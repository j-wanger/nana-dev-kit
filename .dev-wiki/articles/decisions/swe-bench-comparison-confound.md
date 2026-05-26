---
title: "SWE-bench comparison confound: acceptance test asymmetry"
aliases: [test-asymmetry-confound, acceptance-test-confound]
category: decisions
tags: [eval, comparison, methodology, confound, swe-bench]
parents: [phase-42-harness-effectiveness-validation]
created: 2026-05-26
updated: 2026-05-26
source: debrief
confidence: high
---

## Context

Condition C (full harness, manual user session) had access to gold acceptance tests (structural SQL checks like "count SELECTs") during development. Conditions A and B did not — they only had correctness tests (right numeric results). C scored 4/4 while A and B scored 3/4. The gap is partly explained by this information asymmetry, not solely by interactive iteration or harness features.

## Decision

Acknowledged the confound explicitly in results documentation. The 4/4 vs 3/4 gap measures "harness + acceptance tests" not "harness alone." Both A and B produce correct query results — they just use different SQL shapes that fail structural assertions. Future comparison iterations should either give all conditions the same acceptance tests or measure only result correctness.

## Consequences

- Results cannot claim the full quality gap is attributable to the harness
- The A-vs-B comparison (same test access) remains valid and unconfounded
- Future experiments need test-access parity as an explicit design constraint
- The confound is a useful finding: it shows that acceptance test design matters as much as the development harness
