---
title: "install.sh stays minimal"
aliases: [minimal installer, no hooks in install]
category: decisions
tags: [install, hooks, architecture]
parents: [phase-01-foundation-and-packaging]
created: 2026-05-15
updated: 2026-05-15
source: plan
confidence: high
---

## Context

install.sh is the global one-time installer for the nana-dev-kit. The question arose whether it should also copy hook templates to ~/.claude/hooks/ alongside the py-init skill and nana-soul rule.

## Decision

install.sh only copies three things: py-init skill, nana-soul rule, and kit path marker. Hooks are NOT installed globally because they reference project-local paths and are per-project artifacts deployed by /py-init at scaffold time.

## Consequences

- Simpler installer with fewer failure modes
- Hooks remain project-scoped, avoiding global state pollution
- Users must run /py-init in each project to get hooks deployed
- No risk of stale global hooks pointing to wrong project paths
