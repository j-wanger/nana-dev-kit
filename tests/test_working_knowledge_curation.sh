#!/usr/bin/env bash
# Tests for the working-knowledge hot-cache curator (wk-prune.sh -> prune_working_knowledge).
# The curator deterministically enforces: cap (<=100 entries / <=210 lines), exact-proposition
# dedup, [pinned]-immunity, well-formedness (bail on broken 2-line pairing), atomic write, and the
# pre-existing >30d [uses:1] stale prune. Cap/line bounds are overridable via WK_MAX_ENTRIES /
# WK_MAX_LINES so eviction can be exercised with tiny fixtures (production defaults: 100 / 210).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WK_PRUNE="$REPO_ROOT/templates/.claude/hooks/session-start.d/wk-prune.sh"
# fires: wk-prune.sh   # (coverage gate — see test_hook_firing_coverage.sh)

# shellcheck source=/dev/null
source "$WK_PRUNE"   # defines prune_working_knowledge

# Run the curator in a subshell with errexit disabled so the function's internal
# non-zero returns can't kill this (set -e) test harness. Caps are passed via env.
run_curator() {
  local wk="$1" sq="$2" maxE="${3:-100}" maxL="${4:-210}"
  ( set +e; WK_MAX_ENTRIES="$maxE" WK_MAX_LINES="$maxL" prune_working_knowledge "$wk" "$sq" ) 2>&1 || true
}

days_ago() { python3 -c "from datetime import date,timedelta; print(date.today()-timedelta(days=$1))"; }

echo "=== Working-Knowledge Curation Tests ==="

# ---------------------------------------------------------------------------
# 1. exactly-at-cap -> no-op (non-strict boundary, byte-identical)
# ---------------------------------------------------------------------------
test_start "cap: exactly at cap is a byte-identical no-op"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] entry alpha unique"
  echo "  source: [[s-a]] | activated: $TODAY"
  echo "- [uses: 1] entry bravo unique"
  echo "  source: [[s-b]] | activated: $TODAY"
  echo "- [uses: 1] entry charlie unique"
  echo "  source: [[s-c]] | activated: $TODAY"
} > "$WK"
cp "$WK" "$T/before"
run_curator "$WK" "$SQ" 3 210 >/dev/null
if diff -q "$T/before" "$WK" >/dev/null; then test_pass; else test_fail "file changed at exactly-cap (should be no-op)"; fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 2. over-cap -> cull lowest-uses first
# ---------------------------------------------------------------------------
test_start "cap: over-cap evicts lowest-uses entries first"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 5] high-use keep one"
  echo "  source: [[h1]] | activated: $TODAY"
  echo "- [uses: 5] high-use keep two"
  echo "  source: [[h2]] | activated: $TODAY"
  echo "- [uses: 5] high-use keep three"
  echo "  source: [[h3]] | activated: $TODAY"
  echo "- [uses: 1] low-use evict one"
  echo "  source: [[l1]] | activated: $TODAY"
  echo "- [uses: 1] low-use evict two"
  echo "  source: [[l2]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 3 210 >/dev/null
N=$(grep -c '^- \[uses:' "$WK" || true)
if [ "$N" -eq 3 ] && grep -q 'high-use keep one' "$WK" && grep -q 'high-use keep three' "$WK" \
   && ! grep -q 'low-use evict one' "$WK" && ! grep -q 'low-use evict two' "$WK" \
   && grep -q 'low-use evict one' "$SQ"; then
  test_pass
else
  test_fail "expected 3 high-use kept, both low-use evicted to stale-queue (got $N entries)"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 3. over-cap tie on uses -> oldest activated date evicted first
# ---------------------------------------------------------------------------
test_start "cap: ties on uses break by oldest activated date"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
D_OLD1=$(days_ago 20); D_OLD2=$(days_ago 15); D_NEW1=$(days_ago 5); D_NEW2=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] oldest entry twenty"
  echo "  source: [[o1]] | activated: $D_OLD1"
  echo "- [uses: 1] old entry fifteen"
  echo "  source: [[o2]] | activated: $D_OLD2"
  echo "- [uses: 1] newer entry five"
  echo "  source: [[n1]] | activated: $D_NEW1"
  echo "- [uses: 1] newest entry zero"
  echo "  source: [[n2]] | activated: $D_NEW2"
} > "$WK"
run_curator "$WK" "$SQ" 2 210 >/dev/null
if grep -q 'newer entry five' "$WK" && grep -q 'newest entry zero' "$WK" \
   && ! grep -q 'oldest entry twenty' "$WK" && ! grep -q 'old entry fifteen' "$WK"; then
  test_pass
else
  test_fail "expected two oldest-dated entries evicted, two newest kept"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 4. [pinned] never evicted, even when pins alone exceed the cap (pins win + warning)
# ---------------------------------------------------------------------------
test_start "pinned: all-pinned over cap -> pins win, cap exceeded, warning emitted"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] [pinned] pinned invariant one"
  echo "  source: [[p1]] | activated: $TODAY"
  echo "- [uses: 1] [pinned] pinned invariant two"
  echo "  source: [[p2]] | activated: $TODAY"
  echo "- [uses: 1] [pinned] pinned invariant three"
  echo "  source: [[p3]] | activated: $TODAY"
} > "$WK"
OUT=$(run_curator "$WK" "$SQ" 1 210)
N=$(grep -c '^- \[uses:' "$WK" || true)
if [ "$N" -eq 3 ] && grep -q 'pinned invariant one' "$WK" && grep -q 'pinned invariant three' "$WK" \
   && echo "$OUT" | grep -qi 'pinned\|cap exceeded'; then
  test_pass
else
  test_fail "all-pinned over cap: all 3 must survive (got $N) and a warning must be emitted"
fi
rm -rf "$T"

test_start "pinned: mixed -> non-pinned evicted, pinned kept"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] [pinned] pinned survivor one"
  echo "  source: [[p1]] | activated: $TODAY"
  echo "- [uses: 1] [pinned] pinned survivor two"
  echo "  source: [[p2]] | activated: $TODAY"
  echo "- [uses: 1] plain evictable one"
  echo "  source: [[e1]] | activated: $TODAY"
  echo "- [uses: 1] plain evictable two"
  echo "  source: [[e2]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 2 210 >/dev/null
N=$(grep -c '^- \[uses:' "$WK" || true)
if [ "$N" -eq 2 ] && grep -q 'pinned survivor one' "$WK" && grep -q 'pinned survivor two' "$WK" \
   && ! grep -q 'plain evictable one' "$WK"; then
  test_pass
else
  test_fail "expected 2 pinned kept, both plain entries evicted (got $N)"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 5. exact-duplicate proposition -> removed, surviving entry keeps the MAX uses
# ---------------------------------------------------------------------------
test_start "dedup: exact-duplicate proposition collapses, keeping max uses"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 2] duplicated proposition text identical"
  echo "  source: [[d-lo]] | activated: $TODAY"
  echo "- [uses: 7] duplicated proposition text identical"
  echo "  source: [[d-hi]] | activated: $TODAY"
  echo "- [uses: 1] a distinct proposition kept"
  echo "  source: [[uniq]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 100 210 >/dev/null
N=$(grep -c '^- \[uses:' "$WK" || true)
DUPCOUNT=$(grep -c 'duplicated proposition text identical' "$WK" || true)
if [ "$N" -eq 2 ] && [ "$DUPCOUNT" -eq 1 ] && grep -q '^- \[uses: 7\] duplicated proposition text identical' "$WK" \
   && grep -q 'a distinct proposition kept' "$WK"; then
  test_pass
else
  test_fail "expected exact-dup collapsed to one entry at uses:7 (got $N entries, $DUPCOUNT dup copies)"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 5b. dedup must NEVER drop a [pinned] entry, even when an unpinned exact-text twin precedes it
# ---------------------------------------------------------------------------
test_start "dedup: a [pinned] entry survives over an earlier unpinned exact-text twin"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 9] shared exact proposition"
  echo "  source: [[unpinned-twin]] | activated: $TODAY"
  echo "- [uses: 1] [pinned] shared exact proposition"
  echo "  source: [[pinned-twin]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 100 210 >/dev/null
N=$(grep -c '^- \[uses:' "$WK" || true)
if [ "$N" -eq 1 ] && grep -q '\[pinned\] shared exact proposition' "$WK" && grep -q 'pinned-twin' "$WK" \
   && ! grep -q 'unpinned-twin' "$WK"; then
  test_pass
else
  test_fail "the [pinned] entry must survive dedup (got $N entries); a pin must never be dropped for an unpinned twin"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 5c. two pinned copies of identical text are both kept (a pin is never dropped to dedup)
# ---------------------------------------------------------------------------
test_start "dedup: two pinned copies of identical text are both kept"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] [pinned] twin pinned proposition"
  echo "  source: [[pin-a]] | activated: $TODAY"
  echo "- [uses: 1] [pinned] twin pinned proposition"
  echo "  source: [[pin-b]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 100 210 >/dev/null
N=$(grep -c '^- \[uses:' "$WK" || true)
if [ "$N" -eq 2 ] && grep -q 'pin-a' "$WK" && grep -q 'pin-b' "$WK"; then
  test_pass
else
  test_fail "two pinned identical-text entries must both survive (got $N)"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 6. REGRESSION (the wrong-key bug): distinct facts sharing one source slug -> NOT collapsed
# ---------------------------------------------------------------------------
test_start "dedup: distinct facts sharing a source slug are NOT collapsed (wrong-key guard)"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  for k in one two three four five six; do
    echo "- [uses: 1] distinct phase-45 fact number $k"
    echo "  source: [[active-knowledge:phase-45]] | activated: $TODAY"
  done
} > "$WK"
run_curator "$WK" "$SQ" 100 210 >/dev/null
N=$(grep -c '^- \[uses:' "$WK" || true)
if [ "$N" -eq 6 ]; then test_pass; else test_fail "distinct same-slug facts collapsed: expected 6, got $N (slug must NOT be the dedup key)"; fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 7. malformed (broken 2-line pairing) -> whole-file no-op + warning, file byte-intact
# ---------------------------------------------------------------------------
test_start "wellformed: broken 2-line pairing -> whole-file no-op + warning"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] entry with a source line"
  echo "  source: [[ok]] | activated: $TODAY"
  echo "- [uses: 1] entry MISSING its source line"
  echo "- [uses: 1] another entry"
  echo "  source: [[ok2]] | activated: $TODAY"
} > "$WK"
cp "$WK" "$T/before"
OUT=$(run_curator "$WK" "$SQ" 100 210)
if diff -q "$T/before" "$WK" >/dev/null && echo "$OUT" | grep -qi 'malformed\|well-formed\|skip'; then
  test_pass
else
  test_fail "malformed file must be left byte-intact with a warning (no partial edits)"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 8. idempotency: a second run immediately after the first changes nothing
# ---------------------------------------------------------------------------
test_start "idempotent: second run produces no further change"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 5] keep aaa"
  echo "  source: [[a]] | activated: $TODAY"
  echo "- [uses: 5] keep bbb"
  echo "  source: [[b]] | activated: $TODAY"
  echo "- [uses: 1] drop ccc"
  echo "  source: [[c]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 2 210 >/dev/null
cp "$WK" "$T/after1"
run_curator "$WK" "$SQ" 2 210 >/dev/null
if diff -q "$T/after1" "$WK" >/dev/null; then test_pass; else test_fail "second run mutated a converged file (not idempotent)"; fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 9. REGRESSION: pre-existing >30d [uses:1] stale prune still works
# ---------------------------------------------------------------------------
test_start "stale: >30d uses:1 non-pinned entry still moves to stale-queue"
T=$(mktemp -d); WK="$T/wk.md"; SQ="$T/.stale-queue"
OLD=$(days_ago 60); TODAY=$(days_ago 0)
{
  echo "# Working Knowledge"
  echo "- [uses: 1] ancient stale entry"
  echo "  source: [[old]] | activated: $OLD"
  echo "- [uses: 3] fresh frequently-used entry"
  echo "  source: [[fresh]] | activated: $TODAY"
} > "$WK"
run_curator "$WK" "$SQ" 100 210 >/dev/null
if ! grep -q 'ancient stale entry' "$WK" && grep -q 'fresh frequently-used' "$WK" \
   && grep -q 'ancient stale entry' "$SQ"; then
  test_pass
else
  test_fail ">30d uses:1 entry should be pruned to stale-queue; fresh/used entry kept"
fi
rm -rf "$T"

# ---------------------------------------------------------------------------
# 10. absent / empty file -> clean no-op (new projects ship no cache)
# ---------------------------------------------------------------------------
test_start "edge: absent file -> clean no-op (no crash, no file created)"
T=$(mktemp -d); SQ="$T/.stale-queue"
run_curator "$T/does-not-exist.md" "$SQ" 100 210 >/dev/null
if [ ! -f "$T/does-not-exist.md" ]; then test_pass; else test_fail "curator created a file for an absent path"; fi
rm -rf "$T"

test_summary "working-knowledge-curation"
