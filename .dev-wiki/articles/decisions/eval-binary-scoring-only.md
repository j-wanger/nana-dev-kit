---
title: "Binary scoring only for eval harness"
aliases: [eval-binary-scoring-only]
category: decisions
tags: [eval, scoring, simplicity]
parents: [phase-20-eval-harness]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: medium
---

## Context

The eval harness spec included both binary (pass/fail) and ternary (with partial credit) scoring modes. Ternary scoring adds runner complexity: partial_condition fields in manifests, 0.5 score path, and ambiguous pass definitions for advisory hooks.

## Decision

Start with binary scoring only (pass=1.0, fail=0.0). Ternary/weighted scoring is deferred as a future enhancement if granularity proves insufficient. This reduces runner complexity by ~30% and satisfies all exit criteria without loss of diagnostic power.

Alternative considered: ternary with explicit `partial_condition` in manifests -- deferred, not rejected. If advisory hooks (detect-loop, session-start) need finer-grained scoring, ternary can be added without changing existing scenario manifests.

## Consequences

All scenarios produce binary scores. Category averages and overall score are simple arithmetic means. No weighted category aggregation needed in v1. Future ternary upgrade is additive (new field in manifest, new code path in runner) -- existing binary scenarios remain valid.
