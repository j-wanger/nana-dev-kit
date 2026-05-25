---
title: "PostToolUse field path inconsistency: document only, don't fix"
aliases: [posttooluse-field-path, posttooluse-inconsistency]
category: decisions
tags: [hooks, posttooluse, field-path]
parents: [phase-38-install-integrity-functional-verification]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: medium
---

## Context

PostToolUse hooks in the kit use two different JSON field paths: 3 hooks use `.input.file_path` (audit-log, auto-ruff-format, scan-secrets) while 2 hooks use `.tool_input` (post-commit, stale-queue). The correct field path cannot be confirmed without live Claude Code verification because the Claude Code hook documentation doesn't explicitly specify the PostToolUse stdin schema.

## Decision

Document the inconsistency in _ARCHITECTURE.md Known Issues section. Do not fix either set of hooks until live verification confirms the correct field path. Premature normalization risks breaking working hooks.

Alternatives considered:
- Normalize all to .input.file_path: rejected because the 3 hooks using it may be wrong — we confirmed .input.file_path is correct for PreToolUse but PostToolUse may differ.
- Normalize all to .tool_input: rejected for same uncertainty reason.

## Consequences

- Known issue documented for future phases.
- Hooks continue working as-is (both field paths have been tested via eval scenarios for their respective hooks).
- Needs live Claude Code session to resolve definitively.
