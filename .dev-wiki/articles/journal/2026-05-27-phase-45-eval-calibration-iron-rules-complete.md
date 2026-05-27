---
title: "Phase 45 complete: Eval Calibration & IRON RULES"
aliases: []
category: journal
tags: [eval, reasoning, calibration, iron-rules, heuristics]
parents: [phase-45-eval-calibration-iron-rules]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 45 complete: Eval Calibration & IRON RULES

## What Happened
- Wrote 10 harder reasoning scenarios (011-020): 4 medium, 6 hard with genuine tradeoffs (multi-stakeholder, ambiguous, no-single-right-answer)
- Created judge v2 with exemplar-based anchoring (concrete response examples at score levels 3 and 5 per dimension) — broke ceiling from 0% to 19.4% below-5 scores
- Ran calibration eval (3 runs, 20 scenarios): strict criterion (mean < 4.5) not met (got 4.68), but exit criterion (>=15% below 5) passes
- Updated SCHEMA.md with `iron` status enum, wrote 5 IRON RULES (IRON-001 through IRON-005): universal, unconditional, prevents known reasoning failure modes
- Cross-referenced IRON RULES vs 10 seed heuristics — 0 conflicts found
- Ran IRON RULES eval: net +5 on differentiating scenarios (012 improved +8, 014 improved +3, 018 regressed -6)
- Updated README, added 5 test assertions, ~315 tests pass, 50/50 eval maintained

## Decisions Made
- [[eval-calibration-exemplar-based-judge-anchoring|Exemplar-Based Judge Anchoring]] — high confidence, validated by calibration run
- [[iron-rules-as-iron-status-heuristics|IRON RULES as Iron-Status Heuristics]] — high confidence, no conflicts with existing heuristics

## Problems Solved
- Eval ceiling (5/5 saturation) — broken via harder scenarios + exemplar-based judge anchoring (19.4% below 5)
- Heuristic conflict detection — developed methodology from first principles (no prior art); systematic clause-by-clause comparison

## Open Questions
- Strict calibration criterion (mean < 4.5) not met (got 4.68). Cross-model judging may be needed for Phase 46+.

## Artifacts Changed
- `eval/reasoning/corpus/011-020` (10 new harder scenarios)
- `eval/reasoning/judges/reasoning-judge-v2.md` (exemplar-based judge)
- `eval/reasoning/baseline/results-v2.json` (calibrated baseline)
- `wiki/heuristics/SCHEMA.md` (iron status enum)
- `wiki/heuristics/IRON-*.md` (5 IRON RULES)
- `eval/reasoning/with-iron-rules/results.json` (delta measurement)
- `eval/reasoning/iron-rules-crossref.md` (conflict analysis)
- `eval/reasoning/README.md` (updated docs)
- `tests/test_templates.sh` (+5 assertions)

## Related
- [[phase-45-eval-calibration-iron-rules|Phase 45: Eval Calibration & IRON RULES]] — parent phase

## Soft Observations / Phase N+1 Candidates
- IRON-004 (simpler system) caused regression on scenario 018 — pushed agent toward incremental cleanup when expert recommends dedicated sprint. Rules can have unintended negative effects. | Per-rule regression analysis as standard eval practice | Evidence: with-iron-rules/results.json scenario 018 delta
- Original 10 easy scenarios still mostly at ceiling with v2 judge — differentiation comes from hard scenarios, not stricter judging of easy ones. | Difficulty-stratified scoring as standard reporting | Evidence: baseline/results-v2.json vs baseline/results.json

### Activation Quality
- Active-knowledge entries: 10/10 hit rate (100%). All entries referenced during implementation.

### Retro Check (Phases 36-45)

Retro check: no systemic issues. 0 recurring blockers, 0 reversals, 2 documented user overrides (Phases 36-37, escape hatches with justification).
