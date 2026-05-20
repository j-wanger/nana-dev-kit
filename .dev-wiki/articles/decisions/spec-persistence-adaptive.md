---
title: "Spec persistence adaptive routing"
aliases: [adaptive spec routing, spec persistence strategy]
category: decisions
tags: [spec, persistence, dev-wiki, routing, split-brain-prevention]
parents: [phase-08-spec-skill]
created: 2026-05-19
updated: 2026-05-19
source: debrief
confidence: high
---

## Context

The /spec skill needs to persist specs somewhere, but projects with dev-wiki already have phase articles that serve as contracts via /dev-plan. Persisting specs to both specs/ and phase articles creates split-brain: two contracts for one work item, with no single source of truth.

## Decision

Adaptive routing: if dev-wiki + active phase exists, suggest /dev-plan (the phase article IS the spec); if no dev-wiki, persist to specs/<slug>.md as a standalone contract. Two-critic validated this prevents split-brain while keeping /spec portable for non-dev-wiki projects.

## Consequences

- No split-brain: one contract per work item regardless of project setup
- /spec remains portable -- works in projects without dev-wiki
- /dev-plan and /spec share vocabulary (Constraints, Checkpoints, Assumptions) via phase template backport
- specs/ directory at project root serves standalone projects; exemplar spec (phase-08-spec-skill.md) provides format reference
