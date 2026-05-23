---
title: "Use category=custom with bridge-decision tag"
aliases: [memory-bridge-category-custom]
category: decisions
tags: [memory, bridge, category, mcp]
parents: [phase-19-memory-wiki-bridge]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

The memory-wiki bridge needs to store phase decisions in memory_store. The Category enum in vendored memory_server supports only: fact, preference, correction, entity, custom. There is no "decision" category.

## Decision

Use `category="custom"` with `tags=["bridge-decision"]` for all bridge-stored entries. Tags are FTS-indexed, enabling tag-based retrieval via `memory_search`. This avoids modifying vendored memory_server code while preserving semantic filtering capability.

Alternatives considered:
- Adding "decision" to Category enum: rejected because it modifies vendored code (maintenance burden, upgrade friction)
- Using category="fact": rejected because it's semantically imprecise (decisions carry rationale + constraints, facts don't)

## Consequences

All bridge entries share a single tag for retrieval. Future phases can filter bridge entries via FTS search on "bridge-decision". If the memory_server vendor adds a decision category upstream, migration is a single tag-to-category swap.
