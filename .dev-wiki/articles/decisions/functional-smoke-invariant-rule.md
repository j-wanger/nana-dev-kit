---
title: "Functional smoke invariant: every registered component needs a functional test"
aliases: [functional-smoke-invariant]
category: decisions
tags: [testing, prevention, anti-pattern, invariant]
confidence: high
source: plan
created: 2026-05-25
updated: 2026-05-25
---

## Decision

Codify as a spec/dev-plan rule: "Every component registered in settings.json or install.sh must have at least one functional test that exercises it (pipe input through, check output), not just structural (check file exists)."

## Context

4 instances of silent breakage persisted across 8-33 phases. Root cause in all cases: fail-open semantics + structural-only tests. The Phase 38 response (functional tests) was the correct structural fix. This rule codifies it as a preventive invariant.

Evidence:
- MCP CWD bug: 33 phases. Tests checked config key presence, never tested server start.
- pre-compact.sh orphan: 8 phases. File existed, never registered.
- memory-harvest.md API: 11 phases. Invalid category enums, fail-open hid errors.
- PROJECT_STATE.md: 8 phases. session-start.sh read a file nothing created.

## Implementation

1. Add to spec skill: when a spec includes a new hook, skill, or install.sh change, the exit criteria must include a functional test.
2. Add to dev-plan integration checklist: "Does every new component have a functional test? Is registration verified in settings.json AND install.sh?"

## Status

Implemented in Phase 40. Codified in spec SKILL.md Step 2.6 and dev-plan implementation-guide.md integration checklist. Confidence confirmed high.
