---
title: "Bridge runs inline in orchestrator, not subagent"
aliases: [memory-bridge-inline-orchestrator]
category: decisions
tags: [memory, bridge, orchestrator, subagent, mcp]
parents: [phase-19-memory-wiki-bridge]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: high
---

## Context

dev-plan Step 8a (decision articles) runs inside an Agent subagent (artifact-writer). The memory-wiki bridge needs to call MCP tools (memory_store, memory_stats). The question is where to place the bridge execution.

## Decision

Bridge runs inline in the dev-plan orchestrator after the artifact-writer subagent returns (between Steps 8a and 8b in orchestrator flow), not inside the artifact-writer subagent. This is because Agent subagents do not have MCP tool access.

Alternatives considered:
- Inside artifact-writer subagent: rejected because subagents cannot access MCP tools (memory_store/memory_stats)
- As a separate post-plan hook: rejected because it adds process ceremony for a 3-line integration

## Consequences

The companion file (memory-bridge.md) is read by the orchestrator, not the subagent. The pointer in SKILL.md must be placed after the artifact-writer returns. This means bridge execution happens after all file writes are complete, which is actually safer (no partial-write + memory-store inconsistency).
