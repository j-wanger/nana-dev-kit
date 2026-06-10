#!/usr/bin/env python3
"""Phase 86 — emit cost-table.md from extract-costs.py TSV on stdin.

Env: N_PHASES (corpus phase count), NSESS (session count).
Materiality (pre-registration: Cost materiality): immaterial iff cache_adj < 5% of
total AND wall < 5% of total AND interrupts/phase within gate allowance
(dev-plan-orchestration + debrief-capture: 1/phase — the 2 boundary gates; others 0).
"""
import os
import sys

n_phases = int(os.environ["N_PHASES"])
nsess = os.environ["NSESS"]
rows = {}
for line in sys.stdin.read().strip().splitlines()[1:]:
    c = line.split("\t")
    rows[c[0]] = dict(msgs=int(c[1]), inp=int(c[2]), cw=int(c[3]), cr=int(c[4]),
                      out=int(c[5]), adj=int(c[6]), wall=int(c[7]), intr=int(c[8]),
                      disp=int(c[9]), sub=int(c[10]))
total_adj = sum(r["adj"] for r in rows.values()) or 1
total_wall = sum(r["wall"] for r in rows.values()) or 1
STEPS = ["dev-plan-orchestration", "spec-generation", "approach-reviewer",
         "plan-reviewer", "review-gate-reviewer", "debrief-capture"]
ALLOWANCE = {"dev-plan-orchestration": 1.0, "debrief-capture": 1.0}

print("# Ceremony Cost Table — Phases 76–85 (frozen corpus)")
print()
print(f"Sessions: {nsess}; phases = {n_phases}; extractor: extract-costs.py "
      "(control 11/11). Raw = in+cw+cr+out summed; cache-adjusted = "
      "in*1.0 + cw*1.25 + cr*0.1 + out*5.0 (input-token-equivalents).")
print()
print("| step | msgs | in | cache_write | cache_read | out | raw | cache_adj | wall_s | interrupts | dispatches | subagent_out | %adj | %wall |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
verdicts = []
for s in STEPS + ["implementation-other"]:
    r = rows.get(s, dict(msgs=0, inp=0, cw=0, cr=0, out=0, adj=0, wall=0,
                         intr=0, disp=0, sub=0))
    raw = r["inp"] + r["cw"] + r["cr"] + r["out"]
    padj = 100.0 * r["adj"] / total_adj
    pwall = 100.0 * r["wall"] / total_wall
    print(f"| {s} | {r['msgs']} | {r['inp']} | {r['cw']} | {r['cr']} | {r['out']} "
          f"| {raw} | {r['adj']} | {r['wall']} | {r['intr']} | {r['disp']} | {r['sub']} "
          f"| {padj:.1f} | {pwall:.1f} |")
    if s in STEPS:
        intr_per_phase = r["intr"] / n_phases
        immaterial = (padj < 5.0 and pwall < 5.0
                      and intr_per_phase <= ALLOWANCE.get(s, 0.0))
        verdicts.append((s, "immaterial" if immaterial else "material"))
print()
print("Interrupt allowance: dev-plan-orchestration + debrief-capture 1/phase "
      "(the 2 budgeted boundary gates); others 0 (pre-registration: Cost materiality).")
print()
print("MATERIALITY-VERDICT: " + " ".join(f"{s}={v}" for s, v in verdicts))
print("EARLY-EXIT: " + ("yes" if all(v == "immaterial" for _, v in verdicts) else "no"))
