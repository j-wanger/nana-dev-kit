---
title: "pre-compact.sh belongs in dev-wiki module group"
aliases: [pre-compact-dev-wiki-module]
category: decisions
tags: [hooks, install, modules]
parents: [phase-23-bug-fixes-readme]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

pre-compact.sh reads `.dev-wiki/_CURRENT_STATE.md`, `.dev-wiki/tasks.md`, and `.claude/rules/active-phase.md` -- all dev-wiki lifecycle files. It was created in Phase 15 but never registered in `settings.json` hooks or added to install.sh's dev-wiki module group. The hook is orphaned: present in templates/ but not installed or activated.

## Decision

Place pre-compact.sh in the dev-wiki module group (alongside enforce-spec.sh, enforce-loop.sh, detect-loop.sh). Users running `--core-only` should NOT receive it because it depends on .dev-wiki/ files that core-only installs do not scaffold. The hook registration uses PreCompact event type in settings.json with the standard nested format.

Alternative considered: placing in core module. Rejected because core is language/workflow-agnostic and pre-compact.sh is meaningless without a dev-wiki.

## Consequences

- `install.sh --all` and default installs copy pre-compact.sh to `~/.claude/hooks/` and register PreCompact in settings.json
- `install.sh --core-only` does NOT install pre-compact.sh
- PreCompact hook fires on context compaction, injecting dev-wiki state summary
