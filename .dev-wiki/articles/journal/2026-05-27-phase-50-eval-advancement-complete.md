---
title: "Phase 50 complete — eval advancement (length-sensitivity negative, cross-model Haiku passes, harder scenarios 15/15)"
aliases: []
category: journal
tags: [eval, reasoning, length-sensitivity, cross-model, calibration, harder-scenarios]
parents: [phase-50-eval-advancement]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 50 complete — Eval Advancement

## What Happened
- Three sequential experiments to advance reasoning eval capability
- **Experiment 1 (Length-Sensitivity)**: NEGATIVE RESULT. Filler text (579 words, cooking/gardening domain) produced zero delta vs baseline. Model actively discards irrelevant content -- length-sensitivity experiment doesn't cleanly isolate length variable because irrelevant text is ignored. IRON RULES interference is content-specific, not length-driven.
- **Experiment 2 (Cross-Model Judging)**: Haiku judge passes calibration (mean=4.07, 37.8% below 5). Sonnet was not tested (jumped to Haiku per fallback sequence). Haiku shows high inter-run variance (mean ranges 2.97-4.85) -- needs investigation. Self-judge calibration still fails (mean 4.83).
- **Experiment 3 (Harder Scenarios)**: 5 new scenarios (021-025) with genuine multi-stakeholder ambiguity. Zero judge variance on fixed reference responses. 15/15 correct with self-judge -- ceiling not reduced. Insight: ceiling is about correct-answer frequency, not scenario difficulty. Need wrong answers or stricter judge.
- Discovered two-phase eval methodology: single-call (agent sees answers) = 100% ceiling; two-phase (agent blind, separate judge) = meaningful differentiation

## Decisions Made
- [[two-phase-eval-methodology|Two-Phase Eval Methodology]] -- extracted this session

## Problems Solved
- Single-call eval ceiling at 100% -- resolved by separating agent response generation from judge scoring
- Cross-model calibration -- Haiku passes where self-judge fails (mean 4.07 vs 4.83)

## Open Questions
- Haiku judge inter-run variance (mean ranges 2.97-4.85) -- possibly caused by recommendation length sensitivity
- IRON-004 scoping for deadline-constrained scenarios -- "simpler system wins" overrides domain reasoning on 015
- Whether "meta-decision" scenarios (like 020) can be systematically expanded
- MCP memory data loss not investigated this phase (0 entries at start, was populated in prior phases)

## Artifacts Changed
- `eval/reasoning/length-sensitivity/filler-text.md` (579-word coherent filler text)
- `eval/reasoning/length-sensitivity/results.json` (3-condition x 20 scenarios x 3 runs)
- `eval/reasoning/judges/cross-model-judge.md` (Haiku judge protocol)
- `eval/reasoning/cross-model/results.json` (responses + judge_model/agent_model metadata)
- `eval/reasoning/corpus/021-025` (5 new harder scenarios)
- `eval/reasoning/run-eval.py` (--length-test, --cross-judge modes added)
- `eval/reasoning/traces/phase-50-analysis.md` (combined analysis document)
- `eval/reasoning/baseline/results-25.json` (full 25-scenario results)
- `eval/reasoning/with-iron-rules/results-25.json` (full 25-scenario IRON RULES results)

## Related
- [[phase-50-eval-advancement|Phase 50: Eval Advancement]]
- [[two-phase-eval-methodology|Two-Phase Eval Methodology]]

## Soft Observations / Phase N+1 Candidates
- IRON-004 interference is content-specific: biases toward rewrite on deadline-constrained scenarios where incremental is safer. "Simpler lifecycle" framing overrides "lower delivery risk" argument. | Per-scenario IRON RULE gating or IRON-004 revision | evidence: phase-50-analysis.md
- Scenario 020 (meta-decision: capacity multiplier) consistently wrong across all conditions (8/9 choose dependency upgrade, 0 choose test reliability). Genuine model gap in "choose the initiative that unblocks other initiatives" reasoning. | Dedicated capacity-multiplier training scenarios | evidence: phase-50-analysis.md
- Haiku judge variance may be systematic -- recommendation length or response structure could bias scoring | Haiku judge stability investigation | evidence: cross-model/results.json
