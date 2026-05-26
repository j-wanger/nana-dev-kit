---
title: "Cooldown advisory placement: debrief SKILL.md after executor returns"
aliases: [cooldown-advisory, phase-cooldown]
category: decisions
tags: [debrief, cooldown, momentum, session, advisory]
parents: [phase-41-harness-hardening-process-safeguards]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

Multi-phase sessions accumulate context debt. Phases 36-40 were completed in a single session, with diminishing returns on later phases (more rework, slower convergence). No mechanism currently advises the developer to start a fresh session between phases.

## Decision

Place the cooldown advisory in debrief SKILL.md after the executor returns, outside the delivery-flow.md fallback path. The advisory:
1. Reads `$HOME/.claude/.session-start-ts` (falls back to "last 4 hours" if missing)
2. Counts `git log --since` commits matching "Phase N" pattern
3. Emits "Phase N committed. For best results, start a new session for Phase N+1." when >=2 phase commits found

Advisory only (no blocking behavior). Placement after executor ensures it doesn't interfere with the delivery report flow.

## Consequences

- Developers see a nudge to start fresh sessions after completing multiple phases
- Falls back gracefully when session timestamp is missing (4-hour window)
- Does not block or gate any workflow -- purely informational
- Depends on session-start.sh writing `.session-start-ts` (Task 2 in this phase)
