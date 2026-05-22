---
title: sqlite3 for memory nudge (not MCP)
status: accepted
confidence: medium
date: 2026-05-22
source: plan
tags: [memory, sqlite, session-start, hooks]
parents: [phase-17-harden]
---

# sqlite3 for memory nudge (not MCP)

## Context

session-start.sh needs to check memory entry count to nudge users toward memory consolidation when the count is high. Shell hooks cannot call MCP tools (MCP is agent-only protocol). Need an alternative path to query memory state.

## Decision

Query memory.db directly via sqlite3 CLI with a 2-second timeout. If sqlite3 is unavailable or the database file does not exist, skip the nudge silently. A cooldown mechanism prevents repeated nudges within the same day.

## Rationale

- **Constraint:** Shell hooks have no MCP access. The only path to memory state is direct DB query.
- **sqlite3 availability:** Installed by default on macOS and most Linux distros. Reasonable to depend on for an advisory (non-blocking) feature.
- **Timeout:** 2-second timeout prevents session-start from stalling if the database is locked or corrupted.
- **Fallback:** Skip silently — the nudge is advisory, so absence is harmless.
- **Alternative rejected:** Counting files in a directory (memory_server uses sqlite, not file-per-entry). Parsing MCP server logs (fragile, non-standard).

## Consequences

- Depends on knowing memory.db path (~/.claude/memory_server/memory.db) — ties to vendored memory_server layout
- If memory_server changes its storage schema, the query may break silently (acceptable: advisory feature)
- sqlite3 dependency is soft (skip if absent), not hard

## Related

- [[memory-convergence-mcp-only]] — MCP is the canonical access path for agents; this is a shell-layer exception for advisory hooks
- [[vendor-memory-server]] — memory.db path derives from vendored server layout
