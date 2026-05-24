---
title: "Settings registration: global only"
aliases: [enforce-memory-global-registration]
category: decisions
tags: [enforcement, hooks, install]
parents: [phase-31-integration-eval-memory-gating]
created: 2026-05-23
updated: 2026-05-24
source: debrief
confidence: high
status: active
---

## Context

enforce-memory.sh needs to be registered in settings.json as a PreToolUse hook. The question was whether to register it in the project template (templates/.claude/settings.json) or only globally (~/.claude/settings.json via install.sh).

## Decision

Register enforce-memory.sh in ~/.claude/settings.json via install.sh only. Do NOT add it to templates/.claude/settings.json. This matches the enforce-spec.sh pattern where enforcement hooks are global infrastructure, not project-template concerns.

## Consequences

- Enforcement hooks remain global, consistent with enforce-spec.sh and enforce-loop.sh patterns.
- Projects scaffolded from templates don't inherit enforcement hook registrations.
- install.sh is the single point of enforcement hook registration.
- Users who skip install.sh don't get enforcement hooks (by design).
