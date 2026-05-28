---
title: Cognitive Enhancement Roadmap
created: 2026-05-27
updated: 2026-05-27
status: active
tags: [roadmap, heuristics, reasoning, eval]
---

# Cognitive Enhancement Roadmap

> Goal: Build a heuristic learning system that measurably improves reasoning quality.
> Source: [[cognitive-enhancement-plan]] decision (2026-05-26), Phase 44 spec §Context.
> Design principles: eval before feature, content before infrastructure, one variable at a time, own history as test corpus.

## Phase Status

| # | Planned Name | Actual Phase | Status | Key Artifacts | Notes |
|---|-------------|-------------|--------|---------------|-------|
| 1 | Heuristic schema, 10 seeds, baseline eval | Phase 44 | **DONE** | wiki/heuristics/SCHEMA.md, HEU-001–010, eval/reasoning/ | As planned |
| 2 | Heuristic capture in dev-debrief | Phase 46 | **DONE** | heuristic-capture.md (Step 4.8, 60 lines) | Reordered — landed in Phase 46 alongside anti-pattern tables |
| 3 | IRON RULES + anti-pattern tables | Phase 45+46 | **DONE** | IRON-001–005, anti-pattern tables (3 rows each), judge v2 | Split across two phases; eval calibration added to Phase 45 |
| 4 | Self-dialogue in dev-plan | Phase 47 | **DONE** | self-dialogue-prompt.md, self-dialogue-injection.md, 2 eval conditions | **Negative result**: inline net negative, subagent net neutral |
| 5 | Trace collection + pattern analysis | Phase 48 | **DONE** | eval/reasoning/traces/, attribution-matrix.json, selection-criteria.md | **Negative result**: per-rule selection not viable (stochastic interference); reframes to scenario-type classification |
| 6 | Prompt-type hooks (LLM-as-judge during execution) | Phase 51 | **DONE** | heuristic-matcher.md, heuristic-judge-prompt.md, SKILL.md Step 6.5, ground-truth.json (25 scenarios, 84% coverage) | As planned |
| 7 | Heuristic evolution (helpful/harmful scoring, deprecation) | Phase 52 | **DONE** | heuristic-counter-update.md, heuristic-lifecycle.md, heuristic-dashboard.py, SCHEMA.md lifecycle section | Uniform global verdict attribution (known approximation) |

## Eval Baseline & Deltas

| Condition | Mean Score | % Below 5 | Delta vs Baseline | Phase |
|-----------|-----------|-----------|-------------------|-------|
| Baseline (no heuristics, judge v1) | ~5.0 | 0% | — | 44 |
| Baseline (judge v2, exemplar-anchored) | 4.68 | 19.4% | — (recalibrated) | 45 |
| + IRON RULES | — | — | +5 (net) | 45 |
| + Anti-pattern tables | ~4.83 | — | scenario 018 +2.67, scenario 012 -0.67 | 46 |
| + Self-dialogue (inline) | — | — | net negative (hedging, not depth) | 47 |
| + Self-dialogue (subagent) | — | — | net neutral (no measurable improvement) | 47 |

## Open Questions (carrying forward)

- Baseline divergence: fresh eval scores differ from prior phases due to condensed prompt format — cross-round comparisons invalid
- Ceiling effect: 4/5 scenarios at 5/5/5 limits differentiation power — need harder scenarios
- Strict calibration target (mean < 4.5) still unmet. Cross-model judging identified as next lever
- Self-grading bias constant across conditions — relative comparisons valid, absolute scores inflated
- Stochastic interference: scenario 015 interference ~1/3 of runs, not rule-specific — per-rule selection not viable, scenario-type classification (all-or-nothing) is the right framing
- Self-dialogue adds hedging not depth: devil's advocate without novel information generates compelling but shallow counterarguments

## Cross-References

- Decision: [[cognitive-enhancement-plan]] — architecture and design principles
- Decision: [[eval-calibration-exemplar-based-judge-anchoring]] — judge v2 design
- Decision: [[iron-rules-as-iron-status-heuristics]] — IRON RULES format
- Decision: [[anti-pattern-table-format-extension]] — structured failure mode tables
- Decision: [[iron-004-lifecycle-complexity-fix]] — IRON-004 regression fix
- Spec: specs/phase-44-heuristic-learning-foundation.md (original roadmap source)
- Spec: specs/phase-45-eval-calibration-iron-rules.md
- Decision: [[self-dialogue-dual-condition-eval]] — dual-condition eval design
- Decision: [[stochastic-heuristic-interference]] — LOO ablation negative result (Phase 48)
- Decision: [[full-spec-ablation-scope]] — comprehensive ablation scope (Phase 48)
- Spec: specs/phase-48-trace-collection-pattern-analysis.md
- Spec: specs/phase-47-self-dialogue-in-dev-plan.md
- Spec: specs/phase-46-anti-pattern-tables-heuristic-capture.md
