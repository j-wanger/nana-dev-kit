#!/usr/bin/env python3
"""Phase 86 ceremony cost extractor.

Pre-registered attribution (eval/ceremony-lift/pre-registration.md, FROZEN):
- A message belongs to a step from its step-boundary marker (Skill invocation, or
  Agent dispatch whose label matches a Step-list class) until the next boundary.
- Messages before any boundary, and spans opened by non-ceremony markers, land in
  "implementation-other".
- Subagent costs attribute WHOLLY to the dispatching step (subagent_tokens markers
  in dispatch results, deduped per result line).
- cache_adjusted = in*1.0 + cache_write*1.25 + cache_read*0.1 + out*5.0
- Line-tolerant: malformed/truncated JSONL lines are skipped (mid-append sessions).

Output: TSV — step, msgs, in, cw, cr, out, cache_adj, wall_s, interrupts,
dispatches, subagent_out. One row per step class present, plus implementation-other.
"""
import json
import re
import sys
from datetime import datetime

# Label keywords -> step class (pre-registration ## Step list). Checked in order;
# first match wins. Lowercased substring match on the dispatch description/label.
DISPATCH_CLASS = [
    ("adversarial", "spec-generation"),
    ("tier-1", "spec-generation"),
    ("tier 1", "spec-generation"),
    ("spec semantic", "spec-generation"),
    ("state loader", "dev-plan-orchestration"),
    ("artifact writer", "dev-plan-orchestration"),
    ("approach review", "approach-reviewer"),
    ("plan review", "plan-reviewer"),
    ("plan re-review", "plan-reviewer"),
    ("review gate", "review-gate-reviewer"),
    ("debrief executor", "debrief-capture"),
]
SKILL_CLASS = {
    "spec": "spec-generation",
    "dev-plan": "dev-plan-orchestration",
    "dev-debrief": "debrief-capture",
}
OTHER = "implementation-other"
# Two marker forms: sync dispatch tool_results use "subagent_tokens: N";
# background task-notifications use "<subagent_tokens>N<". Background values also
# appear in queue-operation entries (no .message) — those are skipped, so each
# background dispatch is counted exactly once via its user-string notification.
SUBAGENT_RE = re.compile(r"subagent_tokens[>:]\s*(\d+)")
NOTIF_DESC_RE = re.compile(r'Agent \\?"([^"\\]+)')


def parse_ts(s):
    if not s:
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def classify_dispatch(label):
    low = (label or "").lower()
    for kw, cls in DISPATCH_CLASS:
        if kw in low:
            return cls
    return None


def new_row():
    return {"msgs": 0, "in": 0, "cw": 0, "cr": 0, "out": 0,
            "wall": 0.0, "interrupts": 0,
            "dispatches": 0, "subagent_out": 0}


def main(paths, manifest=False):
    rows = {}
    dispatches = []  # (file, timestamp, label, class) when manifest mode

    def row(cls):
        if cls not in rows:
            rows[cls] = new_row()
        return rows[cls]

    for path in paths:
        current = OTHER
        prev_ts = None
        # tool_use_id -> step class, for attributing dispatch results' subagent tokens
        dispatch_step = {}
        try:
            fh = open(path, "r", encoding="utf-8", errors="replace")
        except OSError as e:
            print(f"extract-costs: cannot open {path}: {e}", file=sys.stderr)
            return 1
        with fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                except json.JSONDecodeError:
                    continue  # truncated/mid-append line
                msg = entry.get("message") or {}
                content = msg.get("content")
                ts = parse_ts(entry.get("timestamp"))

                # Boundary detection + interrupt/dispatch counting from tool_use blocks
                if isinstance(content, list):
                    for block in content:
                        if not isinstance(block, dict):
                            continue
                        if block.get("type") == "tool_use":
                            name = block.get("name", "")
                            inp = block.get("input") or {}
                            if name == "AskUserQuestion":
                                row(current)["interrupts"] += 1
                            elif name == "Skill":
                                cls = SKILL_CLASS.get(inp.get("skill", ""))
                                current = cls if cls else OTHER
                            elif name in ("Agent", "Task"):
                                label = inp.get("description") or ""
                                cls = classify_dispatch(label)
                                if manifest:
                                    dispatches.append(
                                        (path.split("/")[-1],
                                         entry.get("timestamp") or "",
                                         label, cls or "non-ceremony"))
                                if cls:
                                    row(cls)["dispatches"] += 1
                                    current = cls
                                else:
                                    current = OTHER
                                # record ALL dispatches (unclassified -> OTHER) so
                                # their sync subagent costs conserve, not vanish
                                dispatch_step[block.get("id", "")] = cls or OTHER
                        elif block.get("type") == "tool_result":
                            # subagent token recovery, attributed to dispatching step
                            tuid = block.get("tool_use_id", "")
                            if tuid in dispatch_step:
                                text = json.dumps(block.get("content", ""))
                                m = SUBAGENT_RE.search(text)
                                if m:
                                    row(dispatch_step.pop(tuid))["subagent_out"] += int(m.group(1))

                # Background-dispatch notifications: user entries with STRING content
                # carrying the XML marker; attribute via the notification's agent
                # description (same label keywords as dispatch classification).
                if isinstance(content, str) and "subagent_tokens>" in content:
                    m = SUBAGENT_RE.search(content)
                    if m:
                        dm = NOTIF_DESC_RE.search(content)
                        ncls = classify_dispatch(dm.group(1)) if dm else None
                        row(ncls or OTHER)["subagent_out"] += int(m.group(1))

                r = row(current)
                usage = msg.get("usage") or {}
                if usage.get("output_tokens") is not None:
                    r["msgs"] += 1
                    r["in"] += usage.get("input_tokens") or 0
                    r["cw"] += usage.get("cache_creation_input_tokens") or 0
                    r["cr"] += usage.get("cache_read_input_tokens") or 0
                    r["out"] += usage.get("output_tokens") or 0
                # Wall-clock: consecutive-message delta credited to the ACTIVE span —
                # partitions the session timeline exactly (sum of rows == session span).
                # prev_ts advances monotonically: out-of-order timestamps must not
                # re-count already-credited time.
                if ts:
                    if prev_ts is None:
                        prev_ts = ts
                    elif ts > prev_ts:
                        r["wall"] += (ts - prev_ts).total_seconds()
                        prev_ts = ts

    if manifest:
        print("session\ttimestamp\tlabel\tclass")
        for d in dispatches:
            print("\t".join(d))
        return 0

    print("step\tmsgs\tin\tcw\tcr\tout\tcache_adj\twall_s\tinterrupts\tdispatches\tsubagent_out")
    for cls in sorted(rows):
        r = rows[cls]
        cache_adj = int(r["in"] * 1.0 + r["cw"] * 1.25 + r["cr"] * 0.1 + r["out"] * 5.0)
        wall = int(r["wall"])
        print(f"{cls}\t{r['msgs']}\t{r['in']}\t{r['cw']}\t{r['cr']}\t{r['out']}"
              f"\t{cache_adj}\t{wall}\t{r['interrupts']}\t{r['dispatches']}\t{r['subagent_out']}")
    return 0


if __name__ == "__main__":
    args = sys.argv[1:]
    manifest = "--manifest" in args
    args = [a for a in args if a != "--manifest"]
    if not args:
        print("usage: extract-costs.py [--manifest] <session.jsonl> [...]", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(args, manifest=manifest))
