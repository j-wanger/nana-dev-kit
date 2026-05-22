---
title: "Adversarial constraint generation as spec Step 2.5"
aliases: [adversarial-constraints, spec-step-2-5, constraint-generation]
category: decisions
tags: [spec, adversarial, constraint-generation, subagent]
parents: [phase-14-adversarial-thinking-and-review]
created: 2026-05-21
updated: 2026-05-21
source: plan
confidence: high
---

## Context

Spec authoring suffers from same-context confirmation bias — the author who applies the thinking protocol also drafts the spec, so constraints reflect priors already baked into the approach. This is the "grading-own-homework" problem from AgentCoder 3-agent separation research.

## Decision

New Step 2.5 between "Apply Thinking Protocol" and "Draft Spec." Clean-context subagent receives ONLY objective + context, generates constraints with falsifiability tests, edge cases, and scope risks independently. Author incorporates or rejects each item before drafting. Companion file adversarial-constraints-prompt.md (~40-50 lines) houses the subagent prompt.

## Consequences

- Moves adversarial thinking upstream from review to authoring stage
- Clean-context subagent breaks shared-prior confirmation bias (no access to approach/decisions)
- Adds token cost for subagent invocation — acceptable for standard ceremony specs
- Spec SKILL.md grows by ~20 lines (must stay ≤350)
- Strengthening existing Tier 1 reviewer was rejected (doesn't fix authoring-stage bias)
- Adding adversarial dimension to Tier 0 lint was rejected (structural only, can't generate constraints)
