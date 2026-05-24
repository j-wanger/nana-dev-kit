---
title: "Memory enforcement auto-create"
aliases: [memory-enforcement-default-on]
category: decisions
tags: [enforcement, memory, install]
parents: [phase-31-integration-eval-memory-gating]
created: 2026-05-23
updated: 2026-05-24
source: debrief
confidence: medium
status: active
---

## Context

enforce-memory.sh needs an opt-in marker (~/.claude/enforce-memory) to activate, following the same pattern as enforce-spec.sh (.claude/enforce). The question was whether install.sh should auto-create this marker (default-on) or require manual opt-in.

## Decision

install.sh auto-creates ~/.claude/enforce-memory marker. This makes memory enforcement default-on for kit users, diverging from the project-local .claude/enforce pattern which requires per-project opt-in. The user chose default-on because the kit targets compliance-domain work where memory consultation is a quality gate, not optional.

## Consequences

- Kit users get memory enforcement out of the box without manual setup.
- Diverges from project-local .claude/enforce pattern (home-relative vs CWD-relative).
- Users who don't want memory enforcement must manually delete ~/.claude/enforce-memory.
- Consistent with the kit's opinionated compliance posture.
