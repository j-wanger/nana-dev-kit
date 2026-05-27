---
title: "Phase 48 complete (stochastic interference — negative result)"
aliases: []
category: journal
tags: [eval, ablation, iron-rules, trace, reasoning, negative-result]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 48: Trace Collection & Pattern Analysis — Complete

## What Happened
- Built trace infrastructure: traces/ directory, trace-schema.json, extended run-eval.py with --ablation and --analyze modes (~100 lines)
- Executed ~75 subagent invocations: fresh baseline (15), full-set (15), leave-one-out on 5 IRON RULES x 3 training scenarios x 3 runs (45)
- Key finding (NEGATIVE RESULT): scenario 015 interference is stochastic (~1/3 of runs), not attributable to any specific IRON RULE. Removing IRON-004 does NOT fix it — contradicts Phase 45-47 hypothesis
- IRON-001 confirmed load-bearing for scenario 020 (removal causes regression)
- Baseline divergence: fresh eval scores differ from prior phases due to condensed prompt format — cross-round comparisons invalid, within-round deltas valid
- Ceiling effect: 4/5 scenarios score 5/5/5 in both baseline and full-set, severely limiting differentiation power

## Decisions Made
- [[full-spec-ablation-scope|Full-Spec Ablation Scope]] -- confidence upgraded medium -> high (validated by execution)
- [[sequential-baseline-verification|Sequential Baseline Verification]] -- confidence upgraded medium -> high
- [[scenario-type-selection-criteria|Scenario-Type Selection Criteria]] -- confidence upgraded medium -> high
- [[no-prompt-length-padding|No Prompt-Length Padding]] -- confidence upgraded medium -> high
- [[stochastic-heuristic-interference|Stochastic Heuristic Interference]] -- new, high confidence (negative result)

## Open Questions
- Baseline divergence: fresh eval scores differ from prior phases — cross-round comparisons invalid
- Scenario corpus needs harder scenarios — 4/5 at ceiling limits differentiation power
- Cross-model judging (different model for judge vs agent) remains untested calibration lever

## Artifacts Changed
- `eval/reasoning/traces/` (7 trace files + attribution-matrix.json + selection-criteria.md)
- `eval/reasoning/trace-schema.json` (new JSON schema)
- `eval/reasoning/run-eval.py` (--ablation and --analyze modes, ~100 lines added)
- `eval/reasoning/README.md` (Ablation Analysis section)
- `tests/test_templates.sh` (+5 assertions)

## Related
- [[phase-48-trace-collection-pattern-analysis|Phase 48: Trace Collection & Pattern Analysis]]
- [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] — Phase 5 of 7

## Soft Observations / Phase N+1 Candidates
- Baseline divergence from prior phases: condensed prompt format produces higher scores. Within-round valid, cross-round invalid. Need identical prompts for true comparison or accept within-round deltas only. | Evidence: baseline-no-heuristics.json vs prior results-v2.json
- Ceiling effect: 4/5 scenarios at 5/5/5 in both baseline and full-set. Ablation differentiation power severely limited. | Next phase: harder scenarios corpus expansion
- Stochastic interference suggests scenario-type classification (all-or-nothing injection) rather than per-rule exclusion. Reframes Phase 49 approach from fine-grained selection to coarse classification. | Evidence: attribution-matrix.json

### Activation Quality
4 active-knowledge entries, 4 hit (100%). All entries directly applicable: ablation methodology guided LOO execution, payload-size confound drove 012 diagnostic interpretation, selection criteria design informed attribution-matrix structure, IRON RULES interference prior was tested and partially refuted (stochastic, not rule-specific).

### Health Delta
- +5 test assertions in tests/test_templates.sh
- make test: all pass (162+ tests)
- make eval: 50/50 (100%)
