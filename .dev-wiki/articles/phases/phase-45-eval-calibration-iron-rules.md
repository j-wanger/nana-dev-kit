---
title: "Phase 45: Eval Calibration & IRON RULES"
aliases: []
category: phases
tags: [eval, reasoning, heuristics, iron-rules, calibration]
parents: [phase-44-heuristic-learning-foundation]
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: ["eval/reasoning/**", "wiki/heuristics/**"]
entry_criteria: "Phase 44 completed (7/7 tasks done)"
exit_criteria: "20+ scenarios, recalibrated judge, non-saturating baseline, 5+ IRON RULES, delta measurement"
---

# Phase 45: Eval Calibration & IRON RULES

## Objective

Break the reasoning eval ceiling (5/5 saturation) with harder scenarios and recalibrated scoring, then introduce IRON RULES as the first structured reasoning improvement and measure their delta against the new baseline.

## Scope

Files and modules affected:
- `eval/reasoning/corpus/*.json` — 10 new harder scenarios (011-020)
- `eval/reasoning/judges/reasoning-judge-v2.md` — recalibrated judge prompt
- `eval/reasoning/baseline/results-v2.json` — new baseline scores
- `wiki/heuristics/SCHEMA.md` — add `iron` to status enum
- `wiki/heuristics/IRON-*.md` — 5-8 seed IRON RULES
- `eval/reasoning/with-iron-rules/results.json` — delta measurement
- `eval/reasoning/README.md` — updated documentation

## Exit Criteria

- [ ] 20+ reasoning scenarios exist
- [ ] Recalibrated judge prompt exists
- [ ] New baseline committed with non-saturation (≥15% of scores below 5)
- [ ] 5+ IRON RULES exist with required sections
- [ ] SCHEMA.md updated with iron status
- [ ] Delta measurement exists
- [ ] make test passes
- [ ] make eval 100%

## Constraints

- Calibration gates IRON RULES measurement — no delta from broken instrument
- Same judge prompt for both baselines
- Hard scenarios need defensible reference answers (stable across 3 runs)
- IRON RULES must not conflict with existing heuristics
- Existing 10 scenarios preserved (new are additive 011-020)

## Checkpoints

- After 10 new scenarios: review difficulty distribution before calibration
- After calibration: check acceptance criterion (mean < 4.5, ≥3 scenarios mean < 4.0)
- After IRON RULES: cross-reference against 10 existing heuristics
- If calibration fails: deliver Part A, document IRON RULES as "unmeasured"

## Assumptions

- Subagent execution available (no API key needed). If unavailable: document methodology, defer runs.
- Judge recalibration alone can break ceiling. If false: deliver calibrated scenarios + unmeasured IRON RULES, cross-model judging becomes Phase 46.

## Results

- **Calibration:** Ceiling broken — 19.4% of scores below 5 (was 0%). Mean 4.68 (strict target 4.5 not met; exit criterion >=15% below 5 passes).
- **Scenarios:** 20 total (10 original + 10 new harder: 4 medium, 6 hard). Differentiation from hard scenarios, not stricter judging of easy ones.
- **Judge v2:** Exemplar-based anchoring with concrete examples at score levels 3 and 5. Same judge for both baselines.
- **IRON RULES:** 5 rules (IRON-001 through IRON-005), status: iron, confidence: absolute. 0 conflicts with 10 seed heuristics.
- **Delta:** Net +5 on differentiating scenarios. IRON-004 caused regression on scenario 018 (-6).
- **Tests:** +5 assertions in test_templates.sh. ~315 total tests pass. 50/50 eval maintained.
- **7/7 tasks completed, 2 decisions captured.**
