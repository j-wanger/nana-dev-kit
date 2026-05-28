---
title: "Phase 50: Eval Advancement — Cross-Model Judging, Harder Scenarios & Length-Sensitivity"
aliases: [phase-50-eval-advancement]
category: phases
tags: [eval, reasoning, cross-model-judging, calibration, scenarios, length-sensitivity]
parents: []
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: ["eval/reasoning/**"]
entry_criteria: "Phase 49 completed (6/6 tasks done, negative result). conditional-analysis.md recommends these 3 levers."
exit_criteria: "Filler-text 520-580 words, cross-model results with different judge/agent models, corpus >= 25 scenarios, analysis doc covering all 3 experiments, make test + make eval pass."
---

# Phase 50: Eval Advancement — Cross-Model Judging, Harder Scenarios & Length-Sensitivity

## Objective

Three sequential experiments to advance reasoning eval capability: (1) length-sensitivity test to isolate whether prompt length vs content drives interference, (2) cross-model judging to break self-grading bias, (3) harder scenarios to increase differentiation power beyond 4/20 below ceiling.

## Approach

Experiments ordered by cost and information value (cheapest first per early-falsification-checkpoint decision):

1. **Length-Sensitivity**: Count IRON RULES word count (549 words), create coherent filler text (cooking/gardening, 520-580 words). Run 3-condition eval (no-inject vs IRON RULES vs filler). Checkpoint: if filler delta within 0.3 of IRON RULES delta on >50% of affected scenarios, report length-as-driver.
2. **Cross-Model Judging**: Extend results schema for raw response storage. Re-judge with Agent(model="sonnet"). Calibration gate: mean < 4.5, >=15% below 5. Fallback: Haiku.
3. **Harder Scenarios**: 5 new scenarios (021-025) with genuine multi-stakeholder ambiguity. Judge variance check (3 runs, reject if variance > 0.5). Report original-20 and full-25 metrics.

## Scope

- `eval/reasoning/**`

## Decisions

- [[length-sensitivity-experiment-design]] -- coherent filler text matching IRON RULES word count, pre-committed threshold
- [[cross-model-judge-via-agent-param]] -- Agent model param for Sonnet judge, response storage, calibration gate

## Exit Criteria

- [x] Filler-text.md exists with 520-580 word count
- [x] Cross-model results.json with different judge_model and agent_model
- [x] Corpus contains >= 25 scenario files
- [x] run-eval.py supports --length-test and --cross-judge modes
- [x] cross-model-judge.md prompt template exists
- [x] phase-50-analysis.md covers all 3 experiments
- [x] make test && make eval pass

## Notes

Phase 49 conditional injection produced a negative result (zero delta vs always-inject). Length-sensitivity is the cheapest falsification of the content-vs-length hypothesis. Cross-model judging addresses the long-standing self-grading bias (mean 4.83 vs target < 4.5). Harder scenarios address ceiling effect (16/20 at 5/5/5).
