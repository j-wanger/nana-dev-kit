---
title: "Gate enforcement: checklist + log"
aliases: [gate-enforcement]
category: decisions
tags: [process, gates, enforcement, dev-plan, active-phase]
parents: [phase-10-memory-lifecycle-convergence]
created: 2026-05-19
updated: 2026-05-19
source: debrief
confidence: high
---

## Context

Phase 10 was executed without passing through the approval gates (Steps 7/7.5/7.6 of /dev-plan). The user caught the process violation post-hoc. The existing system had no mechanism to prevent or detect skipped gates -- enforcement relied entirely on agent memory of the protocol.

## Decision

Two-layer gate enforcement:

1. **Checkpoint (preventive):** `active-phase.md` gets a `## Gates` section with 5 mandatory checkpoints: spec reviewed, approach approved, plan reviewed, tasks approved, memory session-start search. Written by /dev-plan Step 8f.

2. **Audit log (detective):** `tasks.md` gets gate log HTML comments per phase (`<!-- gates: spec=N/10 approach=yes|SKIPPED plan-review=N/10|n/a tasks=yes|SKIPPED -->`) recording approval status. Enables post-hoc audit of whether gates were passed.

Chose checklist + log over alternatives: runtime guardrails (too complex, fragile), honor system (already failed), single-layer checkpoint (no detective mechanism).

## Consequences

- /dev-plan SKILL.md Step 8f must write Gates section to active-phase.md
- task-schema.md updated with Gate Log specification
- Post-hoc audit possible: debrief or user can grep for `SKIPPED` in gate logs
- Does not prevent violations (still relies on agent following protocol) but makes them visible and auditable
- Retroactive gate logs added for Phases 8-10 to establish baseline
