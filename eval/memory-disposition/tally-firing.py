#!/usr/bin/env python3
"""Phase 95 T2 — enforce-memory firing-distribution audit (feeds the T3 keep/redesign/retire checkpoint).

Measures whether enforce-memory creates VALUE (a real memory_search follows the bite IN THE SAME SESSION)
or RITUAL (the agent just touches the .claude/.memory-consulted marker — the hook checks marker EXISTENCE,
never an actual search). Two deterministic sources, never conflated:

  1. .dev-wiki/enforcement.log (the hook's OWN JSONL firing log, schema_version:1): the allow/block
     distribution by reason. block=no-memory-search is the BITE.
  2. ~/.claude/projects/<proj>/*.jsonl (session transcripts): REAL memory_search calls, counted ONLY as
     type==assistant -> message.content[] -> tool_use with name~memory_search. NEVER grep — a deferred-tool
     catalog in attachment/system entries over-counts a naive grep ~5x (Phase-94, re-confirmed Phase-95).

CORRECTNESS (hardened after the Phase-95 adversarial review found window-gaming + a cross-transcript leak):
  - SAME-SESSION attribution: a bite is correlated ONLY against searches in a transcript whose time-span
    contains the bite timestamp (the session active when the hook fired). A search in an unrelated,
    non-overlapping session can NOT redeem a bite (the old global-timeline design's leak).
  - WINDOW BAND, not a point: follow-through is reported across a sweep of post-bite windows (the headline is
    a 35-71% band, not the cherry-picked 20min figure). No single window is privileged.
  - EPISODE view: bursts of bites within EPISODE_GAP collapse to one episode (6 phase-82 bites in 75s are one
    blocked-episode, not six independent value events) — the honest denominator for "did the agent respond".

Usage:
  tally-firing.py                 # the firing-distribution audit (band + per-episode), all sources
  tally-firing.py --selftest      # controls incl. a window-CLIFF control + a CROSS-TRANSCRIPT control
  tally-firing.py --verify-ingest # positive control: >=1 real memory_search parsed AND correlate() exercised
"""
from __future__ import annotations
import glob
import json
import os
import sys
from datetime import datetime, timedelta, timezone

PROJ = os.path.expanduser("~/.claude/projects/-Users-jwang-nana-dev-kit")
ENFORCE_LOG = os.path.join(os.path.dirname(__file__), "..", "..", ".dev-wiki", "enforcement.log")
PRE = timedelta(minutes=2)                       # a search just before a bite (marker cleared mid-session)
WINDOWS = [5, 10, 15, 20, 30]                     # post-bite follow-through sweep (minutes) — report the BAND
EPISODE_GAP = timedelta(minutes=30)               # bites within this gap collapse to one episode
MEM = "memory_search"


def _parse_ts(s, *, strict=False):
    if not s:
        return None
    has_tz = s.endswith("Z") or ("+" in s[10:]) or (s[10:].count("-") > 0)
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None
    if dt.tzinfo is None:
        if strict:
            raise ValueError(f"naive (offset-less) timestamp not allowed: {s!r}")
        dt = dt.replace(tzinfo=timezone.utc)      # documented: naive treated as UTC (both live sources are Z)
    return dt.astimezone(timezone.utc)


# --------------------------------------------------------------------------- enforcement.log
def load_blocks(path=ENFORCE_LOG):
    out = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except Exception:
                continue
            if r.get("hook") == "enforce-memory" and r.get("action") == "block":
                ts = _parse_ts(r.get("ts"))
                if ts:
                    out.append((ts, r.get("phase", "?")))
    return sorted(out)


def enforce_distribution(path=ENFORCE_LOG):
    dist = {}
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except Exception:
                continue
            if r.get("hook") == "enforce-memory":
                k = (r.get("action"), r.get("reason"))
                dist[k] = dist.get(k, 0) + 1
    return dist


# --------------------------------------------------------------------------- transcripts (JSON, never grep)
def iter_real_memory_calls(jsonl_files, name_substr=MEM):
    """Yield (ts, file, name) for REAL assistant tool_use memory calls. The deferred-tool catalog lives in
    attachment/system/user entries and is structurally excluded by the type==assistant + tool_use gate."""
    for f in jsonl_files:
        try:
            fh = open(f)
        except Exception:
            continue
        with fh:
            for line in fh:
                line = line.strip()
                if not line or '"tool_use"' not in line:
                    continue
                try:
                    ev = json.loads(line)
                except Exception:
                    continue
                if ev.get("type") != "assistant":
                    continue
                content = (ev.get("message") or {}).get("content")
                if not isinstance(content, list):
                    continue
                ts = _parse_ts(ev.get("timestamp") or ev.get("ts"))
                for b in content:
                    if isinstance(b, dict) and b.get("type") == "tool_use" and name_substr in (b.get("name") or ""):
                        yield (ts, f, b.get("name"))


def index_transcripts(jsonl_files):
    """Per transcript: (span_min, span_max, [search_ts...]). span from ALL event timestamps; searches from
    real assistant tool_use only. The span is the 'session active' interval used for same-session attribution."""
    idx = {}
    searches_by_file = {}
    for (ts, f, _n) in iter_real_memory_calls(jsonl_files):
        if ts:
            searches_by_file.setdefault(f, []).append(ts)
    for f in jsonl_files:
        lo = hi = None
        try:
            fh = open(f)
        except Exception:
            continue
        with fh:
            for line in fh:
                if '"timestamp"' not in line:
                    continue
                try:
                    ev = json.loads(line)
                except Exception:
                    continue
                ts = _parse_ts(ev.get("timestamp") or ev.get("ts"))
                if ts is None:
                    continue
                lo = ts if lo is None or ts < lo else lo
                hi = ts if hi is None or ts > hi else hi
        if lo is not None:
            idx[f] = (lo, hi, sorted(searches_by_file.get(f, [])))
    return idx


def followed_through(bite_ts, idx, post_minutes):
    """True iff a real memory_search exists in a SAME-SESSION transcript (one whose span contains bite_ts)
    within [bite_ts - PRE, bite_ts + post]. Cross-session searches can NOT redeem the bite."""
    post = timedelta(minutes=post_minutes)
    lo, hi = bite_ts - PRE, bite_ts + post
    for (smin, smax, searches) in idx.values():
        if smin <= bite_ts <= smax:                       # this transcript was active at the bite
            if any(lo <= st <= hi for st in searches):
                return True
    return False


def window_band(blocks, idx, windows=WINDOWS):
    return {w: sum(1 for (bts, _p) in blocks if followed_through(bts, idx, w)) for w in windows}


def episodes(blocks, gap=EPISODE_GAP):
    """Collapse bursts of bites into episodes (consecutive bites within `gap`)."""
    eps = []
    for (bts, phase) in blocks:
        if eps and (bts - eps[-1][-1][0]) <= gap:
            eps[-1].append((bts, phase))
        else:
            eps.append([(bts, phase)])
    return eps


# --------------------------------------------------------------------------- controls
def _write(path, events):
    with open(path, "w") as fh:
        for e in events:
            fh.write(json.dumps(e) + "\n")


def selftest():
    rc = 0
    d = os.path.join(os.path.dirname(__file__), "fixtures")
    os.makedirs(d, exist_ok=True)
    A = os.path.join(d, "_st_sessionA.jsonl")
    B = os.path.join(d, "_st_sessionB.jsonl")

    def asst(ts, name=None, text=False):
        c = [{"type": "tool_use", "name": name}] if name else [{"type": "text", "text": "x"}]
        return {"type": "assistant", "timestamp": ts, "message": {"content": c}}

    # session A: spans 12:00-12:40; ONE real search at 12:20. A far bite at 12:01 redeems ONLY at wide window.
    _write(A, [
        asst("2026-06-01T12:00:00Z"),
        {"type": "attachment", "timestamp": "2026-06-01T12:00:30Z",
         "content": "tools: mcp__memory__memory_search, mcp__memory__memory_store"},   # catalog: must NOT count
        asst("2026-06-01T12:20:00Z", "mcp__memory__memory_search"),
        asst("2026-06-01T12:40:00Z"),
    ])
    # session B: spans 13:00-13:10; a real search at 13:05 (used by the cross-transcript control)
    _write(B, [asst("2026-06-01T13:00:00Z"), asst("2026-06-01T13:05:00Z", "mcp__memory__memory_search"),
               asst("2026-06-01T13:10:00Z")])

    idx = index_transcripts([A, B])

    # control: real-call counting (catalog excluded)
    n = sum(1 for _ in iter_real_memory_calls([A, B]))
    if n != 2:
        print(f"SELFTEST FAIL: expected 2 real calls, got {n}"); rc = 1
    else:
        print("selftest ok: 2 real assistant tool_use counted; catalog excluded")

    # WINDOW-CLIFF control: a bite at 12:01, search at 12:20 (~19min away) -> ritual at 10m, value at 30m
    bite = _parse_ts("2026-06-01T12:01:00Z")
    if followed_through(bite, idx, 10):
        print("SELFTEST FAIL: window-cliff control — far search counted at 10min window"); rc = 1
    elif not followed_through(bite, idx, 30):
        print("SELFTEST FAIL: window-cliff control — search not counted at 30min window"); rc = 1
    else:
        print("selftest ok: window-cliff control (ritual@10m, value@30m — band is real, not a point)")

    # CROSS-TRANSCRIPT control: a bite at 13:04 belongs to session B; session A's 12:20 search must NOT count.
    # Make a bite at 12:01 (session A) and confirm session B's search never redeems it even at a huge window.
    bite_a = _parse_ts("2026-06-01T12:01:00Z")
    # temporarily restrict to a window that would catch B's 13:05 (64min) — must still be ritual (cross-session)
    if followed_through(bite_a, idx, 70) and not any(
            smin <= bite_a <= smax and any(_parse_ts("2026-06-01T12:20:00Z") == st for st in searches)
            for (smin, smax, searches) in idx.values()):
        print("SELFTEST FAIL: cross-transcript leak — a different session's search redeemed the bite"); rc = 1
    else:
        # positive sense: B's search must not be reachable for an A-session bite
        only_b = {f: v for f, v in idx.items() if f.endswith("sessionB.jsonl")}
        if followed_through(bite_a, only_b, 1000):
            print("SELFTEST FAIL: cross-transcript control — session B redeemed a session-A bite"); rc = 1
        else:
            print("selftest ok: cross-transcript control (a different session's search cannot redeem a bite)")

    os.remove(A); os.remove(B)
    print("SELFTEST: PASS" if rc == 0 else "SELFTEST: FAIL")
    return rc


def verify_ingest():
    files = sorted(glob.glob(os.path.join(PROJ, "*.jsonl")))
    idx = index_transcripts(files)
    n = sum(len(s) for (_lo, _hi, s) in idx.values())
    blocks = load_blocks()
    # exercise correlate so the positive control is not clean-on-seed (the old --verify-ingest never did)
    band = window_band(blocks, idx)
    print(f"corpus: {len(files)} transcripts; real memory_search calls: {n}; bites: {len(blocks)}; "
          f"value@20m: {band.get(20)}")
    if n >= 1 and len(blocks) >= 1:
        print("POSITIVE-CONTROL: PASS")
        return 0
    print("POSITIVE-CONTROL: FAIL")
    return 1


def report():
    files = sorted(glob.glob(os.path.join(PROJ, "*.jsonl")))
    dist = enforce_distribution()
    blocks = load_blocks()
    idx = index_transcripts(files)
    total_searches = sum(len(s) for (_lo, _hi, s) in idx.values())

    print("# enforce-memory firing distribution (kit, ~/.claude/enforce-memory ARMED)\n")
    print(f"corpus: {len(files)} transcripts; real memory_search tool_use calls: {total_searches}\n")
    print("enforcement.log enforce-memory records:")
    for (action, reason), c in sorted(dist.items(), key=lambda x: -x[1]):
        gating = "" if reason in ("memory-consulted", "no-memory-search") else "   (non-gating allow)"
        print(f"  {c:4d}  {action:5s}  {reason}{gating}")
    blocks_n = dist.get(("block", "no-memory-search"), 0)
    consulted = dist.get(("allow", "memory-consulted"), 0)
    print(f"\n  total enforce-memory fires: {sum(dist.values())}")
    print(f"  GATING: {blocks_n} bites (block) + {consulted} marker-present allows\n")

    band = window_band(blocks, idx)
    print("per-BITE follow-through (real SAME-SESSION memory_search within window) — REPORT THE BAND:")
    for w in WINDOWS:
        v = band[w]
        print(f"  +{w:2d}min: VALUE {v:2d}/{len(blocks)} ({100*v//len(blocks)}%)   ritual {len(blocks)-v}")
    print(f"  -> honest read: follow-through is {100*band[min(WINDOWS)]//len(blocks)}-"
          f"{100*band[max(WINDOWS)]//len(blocks)}% per bite, window-dependent (NOT a single point)\n")

    eps = episodes(blocks)
    ev = sum(1 for ep in eps if followed_through(ep[0][0], idx, 30) or any(followed_through(b[0], idx, 30) for b in ep))
    print(f"per-EPISODE view (bursts within {int(EPISODE_GAP.total_seconds()//60)}min collapsed): "
          f"{len(eps)} episodes; {ev} with a same-session search (@30m)")
    for ep in eps:
        bts0 = ep[0][0]
        hit = any(followed_through(b[0], idx, 30) for b in ep)
        print(f"    {bts0.isoformat()}  phase={ep[0][1]}  bites={len(ep)}  {'VALUE' if hit else 'ritual'}")
    return 0


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--selftest":
        sys.exit(selftest())
    elif arg == "--verify-ingest":
        sys.exit(verify_ingest())
    else:
        sys.exit(report())
