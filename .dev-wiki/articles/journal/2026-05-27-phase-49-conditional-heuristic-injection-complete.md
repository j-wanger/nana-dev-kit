---
title: "Phase 49 complete (negative result — conditional injection zero delta)"
aliases: []
category: journal
tags: [eval, heuristic, injection, classification, negative-result]
parents: [phase-49-conditional-heuristic-injection]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 49 complete (negative result — conditional injection zero delta)

## What Happened
- Defined 3-type scenario taxonomy (risk-dominant, capacity-constraint, domain-nuance) with property-based criteria
- Classified all 20 reasoning scenarios with scenario_type field
- Wrote conditional injection template gating on scenario_type (risk-dominant suppresses IRON RULES)
- Added --conditional analysis mode to run-eval.py (~70 lines)
- Ran 3-condition fresh eval: no-inject, always-inject, conditional — all conditions run in same round per fresh-runs-deviation decision
- Early falsification on 015: baseline showed no stochastic error without rules (3/3 clean), so proceeded with full eval
- **Result: conditional injection provides zero delta vs always-inject.** Stochastic interference from Phase 48 did not reproduce in fresh runs
- Judge hallucinated IRON-004 interference on scenario 018 (response was correct but scored low) — self-grading bias artifact

## Problems Solved
- Baseline divergence resolved by running all conditions fresh in same round
- Stochastic interference finding from Phase 48 was non-reproducible (baseline variance, not rule-induced)

## Open Questions
- Length-sensitivity may be the relevant variable for injection effects, not scenario type (Phase 46 context dilution supports this)
- Cross-model judging needed to break self-grading bias
- MCP memory completely empty (0 entries) — all prior bridge-decisions lost, needs investigation

## Artifacts Changed
- `eval/reasoning/scenario-type-taxonomy.md` (new — 3-type taxonomy)
- `eval/reasoning/corpus/*.json` (20 files — added scenario_type field)
- `eval/reasoning/conditional-injection.md` (new — gate template)
- `eval/reasoning/run-eval.py` (added --conditional mode)
- `eval/reasoning/with-conditional/results.json` (new)
- `eval/reasoning/baseline/results.json` (overwritten with fresh v3 data)
- `eval/reasoning/with-iron-rules/results.json` (overwritten with fresh v3 data)
- `eval/reasoning/traces/conditional-analysis.md` (new)

## Related
- [[phase-49-conditional-heuristic-injection|Phase 49: Conditional Heuristic Injection]]

## Soft Observations / Phase N+1 Candidates
- Length-sensitivity as injection variable | investigate prompt-length correlation with score delta across all conditions | conditional-analysis.md length section
- Cross-model judging for calibration | use different model for judge vs agent to break self-grading bias | recurring blocker since Phase 45
- Harder scenario design | current corpus has 16/20 at ceiling, limiting differentiation power | ceiling effect blocker
- MCP memory data loss | investigate why all bridge-decisions from prior phases are gone | memory_stats showing 0 entries

### Activation Quality
Active-knowledge.md had 4 entry groups (stochastic interference, eval methodology, scenario-type taxonomy, eval infrastructure). All 4 were directly relevant and used during implementation. Hit rate: 4/4 (100%).
