---
title: "Structural placeholder verification"
aliases: [placeholder test scope, template test strategy]
category: decisions
tags: [testing, templates, placeholders]
parents: [phase-02-automated-testing]
created: 2026-05-15
updated: 2026-05-15
source: plan
confidence: high
---

## Context

Template files use `{{PLACEHOLDER}}` conventions (e.g., `{{PACKAGE_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{PROJECT_NAME}}`). The `/py-init` skill substitutes these during project scaffolding. Phase 2 needs to test that templates are correct, but `/py-init` is a Claude Code skill -- not scriptable from bash.

## Decision

Tests verify that placeholder patterns exist in template files via grep, not end-to-end substitution. This is structural verification: grep for `{{PACKAGE_NAME}}`, `{{PROJECT_DESCRIPTION}}`, `{{PROJECT_NAME}}` in the expected template files. Placeholder presence is the automatable contract.

Mocking `/py-init` execution was rejected as over-engineering -- it would require simulating Claude Code's skill execution environment, which is outside the project's scope.

## Consequences

- Tests can only verify placeholder presence, not correct substitution behavior
- If a placeholder is renamed in `/py-init` but not in templates, this test catches it (the old name would be missing)
- If `/py-init` adds a new placeholder, the test must be updated manually
- Sufficient for Phase 2 exit criteria since placeholder presence is the testable contract
