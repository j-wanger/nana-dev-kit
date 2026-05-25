---
title: "PostToolUse normalization: verify then normalize"
aliases: [posttooluse-normalize-after-verification, posttooluse-field-normalization]
category: decisions
tags: [hooks, posttooluse, field-path, normalization]
parents: [phase-39-resilience-health-probes]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

PostToolUse hooks have inconsistent field access: 3 hooks use `.input.file_path` (audit-log, auto-ruff, scan-secrets), 2 use `.tool_input` (post-commit, stale-queue). Both patterns work in practice, but this creates maintenance confusion and makes it unclear which is canonical. Phase 38 documented the inconsistency; Phase 39 resolves it.

## Decision

After live verification of the actual PostToolUse stdin JSON structure (via temporary diagnostic hook that dumps raw stdin), normalize ALL PostToolUse Edit/Write hooks to the verified canonical path. Add a defensive fallback (`jq '.input.file_path // .tool_input.file_path // empty'`) as a transitional guard only — to be removed once verification confirms the canonical path is stable across Claude Code versions.

Rejected alternatives:
- **Keep both patterns** — creates perpetual inconsistency, confuses future contributors, makes eval fixtures ambiguous.
- **Pick one without verification** — risks silent breakage if the chosen path isn't the actual one Claude Code sends.

## Consequences

- All PostToolUse hooks will use a single, verified field path.
- Eval fixtures and schemas updated to match the canonical path.
- Transitional fallback adds ~1 line per hook but ensures no breakage during verification period.
- Future hooks can be written with confidence about the correct field path.
