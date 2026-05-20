---
title: "Spec two-tier review gate"
aliases: [two-tier review, spec review gate, structural lint + semantic review]
category: decisions
tags: [spec, review, quality-gate, structural-lint, semantic-review]
parents: [phase-08-spec-skill]
created: 2026-05-19
updated: 2026-05-19
source: debrief
confidence: high
---

## Context

The /spec skill produces structured contracts (specs) that downstream phases depend on. Low-quality specs cause cascading rework. Needed a review gate that catches both mechanical format issues and deeper semantic gaps, without being so heavyweight that it discourages spec creation.

## Decision

Two-tier review gate: Tier 0 (structural lint, inline, deterministic) checks 9 H2 headers, scope subsections, bullet counts, and self-containment phrases. Tier 1 (semantic review, subagent) evaluates 6 dimensions: ambiguity, constraint completeness, exit criteria verifiability, checkpoint proportionality, assumption explicitness, and self-containment. Dogfooding validation: Sonnet caught structural gaps (6/10), Opus caught semantic gaps (8/10).

## Consequences

- Structural lint is cheap and fast -- catches format errors before expensive semantic review
- Semantic review uses 6 scored dimensions, providing actionable feedback rather than pass/fail
- Pattern is generalizable: two-tier (structural + semantic) can apply to other skill-produced artifacts
- Dogfooding showed the gap between tiers: structural alone missed semantic issues that only Opus caught
