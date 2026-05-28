---
title: "Phase 49: Conditional Heuristic Injection — Scenario-Type Classification"
aliases: [conditional-injection, scenario-type-classification]
category: phases
tags: [eval, heuristic, injection, reasoning, classification]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: debrief
status: completed
scope: ["eval/reasoning/**"]
entry_criteria: "Phase 48 completed (5/5 tasks done), attribution matrix available, selection criteria documented"
exit_criteria: "Scenario-type taxonomy defined, 20 scenarios tagged, conditional injection template written, 3-condition eval run, analysis document produced, make test + make eval pass"
---

# Phase 49: Conditional Heuristic Injection — Scenario-Type Classification

## Objective

Add scenario-type metadata to the 20-scenario reasoning eval corpus and implement conditional IRON RULES injection (inject for non-risk-dominant, suppress for risk-dominant), then validate whether conditional injection outperforms always-inject.

## Scope

Files and modules affected:
- `eval/reasoning/scenario-type-taxonomy.md` (new)
- `eval/reasoning/corpus/*.json` (update 20 files — add scenario_type field)
- `eval/reasoning/conditional-injection.md` (new prompt template)
- `eval/reasoning/run-eval.py` (update — add --conditional analysis mode)
- `eval/reasoning/with-conditional/results.json` (new)
- `eval/reasoning/traces/conditional-analysis.md` (new)

## Exit Criteria

- [ ] All 20 scenario JSONs have valid scenario_type field (risk-dominant|capacity-constraint|domain-nuance)
- [ ] scenario-type-taxonomy.md exists
- [ ] conditional-injection.md exists
- [ ] run-eval.py --help shows --conditional mode
- [ ] with-conditional/results.json exists
- [ ] traces/conditional-analysis.md exists
- [ ] make test && make eval pass

## Constraints

- Type taxonomy must be defined BEFORE assigning types (prevents overfitting to known outcomes)
- 3-run protocol required for all conditions (prevents false positives from stochastic interference)
- Both conditions run on held-out scenarios 012, 014 (prevents unfalsifiable type assignment)
- Design for negative result (prevents sunk cost bias)

## Checkpoints

- After taxonomy definition: verify criteria distinguish 015 from 018/020 on paper
- After type assignment: verify at least 2 scenarios per type
- After first conditional run: note if 012/014 both at ceiling in both conditions (inconclusive held-out)

## Assumptions

- Scenario-type taxonomy captures the relevant dimension. If false: try alternative axis (ambiguity level, number of competing valid answers).
- Stochastic interference on 015 is model variance, not judge variance. If false: 3-run protocol + variance threshold mitigate.
- 20-scenario corpus has sufficient type diversity. If false: note as limitation.

## Notes

- Phase 48 negative result: per-rule selection not viable; all-or-nothing by scenario type is the accepted framing
- Only scenario 015 shows interference signal; 4/5 training scenarios at ceiling
- Conditional injection is metadata-based (lookup), not runtime inference
