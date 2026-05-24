---
title: "Skill-based memory consolidation"
aliases: [memory-consolidate-skill]
category: decisions
tags: [memory, skill, consolidation, vendored-code]
parents: [phase-29-v051-grade-push]
created: 2026-05-23
updated: 2026-05-23
source: implementation
confidence: high
---

## Context

The vendored memory_server includes a consolidator.py that depends on a Qwen sidecar (disabled by default). The v0.5.0 critique flagged the absence of memory consolidation as a gap. Modifying consolidator.py would create fork divergence from the upstream nanaclaw vendor.

## Decision

Create a Claude-powered skill (`/memory-consolidate`) instead of modifying vendored consolidator.py. The skill uses existing MCP tools (memory_search, memory_store, memory_forget) to cluster, merge, and prune entries. This fits the established skill architecture pattern and avoids any changes to vendored Python code.

Alternative rejected: modify consolidator.py to add a non-LLM fallback path. Rejected because it creates vendor fork divergence and couples consolidation to the memory_server codebase.

## Consequences

- No vendored Python changes required — vendor stays upstream-compatible
- Consolidation runs on-demand via `/memory-consolidate` slash command
- Depends on MCP tools being available (memory_search, memory_forget, memory_store)
- 10-merge cap per invocation prevents runaway consolidation
- Dry-run mode for safe preview before destructive merges
