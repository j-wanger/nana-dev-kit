---
title: "Health probe uses 3 layers: jq config, import check, sqlite3 count"
aliases: [health-probe-3-layer, 3-layer-health-probe]
category: decisions
tags: [session-start, health-probe, memory, jq, hooks]
parents: [phase-39-resilience-health-probes]
created: 2026-05-25
updated: 2026-05-25
source: plan
confidence: high
---

## Context

The session-start.sh MCP health probe needs to verify memory server availability without MCP tool access (bash hooks cannot call MCP tools directly). A single import check is insufficient — it doesn't distinguish between "server binary present but DB empty" and "fully operational." A full MCP stdio call is too complex and slow for a hook.

## Decision

Health probe uses 3 layers, each progressively deeper:

1. **jq config read** — parse settings.json for `.mcpServers.memory.command` and `.mcpServers.memory.cwd`. If absent → "not configured".
2. **$MCP_CMD import check** — `$MCP_CMD -c "import memory_server"`. If fails → "broken (import failed)".
3. **sqlite3 entry count** — count entries in the memory DB. Graceful fallback if sqlite3 unavailable or DB doesn't exist.

Output 3-state diagnostic: healthy (N entries) / broken (reason) / not configured.

Rejected alternatives:
- **Single import check** — insufficient granularity, can't report entry count or config absence.
- **Full MCP stdio call** — requires spawning server, parsing JSON-RPC response; too complex and slow for a session-start hook.

## Consequences

- Health probe gives actionable diagnostics (not just pass/fail).
- Requires jq (established fail-open guard) and optionally sqlite3 (graceful degradation if absent).
- Entry count provides signal for "server configured but never used" scenarios.
- Pattern reusable for other MCP server health probes if added later.
