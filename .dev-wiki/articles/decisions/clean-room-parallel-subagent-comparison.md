---
title: "Clean-room parallel subagent comparison"
aliases: [parallel-subagent, clean-room-comparison]
category: decisions
tags: [eval, comparison, methodology, subagent]
parents: [phase-42-harness-effectiveness-validation]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

To measure harness effectiveness, we need a controlled comparison between "with harness" and "without harness" conditions. Sequential runs introduce learning effects (task familiarity confound), and separate Claude sessions add coordination overhead. Agent subagents naturally lack hooks, skills, and memory, making them a valid "no harness" baseline.

## Decision

Both baseline and context-injection conditions run as parallel Agent subagents to eliminate learning effects and ensure same-model same-time execution. Subagents naturally lack hooks/skills/memory, making them a valid "no harness" baseline. Alternatives considered: sequential runs (learning effect confound), two separate Claude sessions (coordination overhead).

## Consequences

- Parallel execution eliminates temporal confounds and learning effects
- Subagent isolation provides a natural clean-room baseline without manual harness removal
- Context injection can be controlled precisely by what files are placed in the repo
- Full harness condition (C) requires manual user execution since subagents cannot run hooks/skills
- Results for A vs B are immediately available; B vs C and A vs C require user participation
