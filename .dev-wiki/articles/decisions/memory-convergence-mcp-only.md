---
title: "Memory convergence: MCP-only"
aliases: [memory-mcp-only, memory-convergence]
category: decisions
tags: [memory, mcp, session-start, convergence]
parents: [phase-10-memory-lifecycle-convergence]
created: 2026-05-19
updated: 2026-05-19
source: debrief
confidence: high
---

## Context

Memory access was split across two stores: MCP server (memory_store/memory_search tools) and .memory/MEMORY.md (file read by session-start.sh). This created a split-brain problem -- memory written via MCP was not visible at session start via the file path, and vice versa. The file-based path was legacy from pre-MCP design.

## Decision

Remove .memory/MEMORY.md read from session-start.sh. Memory access is MCP-only: memory_store to write, memory_search to read. Existing MEMORY.md files become inert legacy -- not deleted, just no longer read.

Chose MCP-only over alternatives: dual-read (perpetuates split-brain), file-only (loses MCP search capabilities), migration script (over-engineered for legacy files that may not exist).

## Consequences

- session-start.sh reads 2 sources (was 3): dev-wiki state and session state
- nana-soul.md Memory discipline updated: memory_search at session start for recall
- file-lifecycle.md memory entry rewritten: MCP-only, no file intermediary
- Existing .memory/MEMORY.md files in projects are harmless but ignored
- Future memory features build exclusively on MCP protocol
