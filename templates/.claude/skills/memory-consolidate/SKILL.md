---
name: memory-consolidate
description: "Consolidate duplicate/overlapping memory entries using Claude. Use when memory_search returns redundant results, after many phases, or for periodic memory maintenance."
---

# memory-consolidate — Claude-Powered Memory Consolidation

Identify and merge duplicate or overlapping memory entries without modifying the vendored memory_server Python code. Uses existing MCP tools (memory_search, memory_store, memory_forget).

## Procedure

### 1. Search for candidates

Run three searches to gather all managed entries:

- `memory_search` with tags `bridge-decision` — phase planning decisions
- `memory_search` with tags `harvest` — debrief corrections and preferences
- `memory_search` with category `custom` — all harness-managed entries

Deduplicate results by memory ID across the three queries.

### 2. Identify clusters

Group entries that share overlapping content or tags. Look for:

- Entries with identical tags on the same topic (e.g., two bridge-decisions about the same phase)
- Entries where one supersedes another (check `superseded_by` field — already-superseded entries are inactive)
- Entries with substantially overlapping content (same concept restated across sessions)

Present each cluster to the user with the entries and the proposed merge.

### 3. Merge (with confirmation)

For each cluster the user approves:

1. Write a single consolidated entry via `memory_store` — combine key facts, preserve specific details (dates, file paths, phase numbers), use the highest trust level from the cluster
2. Forget each original via `memory_forget` with `superseded_by` set to the new entry's ID
3. Report: `"Merged N entries → 1 (ID: <new_id>)"`

### Budget and safety

- **Cap:** 10 merges per invocation. If more clusters exist, report the count and stop.
- **Dry-run mode:** When invoked with `--dry-run`, list all identified clusters with proposed merges but do not modify any entries. Use this to preview before committing.
- **Never merge** entries with different categories or conflicting content. Flag these for manual review instead.
- **Fail-open:** If any MCP tool call fails, skip that cluster and continue. Report failures at the end.
