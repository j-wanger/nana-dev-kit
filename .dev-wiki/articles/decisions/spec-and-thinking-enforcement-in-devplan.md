---
title: "Spec and thinking enforcement in dev-plan"
aliases: [spec-existence-check, thinking-protocol-t0]
category: decisions
tags: [process, spec, thinking-protocol, dev-plan, enforcement]
parents: [phase-12-soul-enhancement-memory-harvest]
created: 2026-05-20
updated: 2026-05-20
source: plan
confidence: medium
---

## Context

Two process gaps found during Phase 12 planning: (1) Spec routing is one-directional -- /spec routes TO dev-plan but dev-plan doesn't check FOR spec. Standard ceremony phases can bypass /spec entirely. (2) The soul's thinking protocol ("challenge the frame, read subtext, delay commitment") is overridden by dev-plan's procedural flow -- skill procedures override soul behavioral guidance.

## Decision

Fix both gaps inline within Phase 12 rather than deferring to a separate phase. Step 0.6 spec-existence check (standard ceremony only, ~5 lines): checks specs/<phase-slug>.md or phase article "## Formal Spec" section, STOP if neither found. Step 6 thinking-protocol T0 (~5 lines): inline prompt to challenge frame, read subtext, delay commitment before approach formulation. Both fixes are minimal and fit naturally in Phase 12's process-improvement scope.

Alternative rejected: separate Phase 13 (both fixes are ~5 lines each, not enough scope for a standalone phase).

## Consequences

Standard ceremony phases now require a spec before planning can proceed. Thinking protocol gets explicit invocation during the highest-impact planning step. Lite ceremony remains spec-optional by design.
