---
title: "Memory harvest in debrief"
aliases: [memory-harvest, memory-keeper-in-debrief]
category: decisions
tags: [memory, debrief, automation, mcp, memory-store]
parents: [phase-12-soul-enhancement-memory-harvest]
created: 2026-05-20
updated: 2026-05-20
source: plan
confidence: high
---

## Context

Institutional knowledge (corrections, preferences, failure lessons) is captured manually via ad-hoc memory_store calls. Dev-debrief already extracts this information (Step 4) but only routes it to wiki articles and tasks.md. A memory-harvest step would automate what's currently manual.

## Decision

Integrate memory-keeper into dev-debrief as a companion file rather than a standalone skill. Dev-debrief Step 4 already extracts the information -- memory-harvest adds a new routing destination (memory_store) alongside existing wiki routing (Step 5). Gets automatic invocation for free, no install.sh changes, no new gate enforcement needed.

Alternative rejected: standalone skill (yet another thing to remember to invoke, contradicts Phase 11 lesson about process adherence). Alternative rejected: hook trigger (premature automation for prototype).

## Consequences

Memory extraction happens automatically during every debrief without additional user action. Companion file keeps SKILL.md additions minimal (~3 lines). Future: if memory-harvest needs standalone invocation, extract to separate skill at that point.
