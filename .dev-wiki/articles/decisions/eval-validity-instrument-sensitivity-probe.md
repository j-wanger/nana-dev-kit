---
title: "Net-zero is ambiguous; an instrument-sensitivity probe must precede any cut-by-eval"
aliases: ["eval-validity-instrument-sensitivity-probe", "instrument-sensitivity-probe", "phase-63-eval-spine"]
category: decisions
tags: [eval-validity, instrument-sensitivity, measurement, llm-judge, subtraction-test]
parents: [phase-63-harness-assessment-eval-validity]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The maintainer no longer trusts the evaluation apparatus that drove the 58/59/61 cuts. `eval/comparison/methodology.md` itself admits the only comparison exercising the full harness (A-vs-C) is confounded by the subagent capability gap, is N=1 "directional not significant," self-graded, and Python-only. A net-zero delta from such an instrument is genuinely ambiguous: the feature may be worthless, OR the instrument may be blind (unable to separate any signal from noise). You cannot tell which from the number alone — yet net-zeros have been treated as evidence-for-cut.

## Decision

Before any net-zero result is allowed to justify a cut, run an instrument-sensitivity probe: inject a deliberately known-good and a deliberately known-broken variant of some component into the apparatus and observe whether it produces a non-zero delta. An instrument that cannot separate broken-from-baseline cannot inform cuts. The probe records a verdict token — `instrument: sensitive | blind | mixed | untested` — with the measured delta. This is the centerpiece (spine) of the phase, distinct from and higher-order than any component verdict.

Distinguish the two sub-instruments: the deterministic binary corpus eval (`make eval`, 54 scenarios, pass/fail) is likely sensitive; the LLM-judge reasoning/comparison evals (N=1, self-graded, capability-gap-confounded) are the suspected-blind ones. The probe characterizes the suspect.

## Consequences

If the probe shows the apparatus is blind, the cut-justification-by-eval path STOPS — that finding is itself the apparatus verdict, independent of any feature, and remaining effort pivots to proposing a non-blind eval (the higher-order deliverable). Slam-dunk cuts can still proceed on affirmative non-eval evidence (firing tests per [[deadweight-requires-affirmative-evidence]]); only cuts that rely on a net-zero delta are gated on the probe showing `sensitive`. This breaks the "measured, ambiguous, deferred" cycle by characterizing the instrument rather than producing more verdicts from a distrusted one.
