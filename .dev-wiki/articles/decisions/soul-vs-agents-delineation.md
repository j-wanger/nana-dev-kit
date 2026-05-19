---
title: "Soul vs AGENTS.md delineation"
aliases: [soul agents boundary, cognitive vs operational]
category: decisions
tags: [soul, agents, delineation, identity, instructions]
parents: [phase-07-soul-and-instructions-enhancement]
created: 2026-05-19
updated: 2026-05-19
source: debrief
confidence: high
---

## Context

Phase 7 required restructuring nana-soul.md and AGENTS.md. The boundary between "soul" (cognitive identity) and "AGENTS.md" (operational contract) was ambiguous -- some rules could belong in either file. Needed a crisp delineation principle to guide current restructuring and future additions.

## Decision

Soul = cognitive identity ("how does this agent think and communicate?"). AGENTS.md = operational contract ("what does this project require to be correct?"). Litmus test: "Would this rule apply in a Rust project with no Python?" If yes, it belongs in soul. If no, it belongs in AGENTS.md.

Three-critic multi-angle review (context engineering, harness design, UX) produced unanimous convergence on this split. Before acting, memory discipline, work habits, and code quality lens are soul. Pre-commit sequence, testing conventions, and project toolchain are AGENTS.md.

## Consequences

- Clear decision framework for future instruction additions (soul vs AGENTS.md)
- Soul stays language/project agnostic -- portable across all projects
- AGENTS.md remains project-specific -- can vary per codebase
- Personal profile (nana-personal.md) extracted as a third tier: user-specific, not project-specific or universal
- Instruction budget tracking (191/300 lines) provides guardrail against unconstrained growth
