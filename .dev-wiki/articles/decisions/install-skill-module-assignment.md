---
title: "Skills module assignment: nana/memory-consolidate to core, py-lint/py-review/py-test to python"
aliases: [skill-module-assignment]
category: decisions
tags: [install, modules, skills]
parents: [phase-38-install-integrity-functional-verification]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

Phase 36 hook reconciliation revealed 5 skills present in templates/.claude/skills/ but missing from install.sh: nana, memory-consolidate, py-lint, py-review, py-test. These skills need to be assigned to the correct install.sh module groups (core, python, dev-wiki, knowledge-wiki, typescript).

## Decision

Assign nana + memory-consolidate to CORE_SKILLS (they are language-agnostic utility skills needed in all installations). Assign py-lint + py-review + py-test to PYTHON_SKILLS (they are Python-specific and should be excluded by --no-python / --core-only flags).

Alternatives considered:
- All 5 to core: rejected because py-lint/py-review/py-test are Python-specific and would bloat --core-only installs.
- All 5 to a new "utility" module: rejected as unnecessary complexity for 5 skills that fit existing categories.

## Consequences

- --core-only now installs nana and memory-consolidate (useful for non-Python projects).
- --no-python correctly excludes py-lint, py-review, py-test.
- No new module groups needed.
