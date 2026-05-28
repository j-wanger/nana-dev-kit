---
title: "Early Falsification Checkpoint"
aliases: [early-falsification, 015-falsification-check]
category: decisions
tags: [eval, methodology, falsification, efficiency]
parents: [phase-49-conditional-heuristic-injection]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

The conditional injection premise rests on scenario 015 interference being rule-induced: IRON RULES cause ~1/3 stochastic error on 015. If the same ~1/3 error rate appears in 015 WITHOUT IRON RULES (no-inject baseline), the interference is inherent model variance on that scenario, and conditional injection cannot help — the premise is falsified.

## Decision

Run no-inject on scenario 015 first (3 runs) before the full 3-condition eval. If the baseline shows ~1/3 stochastic error without IRON RULES, report a negative result and stop — saving ~177 invocations. Only proceed to the full eval if the no-inject baseline on 015 is clean (3/3 passes or at most 1/3 failures consistent with normal variance).

Alternative considered: run all 180 invocations regardless and analyze after. Rejected because it is wasteful if the premise is false, and the falsification check is cheap (3 invocations + 3 judge calls).

## Consequences

- Early termination path saves ~177 invocations if premise is falsified
- Still produces a documented negative result (valuable finding)
- Requires clear pass/fail threshold for the falsification check (defined as: if no-inject 015 shows >= 1/3 runs with mean < 4.0, premise is falsified)
- The full eval only runs when there is reasonable evidence that conditional injection could work
