---
title: "SKILL.md ceiling 250 to 350"
aliases: [skill-ceiling-raise, complex-orchestration-350]
category: decisions
tags: [skills, budgets, self-check, process]
parents: [phase-13-final-polish-and-ship]
created: 2026-05-20
updated: 2026-05-20
source: plan
confidence: high
---

## Context

12 phases of real usage showed the 250-line complex-orchestration SKILL.md ceiling is too tight. dev-debrief reached 310 lines, dev-plan reached 335 lines. Both are working designs that would require artificial splitting to fit 250. The ceiling is advisory (in self-check-checklist.md, not enforced by tests) but creates false-positive warnings during post-implementation self-checks.

## Decision

Raise the complex-orchestration ceiling from 250 to 350 in self-check-checklist.md. This acknowledges reality without removing the guardrail entirely. Refactoring the largest skills is future work that should be driven by usability feedback, not an arbitrary line count.

Alternative rejected: remove ceiling entirely (some guardrail is better than none -- unbounded growth creates maintenance burden). Alternative rejected: refactor skills to fit 250 (premature -- would require splitting working designs that have proven stable across 12 phases).

## Consequences

Self-check no longer flags dev-debrief and dev-plan as oversized. The ceiling still catches genuinely bloated skill files. Future skill authors have more room but still have a constraint to design against. Refactoring debt is acknowledged and deferred.
