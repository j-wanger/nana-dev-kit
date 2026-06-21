#!/usr/bin/env python3
"""Phase 94 T2 — retrospective consumer memory-DEMAND tally (EVIDENCE ONLY).

Counts REAL memory tool_use calls (never grep — a deferred-tool catalog lives in
type==attachment/system entries and contaminates a naive string match ~5x) across the
three maintainer-fixed consumers, on the post-repair admissible window, and reports the
machinery-gradient contrast that feeds the Phase-95 keep/shrink/cut decision.

Demand axis (clean, deterministic): per-consumer kit-memory-machinery level —
  none (no nana-soul memory rules, no enforce-memory hook) => all calls are SPONTANEOUS,
  rules (nana-soul session-start memory_search instruction, no hook),
  rules+hooks (rules + enforce-memory PreToolUse hook).
Sub-measures: attempted-vs-satisfied (paired tool_result) and cross-session READ-BACK
(a search returning a memory created before the current session — the ritual-vs-value
discriminator). Sidechain (subagent) calls are reported SEPARATELY, never folded in.

Admissibility window pinned to the Ph91 repair commit (verify-by-firing in verify-firing.sh
confirms the layer fires in a consumer cwd; pre-repair sessions ran on the broken layer).

Usage:
  tally-demand.py                 # tally the 3 consumers, print the contrast table
  tally-demand.py --selftest      # contamination + sidechain-separation + readback control
  tally-demand.py --verify-ingest # positive control: >=1 admissible session parsed per consumer
"""
from __future__ import annotations
import glob
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

REPAIR_COMMIT = "318e9b6"                       # Phase 91 PYTHONPATH fix
REPAIR_TS = "2026-06-14T18:45:16Z"              # 318e9b6 author date (2026-06-14 14:45:16 -0400 -> UTC)
HOME = Path.home()
CONSUMERS = ["signal-watch", "aml-casework", "aml-substrate"]
MEM_TOOLS = {"mcp__memory__memory_search": "search", "mcp__memory__memory_store": "store"}


def parse_ts(s):
    if not s or not isinstance(s, str):
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00")).astimezone(timezone.utc).timestamp()
    except Exception:
        return None


REPAIR_EPOCH = parse_ts(REPAIR_TS)


def transcript_dir(name):
    return HOME / ".claude" / "projects" / f"-Users-jwang-{name}"


def machinery(name):
    """Deterministic from the consumer's installed harness surface."""
    root = HOME / name
    soul = root / ".claude" / "rules" / "nana-soul.md"
    has_rules = soul.is_file() and "memory_search" in soul.read_text(errors="ignore")
    has_hook = False
    sl = root / ".claude" / "settings.local.json"
    if sl.is_file():
        has_hook = "enforce-memory" in sl.read_text(errors="ignore")
    if has_hook:
        return "rules+hooks"
    if has_rules:
        return "rules"
    return "none"


def db_rows(name):
    db = HOME / name / ".memory" / "memory.db"
    if not db.is_file():
        return None
    try:
        import sqlite3
        con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
        n = con.execute("select count(*) from memories").fetchone()[0]
        con.close()
        return n
    except Exception:
        return None


def _result_items(tr_content):
    """Extract the list under the search tool_result's top-level 'result' key (robust to
    string / list-of-text-blocks shapes). Returns [] on any parse failure."""
    raw = tr_content
    if isinstance(raw, list):
        raw = "".join(b.get("text", "") for b in raw if isinstance(b, dict))
    if not isinstance(raw, str):
        return []
    try:
        obj = json.loads(raw)
    except Exception:
        return []
    if isinstance(obj, dict) and isinstance(obj.get("result"), list):
        return obj["result"]
    if isinstance(obj, list):
        return obj
    return []


def tally_session(path):
    """Return per-session counts for ONE transcript file (admissible-gated)."""
    rows = []
    for line in open(path, errors="ignore"):
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except Exception:
            continue
    ts_all = [parse_ts(o.get("timestamp")) for o in rows]
    ts_all = [t for t in ts_all if t is not None]
    first_ts = min(ts_all) if ts_all else None

    z = dict(admissible=False, main_search=0, main_store=0, side_search=0, side_store=0,
             satisfied_search=0, empty_search=0, readback=0)
    if first_ts is None or REPAIR_EPOCH is None or first_ts < REPAIR_EPOCH:
        return z
    z["admissible"] = True

    results = {}   # tool_use_id -> result item list
    searches = []  # (tool_use_id, sidechain)
    for o in rows:
        msg = o.get("message") or {}
        content = msg.get("content")
        if not isinstance(content, list):
            continue
        side = bool(o.get("isSidechain"))
        for b in content:
            if not isinstance(b, dict):
                continue
            t = b.get("type")
            if t == "tool_use":
                kind = MEM_TOOLS.get(str(b.get("name", "")))
                if not kind:
                    continue
                key = ("side_" if side else "main_") + kind
                z[key] += 1
                if kind == "search":
                    searches.append((b.get("id"), side))
            elif t == "tool_result":
                uid = b.get("tool_use_id")
                if uid:
                    results[uid] = _result_items(b.get("content"))

    for uid, side in searches:
        if side:
            continue
        items = results.get(uid)
        if items is None:
            continue
        if len(items) == 0:
            z["empty_search"] += 1
            continue
        z["satisfied_search"] += 1
        for it in items:
            mem = it.get("memory", it) if isinstance(it, dict) else {}
            ca = parse_ts(mem.get("created_at")) if isinstance(mem, dict) else None
            if ca is not None and ca < first_ts:
                z["readback"] += 1
                break
    return z


def find_subagent_files(d):
    """Subagent transcripts live at <consumer>/<session-uuid>/subagents/agent-*.jsonl —
    SEPARATE files, not inline isSidechain entries. They are orchestrator-driven, so they
    are counted SEPARATELY (side_*), never folded into organic main-agent demand."""
    d = Path(d)
    seen = set()
    for pat in ("*/subagents/*.jsonl", "**/subagents/*.jsonl"):
        for f in glob.glob(str(d / pat), recursive=True):
            seen.add(os.path.realpath(f))
    return sorted(seen)


def tally_subagent_file(path):
    """Count real memory tool_use in ONE subagent file (admissible-gated by own first ts)."""
    rows = []
    for line in open(path, errors="ignore"):
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except Exception:
            continue
    ts = [parse_ts(o.get("timestamp")) for o in rows]
    ts = [t for t in ts if t is not None]
    first = min(ts) if ts else None
    z = dict(admissible=False, side_search=0, side_store=0)
    if first is None or REPAIR_EPOCH is None or first < REPAIR_EPOCH:
        return z
    z["admissible"] = True
    for o in rows:
        content = (o.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        for b in content:
            if isinstance(b, dict) and b.get("type") == "tool_use":
                kind = MEM_TOOLS.get(str(b.get("name", "")))
                if kind:
                    z["side_" + kind] += 1
    return z


def tally_consumer(name):
    d = transcript_dir(name)
    agg = dict(name=name, machinery=machinery(name), db_rows=db_rows(name),
               sessions_total=0, sessions_admissible=0, sessions_pre_repair=0,
               main_search=0, main_store=0, side_search=0, side_store=0,
               side_files=0, satisfied_search=0, empty_search=0, readback=0)
    files = sorted(glob.glob(str(d / "*.jsonl")))
    agg["sessions_total"] = len(files)
    for f in files:
        z = tally_session(f)
        if not z["admissible"]:
            agg["sessions_pre_repair"] += 1
            continue
        agg["sessions_admissible"] += 1
        for k in ("main_search", "main_store", "side_search", "side_store",
                  "satisfied_search", "empty_search", "readback"):
            agg[k] += z[k]
    for sf in find_subagent_files(d):           # subagent transcripts (separate files)
        zs = tally_subagent_file(sf)
        if not zs["admissible"]:
            continue
        agg["side_files"] += 1
        agg["side_search"] += zs["side_search"]
        agg["side_store"] += zs["side_store"]
    return agg


def print_table(aggs):
    print(f"# Consumer memory-demand tally — admissible window: first-entry >= {REPAIR_TS} "
          f"(repair-commit {REPAIR_COMMIT})")
    print(f"# Parse: real type==assistant tool_use blocks only (attachment/system mentions excluded). "
          f"EVIDENCE ONLY.\n")
    hdr = ("consumer", "machinery", "adm.sess", "main_srch", "main_store",
           "satisfied", "readback", "side(s/st)", "db_rows")
    print("| " + " | ".join(hdr) + " |")
    print("|" + "|".join(["---"] * len(hdr)) + "|")
    for a in aggs:
        print("| " + " | ".join(str(x) for x in (
            a["name"], a["machinery"], a["sessions_admissible"],
            a["main_search"], a["main_store"], a["satisfied_search"], a["readback"],
            f'{a["side_search"]}/{a["side_store"]}', a["db_rows"])) + " |")
    print()
    for a in aggs:
        print(f"  {a['name']}: {a['sessions_total']} total sessions "
              f"({a['sessions_admissible']} admissible / {a['sessions_pre_repair']} pre-repair); "
              f"machinery={a['machinery']}; empty_searches={a['empty_search']}; "
              f"admissible_subagent_files={a['side_files']} (side calls reported separately, not folded into demand)")


def selftest():
    fx = Path(__file__).parent / "fixtures" / "contamination_fixture.jsonl"
    assert fx.is_file(), f"fixture missing: {fx}"
    z = tally_session(str(fx))
    fails = []
    if not z["admissible"]:
        fails.append("fixture session not admissible")
    if z["main_store"] != 1:
        fails.append(f"main_store={z['main_store']} expected 1 (attachment/system/prose mention must NOT count)")
    if z["main_search"] != 1:
        fails.append(f"main_search={z['main_search']} expected 1")
    if z["readback"] < 1:
        fails.append(f"readback={z['readback']} expected >=1 (result memory created before session = cross-session)")
    if z["satisfied_search"] < 1:
        fails.append(f"satisfied_search={z['satisfied_search']} expected >=1")

    # subagent capture control — guard the REAL invariant (subagents are separate files,
    # not inline isSidechain entries). A regression that stops reading subagents/*.jsonl
    # must fail here.
    subdir = Path(__file__).parent / "fixtures" / "sub_consumer"
    found = find_subagent_files(subdir)
    if len(found) < 1:
        fails.append(f"find_subagent_files found {len(found)} files under {subdir} — expected >=1 (subagents/*.jsonl path)")
    else:
        zs = tally_subagent_file(found[0])
        if zs["side_search"] != 1:
            fails.append(f"subagent side_search={zs['side_search']} expected 1 (real subagent tool_use must count)")
        if zs["side_store"] != 1:
            fails.append(f"subagent side_store={zs['side_store']} expected 1 (prose/attachment mention must NOT count)")

    if fails:
        print("SELFTEST FAIL:")
        for f in fails:
            print("  -", f)
        return 1
    print("SELFTEST PASS: contamination excluded (attachment/system/prose not counted), "
          "real main call counted, read-back detected, subagent files (separate path) counted separately.")
    return 0


def verify_ingest():
    """Positive control: the rig must prove it actually opened+parsed >=1 admissible
    session per consumer before any low/zero count is trustworthy (mirror of the firing
    broken-control). A silent-empty parse (wrong glob / missing transcripts) FAILS here."""
    bad = []
    for name in CONSUMERS:
        a = tally_consumer(name)
        if a["sessions_admissible"] < 1:
            bad.append(f"{name}: {a['sessions_admissible']} admissible sessions parsed "
                       f"(of {a['sessions_total']} total) — silent-empty parse?")
        else:
            print(f"  ingest OK: {name} — {a['sessions_admissible']} admissible sessions parsed")
    if bad:
        print("VERIFY-INGEST FAIL:")
        for b in bad:
            print("  -", b)
        return 1
    print("VERIFY-INGEST PASS: >=1 admissible session parsed for every consumer.")
    return 0


def main():
    arg = sys.argv[1] if len(sys.argv) > 1 else ""
    if arg == "--selftest":
        return selftest()
    if arg == "--verify-ingest":
        return verify_ingest()
    print_table([tally_consumer(n) for n in CONSUMERS])
    return 0


if __name__ == "__main__":
    sys.exit(main())
