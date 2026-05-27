---
title: "Phase 48: Trace Collection & Pattern Analysis"
aliases: []
category: phases
tags: [eval, heuristics, ablation, trace, reasoning]
parents: []
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: ["eval/reasoning/**", "tests/test_templates.sh"]
entry_criteria: "Phase 47 completed (6/6 tasks done)"
exit_criteria: "Attribution matrix covers 5 IRON RULES × 3 training scenarios × 3 dimensions; selection criteria validated on genuinely held-out scenarios (012/014)"
---

# Phase 48: Trace Collection & Pattern Analysis

## Objective

Instrument reasoning eval to collect per-heuristic influence data via targeted leave-one-out ablation, then analyze to derive selection criteria for conditional heuristic injection.

## Scope

Files and modules affected:
- `eval/reasoning/traces/` — new directory for ablation results and analysis
- `eval/reasoning/trace-schema.json` — JSON schema for trace data
- `eval/reasoning/run-eval.py` — extended with --ablation and --analyze modes
- `eval/reasoning/README.md` — methodology documentation
- `tests/test_templates.sh` — new assertions

## Exit Criteria

- [x] Attribution matrix covers all 5 IRON RULES × 3 training scenarios (015/018/020) × 3 dimensions
- [x] Selection criteria validated on held-out scenarios (012, 014)
- [x] run-eval.py --ablation and --analyze modes functional
- [x] make test passes
- [x] make eval 100% (regression check)

## Constraints

- All new code in eval/reasoning/ — no production skill modifications
- Ablation uses identical prompt structure to existing eval conditions
- Per-dimension attribution (3D matrix, not 2D)
- Classification threshold: delta ≥ 0.5, variance < 0.5
- Genuine held-out: LOO on training only (015/018/020), validate on 012/014 (baseline+full-set comparison only)

## Assumptions

- Leave-one-out ablation provides sufficient signal for IRON RULE attribution. If false: document limitation, test top suspect pairs.
- 5 differentiating scenarios sufficient for criteria derivation. If false: extend to all 20 with reduced runs.

## Results

Key negative result: scenario 015 interference is stochastic (~1/3 of runs), not attributable to any specific IRON RULE. IRON-001 confirmed load-bearing for scenario 020. Ceiling effect (4/5 at 5/5/5) severely limits differentiation. Reframes Phase 49 from per-rule selection to scenario-type classification.

## Notes

Phase 5 of 7 in cognitive enhancement roadmap. User chose trace-then-select strategy (data first, conditional injection in Phase 49). Eval budget: ~75 subagent invocations (revised down from 105 after approach review tightened held-out methodology).
