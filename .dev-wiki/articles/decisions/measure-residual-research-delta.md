---
title: "Measure residual research delta, not the headline +1.75"
aliases: ["residual-delta", "research-measurement", "subtraction-test-research"]
category: decisions
tags: [measurement, eval, residual-delta, subtraction-test, baseline, phase-55]
parents: [phase-58-active-domain-research-in-dev-plan]
created: 2026-05-28
updated: 2026-05-28
source: plan
status: accepted
confidence: high
phase: 58
---

## Decision

Measure the **residual** quality delta that active research adds over the Phase-55 baseline — not the headline `+1.75`. The measurement isolates active-research as the *only* changed variable against the current Phase-55 baseline and reports the delta honestly. A ~0 or negative result is acceptable and triggers a keep/trim/cut decision at Checkpoint 2 (subtraction test).

## Context

A prior experiment reported a `+1.75` composite quality delta for open-ended prompts that do real domain research. But that experiment conflated several variables, AND part of the win (less-prescriptive specs) was already captured by the Phase 55 spec reform. The true *residual* value of adding active research is therefore unknown and must be measured, not assumed.

## Rationale

- **Re-claiming the full +1.75 would be confounded** — Phase 55 already banked the less-prescriptive-spec portion. Attributing it again to Step 2.7 double-counts.
- **Isolate one variable**: hold the Phase-55 baseline fixed, toggle only active-research on/off, measure the gap.
- **Subtraction test**: if research never changes the approach, the feature has not earned its complexity. A credible negative result is a real outcome, not a failure to hide — it directly informs the keep/trim/cut decision.

## Alternatives considered

- **Re-claim the full +1.75 (rejected):** confounded — part of the delta belongs to Phase 55, and the original experiment mixed multiple variables.

## Consequences

- The measurement artifact records a numeric with-vs-without delta against the Phase-55 baseline, human-gated at Checkpoint 2 (`test -f` alone does not self-declare done).
- A ~0/negative residual is an explicit branch in the plan: STOP, present honestly, let the user decide keep/trim/cut.

## Result (Phase 58 run)

Confidence is **high for the method**, but **medium/directional for the result**: the measured residual was **+0.5 composite (reasoning 3→4) at n=1**, on a research-favorable topic — at the project's significance threshold with unknown variance. Non-theatrical (research produced a decision-changing finding the baseline missed). Kept at Checkpoint 2. Do NOT treat +0.5 as banked; strengthen with 2–3 more topics (incl. a research-poor one) before trusting the number. See `eval/research-measurement/results.md`.

## Source

Phase 58 plan. Honest-measurement posture; subtraction test from nana-soul. Consumes the Phase-55 baseline as the comparison reference.
