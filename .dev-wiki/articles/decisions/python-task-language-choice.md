---
title: "Python task language choice for comparison"
aliases: [python-task-choice, comparison-language]
category: decisions
tags: [eval, comparison, methodology, python]
parents: [phase-42-harness-effectiveness-validation]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

The comparison tasks need a programming language. The harness includes Python-specific skills (py-lint, py-review, py-test, py-init) that represent a significant portion of active harness value. Choosing a language without harness skills would understate harness value by not exercising these tools.

## Decision

Tasks are Python because the harness has Python-specific skills. This maximizes the measurable difference between conditions, especially for condition C (full harness) where py-* skills are available. Alternative considered: language-agnostic tasks (would not exercise py-* skills, understating harness value).

## Consequences

- Comparison measures full harness value including language-specific tooling
- Results are specific to Python development — generalization to other languages requires separate testing
- Feature-build and bug-fix tasks can leverage pytest, ruff, mypy ecosystem
- TypeScript comparison would be a natural follow-up (harness also has ts-init)
