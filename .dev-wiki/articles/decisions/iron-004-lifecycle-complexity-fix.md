---
title: "IRON-004 lifecycle complexity fix"
aliases: [iron-004-fix, lifecycle-complexity-distinction]
category: decisions
tags: [iron-rules, IRON-004, eval, regression-fix]
parents: [phase-46-anti-pattern-tables-heuristic-capture]
created: 2026-05-27
updated: 2026-05-27
source: implementation
confidence: high
---

## Context

IRON-004 ("Simpler system wins") caused a regression on scenario 018 (feature flag debt) — scores dropped from 4/4/5 (baseline) to 2/3/2 (with IRON RULES). The rule's "simpler system" framing pushed toward incremental cleanup when the expert recommends a dedicated sprint to address compounding costs. The root cause: the rule did not distinguish between "less effort now" and "simpler system over its lifecycle."

## Decision

Add a Never clause to IRON-004 distinguishing upfront effort from lifecycle complexity: "Never confuse 'less effort now' with 'simpler system' — measure simplicity by total lifecycle complexity, not upfront cost." This keeps the rule domain-agnostic (passes transferability test for web apps, data pipelines, CLI tools). Alternatives considered: add a new IRON-006 for compounding costs (rejected — the concept belongs in IRON-004's scope, adding a new rule risks conflict), add a precedence clause between IRON rules (rejected — precedence is between rules, this issue is within one rule's definition).

## Consequences

The fix targets the specific regression mechanism (confusing low upfront effort with simplicity) without weakening the core rule. Scenario 018 should improve by >= 0.5 on mean score. The fix must be validated via eval checkpoint before proceeding to Part B. If the fix causes regressions on 2+ other scenarios, it should be backed out and reported as a blocker.
