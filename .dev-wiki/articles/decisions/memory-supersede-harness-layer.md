---
title: "Memory supersede at harness layer"
aliases: [memory-supersede, auto-supersede]
category: decisions
tags: [memory, bridge, harvest, supersede]
parents: [phase-26-memory-harness-hardening]
created: 2026-05-23
updated: 2026-05-23
source: debrief
confidence: high
---

## Context

Bridge decisions and harvest corrections accumulate without cleanup. memory_prune only targets trust='low' + strength=1, but bridge entries are trust='medium'/'high', so prune is dead code for them. Stale decisions from earlier phases persist indefinitely, polluting search results.

## Decision

Wire existing MCP tools (memory_forget with superseded_by) at the harness layer rather than modifying vendor code. Memory-bridge gets auto-supersede step: search existing bridge-decisions for same phase-slug, store new entry, memory_forget highest-scoring conflict with superseded_by. Memory-harvest gets supersede for corrections reversing prior corrections. Ceiling raised 100 to 500 for both. 10-call cap per bridge run, 1 supersede per decision max.

Alternatives rejected:
- Modify vendor code: breaks upstream compatibility
- Wire memory_prune: wrong trust level (targets low, entries are medium/high)
- Read-time dedup: pushes complexity to every consumer

## Consequences

Bridge and harvest entries stay bounded without vendor changes. Supersession chains provide audit trail. 10-call cap prevents runaway API usage. Consumers see current decisions without manual cleanup.
