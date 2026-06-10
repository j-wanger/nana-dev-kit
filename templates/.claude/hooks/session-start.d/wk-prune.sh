#!/usr/bin/env bash
# Deterministic curator for the always-loaded hot cache (.claude/rules/working-knowledge.md).
# Single enforcement point, run at session-start. Invariants enforced:
#   - cap: <=WK_MAX_ENTRIES entries AND <=WK_MAX_LINES lines (defaults 100 / 210; NON-strict
#     at the boundary). Eviction key: usage-count asc, ties -> oldest activated date asc.
#   - [pinned] entries are never evicted (pins win even if they alone exceed the cap -> warn).
#   - exact-proposition dedup (keyed on proposition TEXT, never the source slug); survivor keeps
#     the max uses. Distinct facts that merely share a source slug are NOT collapsed.
#   - pre-existing >30d [uses:1] non-pinned stale prune (max 5/run) -> .stale-queue.
#   - well-formedness: any broken 2-line pairing => whole-file no-op + warning, file byte-intact.
#   - size advisory (Phase 79): NON-DESTRUCTIVE warn when an entry exceeds WK_MAX_ENTRY_CHARS (default
#     1500) — the count/line caps do NOT bound SIZE, so a few mega-entries blow the always-loaded token
#     budget; this only warns (never truncates/evicts/bails), prompting a human to compress to a pointer.
#   - atomic write (temp + validate + os.replace); aborts leaving the original intact on failure.
# Policy single source of truth: ~/.claude/skills/dev-wiki/working-knowledge-spec.md.
# Heavy logic is in python3 (already a dependency of this hook); fail-open if python3 is absent.

prune_working_knowledge() {
  local WK_FILE="$1"
  local STALE_QUEUE="$2"

  [ -f "$WK_FILE" ] || return 0
  command -v python3 >/dev/null 2>&1 || return 0

  WK_MAX_ENTRIES="${WK_MAX_ENTRIES:-100}" WK_MAX_LINES="${WK_MAX_LINES:-210}" \
    WK_MAX_ENTRY_CHARS="${WK_MAX_ENTRY_CHARS:-1500}" \
    python3 - "$WK_FILE" "$STALE_QUEUE" <<'PYEOF' || return 0
import os, re, sys, tempfile
from datetime import date, datetime

wk_file = sys.argv[1]
stale_queue = sys.argv[2]
max_entries = int(os.environ.get("WK_MAX_ENTRIES", "100"))
max_lines = int(os.environ.get("WK_MAX_LINES", "210"))


def warn(msg):
    print("[working-knowledge] " + msg)


def size_audit(raw_text, parsed):
    # NON-DESTRUCTIVE size advisory (Phase 79): the always-loaded file is in EVERY session's context, so a
    # few mega-entries silently blow the token budget (the count/line caps below do NOT bound size). This
    # ONLY warns — it never truncates, evicts, or bails. Per-entry over-cap entries are the human-compress
    # signal; detail belongs in the dev-wiki (not always-loaded). Silent when every entry is terse.
    cap = int(os.environ.get("WK_MAX_ENTRY_CHARS", "1500"))
    over = []
    for e in parsed:
        ec = len("- [uses: %d] %s" % (e["uses"], e["rest"])) + 1 + len(e["src"]) + 1
        if ec > cap:
            over.append((ec, re.sub(r"\s+", " ", e["rest"]).strip()[:48]))
    if over:
        over.sort(reverse=True)
        warn("SIZE: %d chars (~%d tokens); %d entr%s exceed the %d-char per-entry cap — compress to a terse pointer (detail belongs in the dev-wiki):"
             % (len(raw_text), len(raw_text) // 4, len(over), "y" if len(over) == 1 else "ies", cap))
        for ec, label in over:
            warn("  - %d chars: %s…" % (ec, label))


try:
    with open(wk_file, "r") as f:
        raw = f.read()
except OSError:
    sys.exit(0)

if raw == "":
    sys.exit(0)

had_trailing_nl = raw.endswith("\n")
lines = raw.split("\n")
if had_trailing_nl:
    lines = lines[:-1]  # drop the empty element produced by the trailing newline

entry_re = re.compile(r'^- \[uses: (\d+)\] (.*)$')
MALFORMED = "WARNING: malformed entry (broken 2-line pairing) -- skipping curation, file left intact."

# --- Parse header + 2-line entries, with a strict well-formedness gate ----------------------
header = []
entries = []   # each: {uses, rest, src, pinned, date}
seen_entry = False
i, n = 0, len(lines)
while i < n:
    line = lines[i]
    m = entry_re.match(line)
    if m:
        seen_entry = True
        if i + 1 >= n or not lines[i + 1].startswith("  "):
            warn(MALFORMED)
            sys.exit(0)
        src = lines[i + 1]
        dm = re.search(r'activated: (\d{4}-\d{2}-\d{2})', src)
        entries.append({
            "uses": int(m.group(1)),
            "rest": m.group(2),
            "src": src,
            "pinned": "[pinned]" in line,
            "date": dm.group(1) if dm else None,
        })
        i += 2
        continue
    if line.startswith("  "):
        # an indented (source-style) line with no preceding entry -> malformed
        warn(MALFORMED)
        sys.exit(0)
    if seen_entry:
        if line.strip() == "":
            i += 1
            continue  # tolerate blank lines between/after entries
        # a non-blank, non-entry, non-indented line once entries have begun -> malformed
        warn(MALFORMED)
        sys.exit(0)
    header.append(line)
    i += 1

# --- Stage 0: non-destructive size advisory (read-only; never modifies the file) ------------
size_audit(raw, entries)

keep = [True] * len(entries)
removed = []
changed = False
today = date.today()

# --- Stage 1: pre-existing >30d [uses:1] non-pinned stale prune (max 5) ----------------------
pruned = 0
for idx, e in enumerate(entries):
    if pruned >= 5:
        break
    if e["uses"] == 1 and not e["pinned"] and e["date"]:
        try:
            age = (today - datetime.strptime(e["date"], "%Y-%m-%d").date()).days
        except ValueError:
            continue
        if age > 30:
            keep[idx] = False
            removed.append(e)
            changed = True
            pruned += 1

# --- Stage 2: exact-proposition dedup (keyed on TEXT, never the source slug) -----------------
# A [pinned] entry is NEVER removed here. If a duplicate group mixes pinned and unpinned copies,
# the pinned copy is the survivor and the unpinned copies are dropped (merging the max uses);
# two pinned copies of the same text are both kept (a pin is never dropped to dedup).
def norm(e):
    return re.sub(r'^\[pinned\]\s*', '', e["rest"]).strip()

first_seen = {}
for idx in range(len(entries)):
    if not keep[idx]:
        continue
    key = norm(entries[idx])
    if key not in first_seen:
        first_seen[key] = idx
        continue
    j = first_seen[key]
    cur, prev = entries[idx], entries[j]
    if cur["pinned"] and not prev["pinned"]:
        # the pin must survive -> drop the unpinned earlier copy, promote cur to survivor
        cur["uses"] = max(cur["uses"], prev["uses"])
        keep[j] = False
        removed.append(prev)
        first_seen[key] = idx
        changed = True
    elif not cur["pinned"]:
        # cur is unpinned -> safe to drop; survivor keeps the max uses
        prev["uses"] = max(prev["uses"], cur["uses"])
        keep[idx] = False
        removed.append(cur)
        changed = True
    # else: both copies are pinned -> keep both (never drop a pin to dedup)

# --- Stage 3: cap enforce (entry count is the binding cap; non-strict; pins win) --------------
# Eviction triggers on entry count ONLY. The 210-line cap is a derived property: with strict
# 2-line entries plus a small header, <=max_entries always stays within it, and a wrapped entry
# would be caught earlier by the well-formedness gate. Lines-over-cap-while-entries-under routes
# to the no-op path below, never to eviction (spec: cap precedence).
def over_cap():
    return sum(1 for k in keep if k) > max_entries

if over_cap():
    cands = [idx for idx in range(len(entries)) if keep[idx] and not entries[idx]["pinned"]]
    cands.sort(key=lambda idx: (entries[idx]["uses"], entries[idx]["date"] or "9999-99-99", idx))
    ci = 0
    while over_cap() and ci < len(cands):
        keep[cands[ci]] = False
        removed.append(entries[cands[ci]])
        changed = True
        ci += 1
    if over_cap():
        warn("WARNING: cap exceeded (%d entries) -- remaining entries are pinned; not evicting."
             % sum(1 for k in keep if k))

if not changed:
    sys.exit(0)   # idempotent / no-op: leave the file byte-intact

# --- Render surviving entries in original order (no sorting) ---------------------------------
out = list(header)
for idx in range(len(entries)):
    if keep[idx]:
        out.append("- [uses: %d] %s" % (entries[idx]["uses"], entries[idx]["rest"]))
        out.append(entries[idx]["src"])
new_content = "\n".join(out) + ("\n" if had_trailing_nl else "")

# --- Belt-and-suspenders: re-validate pairing before we touch the real file ------------------
v = new_content.split("\n")
if had_trailing_nl:
    v = v[:-1]
vi, ok = 0, True
while vi < len(v):
    if entry_re.match(v[vi]):
        if vi + 1 >= len(v) or not v[vi + 1].startswith("  "):
            ok = False
            break
        vi += 2
    else:
        vi += 1
if not ok:
    warn("WARNING: refusing to write -- internal validation failed; file left intact.")
    sys.exit(0)

# spec invariant: (evicted ∩ pinned) == ∅ -- a pinned entry is never removed
if any(e["pinned"] for e in removed):
    warn("WARNING: refusing to write -- a pinned entry was marked for removal; file left intact.")
    sys.exit(0)

# spec cap precedence: lines over cap while entries within cap -> no-op (well-formedness route)
if sum(1 for k in keep if k) <= max_entries and len(v) > max_lines:
    warn("WARNING: %d lines exceeds the %d-line cap at <=%d entries -- treating as malformed; file left intact."
         % (len(v), max_lines, max_entries))
    sys.exit(0)

# --- Atomic write: temp in the same dir, then os.replace -------------------------------------
d = os.path.dirname(os.path.abspath(wk_file)) or "."
fd, tmp = tempfile.mkstemp(dir=d, prefix=".wk-curate.")
try:
    with os.fdopen(fd, "w") as tf:
        tf.write(new_content)
    os.replace(tmp, wk_file)
except OSError:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    warn("WARNING: atomic write failed; file left intact.")
    sys.exit(0)

# --- Audit trail: removed entries -> stale queue ---------------------------------------------
try:
    stamp = today.isoformat()
    with open(stale_queue, "a") as sq:
        for e in removed:
            sq.write("[pruned %s] - [uses: %d] %s\n" % (stamp, e["uses"], e["rest"]))
            sq.write("[pruned %s] %s\n" % (stamp, e["src"]))
except OSError:
    pass

print("[working-knowledge] Curated: %d entr%s removed (stale/dedup/cap). See %s."
      % (len(removed), "y" if len(removed) == 1 else "ies", stale_queue))
sys.exit(0)
PYEOF
}
