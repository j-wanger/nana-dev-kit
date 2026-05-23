---
title: "Cross-skill reference validation at test time"
aliases: [cross-skill-ref, skill-reference-validation]
category: decisions
tags: [testing, skills, references]
parents: [phase-26-memory-harness-hardening]
created: 2026-05-23
updated: 2026-05-23
source: plan
confidence: high
---

## Context

22 skill directories contain ~198 absolute path references to ~/.claude/skills/. Broken references after file renames or moves cause silent skill failures. No automated detection exists.

## Decision

Add test_cross_skill_references function in test_templates.sh. Grep all ~/.claude/skills/ absolute path references from skill files, map to templates/ paths, check file existence, output file:line for broken refs. Cheapest option, fits existing test pattern.

Alternatives rejected:
- Eval scenario: heavier, not the right abstraction for structural checks
- Pre-commit hook: too slow for every commit
- Registry indirection: over-engineering for current scale

## Consequences

Broken cross-skill references caught at make test time. Fix-as-you-find approach -- test discovers breaks, same task fixes them. No runtime overhead. Scales with skill count automatically.
