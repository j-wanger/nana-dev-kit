---
title: "Commit .dev-wiki/ in initial commit"
aliases: [dev-wiki in repo, initial commit scope]
category: decisions
tags: [git, dev-wiki, project-structure]
parents: [phase-01-foundation-and-packaging]
created: 2026-05-15
updated: 2026-05-15
source: plan
confidence: high
---

## Context

The initial commit scope needed clarification: should .dev-wiki/ be committed as part of the project, and should .claude/settings.local.json be excluded?

## Decision

.dev-wiki/ is committed as part of the initial project structure because it is integral to project lifecycle management. .claude/settings.local.json is excluded via .gitignore because it contains user-specific configuration.

## Consequences

- Project lifecycle state is version-controlled and shareable
- User-specific settings remain local and private
- .gitignore must explicitly exclude settings.local.json
