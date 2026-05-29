---
title: "Phase 63 is a multi-angle harness self-assessment that cuts, not another feature micro-optimization"
aliases: ["harness-self-assessment-multi-angle", "phase-63-assessment-deliverable"]
category: decisions
tags: [harness, assessment, eval-validity, subtraction-test, multi-agent, deadweight]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Phases 58/59/61 each proposed a feature, measured it against the existing apparatus (the `eval/comparison/` clean-room A/B/C plus the 25-scenario LLM-as-judge reasoning eval), got net-zero/negative, and CUT it. The documented Phase-63 candidate was another such feature: hot-cache eviction value-signal. But that candidate is the weakest by the subtraction test — the usage counter is empirically inert (87/100 entries at `[uses:1]`), so there is no value signal to engineer. More importantly, the recurring "measured, ambiguous, deferred" cycle points at the instrument, not at any single feature: net-zero is ambiguous between a worthless feature and a blind instrument, and no feature phase can resolve that.

## Decision

Phase 63 steps back to assess the whole harness from four angles via a multi-agent workflow (one assessor per angle, per-finding adversarial verification, then synthesis), and executes the evidence-confirmed slam-dunk subtractions in-phase — deliverable = diagnose + cut, not diagnose-only. The eval-validity angle is the spine ([[eval-validity-instrument-sensitivity-probe]]). Two alternatives were rejected:

1. **Another feature phase (eviction value-signal)** — the documented candidate, but weakest by subtraction test (the counter it would tune is inert) and it would be measured by the same distrusted instrument.
2. **Diagnose-only (ship a report)** — produces process theatre: a pile of verdicts and no leaner harness. The phase must leave the harness measurably smaller where evidence is unambiguous.

## Consequences

The phase produces a re-runnable `scripts/harness-audit.sh`, a coherence map, an instrument-sensitivity result, a verdict, executed slam-dunk cuts, and a remediation roadmap. The risk — assessor=assessed reflexivity — is contained by running over a frozen harness state and batching all cuts at the end ([[cuts-are-frozen-batched-migrations]]). It deliberately does NOT build the new eval (proposed only) and does NOT consolidate the 5 memory layers (roadmap). Re-litigating already-decided 58/59/61 cuts is out of scope.
