---
title: "No eval scenario updates needed for scope-check fix"
aliases: [no-eval-scope-check-scenarios]
category: decisions
tags: [eval, scope-check, hooks]
parents: [phase-38-install-integrity-functional-verification]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

Before fixing dev-wiki-scope-check.sh's field path from .tool_input.file_path to .input.file_path, needed to confirm no existing eval scenarios reference the old field path and would break.

## Decision

No eval scenario updates needed. Confirmed no existing eval/corpus/ scenarios test dev-wiki-scope-check.sh. The fix can proceed without eval corpus changes. Functional verification of the fixed hook will be added as new test assertions in test_install.sh (Task 5).

## Consequences

- Scope-check fix is isolated to the hook file itself.
- New functional test (Task 5d) validates the corrected field path via pipe-through testing.
