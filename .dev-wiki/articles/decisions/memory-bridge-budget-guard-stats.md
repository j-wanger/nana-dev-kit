---
title: "Use memory_stats for budget guard"
aliases: [memory-bridge-budget-guard-stats]
category: decisions
tags: [memory, bridge, budget, mcp]
parents: [phase-19-memory-wiki-bridge]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

The memory-wiki bridge needs a budget guard to prevent unbounded memory growth. Before storing entries, it checks total active count against a threshold (80). The question is how to query the count.

## Decision

Use the `memory_stats` MCP tool, which returns `by_category` counts and total active count. This is a purpose-built introspection endpoint, cheaper than search and semantically correct.

Alternatives considered:
- `memory_search` with empty query: rejected because FTS sanitization strips empty queries, returning zero results regardless of actual count
- `memory_search` with broad keyword (e.g., "*"): rejected because FTS keyword matching is fragile and may not match all entries
- Direct `sqlite3` query on memory.db: rejected because it breaks the MCP abstraction layer

## Consequences

Budget check depends on memory_stats tool availability. If memory_stats is unavailable (older memory_server version), the fallback is `memory_search(query="bridge-decision", limit=50)` and counting results. The fallback undercounts non-bridge entries but still prevents runaway growth for bridge-originated entries.
