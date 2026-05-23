---
title: "Worktree/parallel development won't-build"
aliases: [gap-43, worktree-parallel]
category: decisions
tags: [roadmap, worktree, parallel, won't-build]
parents: [phase-26-memory-harness-hardening]
created: 2026-05-23
updated: 2026-05-23
source: debrief
confidence: high
---

## Context

Gap 4.3 (worktree/parallel development) was the last remaining capability gap on the roadmap alongside 4.1 (language-agnostic core). The question: does nana-dev-kit need worktree isolation for parallel phase development?

## Decision

Closed as won't-build. Regular subagents already parallelize work within a session. Worktree isolation only defers merge conflicts to worktree-merge time without net benefit for a single-developer, phase-sequential workflow. The complexity cost (worktree setup, state sync, merge resolution) exceeds the parallelism gain.

Alternatives rejected:
- Build worktree support: complexity without measurable benefit for target workflow
- Partial worktree (read-only clones): still requires merge, doesn't solve the core problem

## Consequences

Roadmap gap 4.3 permanently closed. Only Gap 4.1 (language-agnostic core) remains OPEN. Simplifies the project scope -- no worktree state management code to maintain. Future multi-developer scenarios would need different tooling (branch-based, not worktree-based).
