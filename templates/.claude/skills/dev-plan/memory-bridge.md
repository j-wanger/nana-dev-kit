---
parent: dev-plan
referenced_at: "Step 15a-bis"
---

# Memory Bridge (Step 15a-bis)

Auto-store key phase decisions to memory after decision articles are finalized (Step 15a). Runs inline in the orchestrator — Agent subagents cannot access MCP tools.

## Scope Boundary

This companion stores DECISIONS (approach choices, constraints, trade-offs) with `category="custom"`. The dev-debrief memory-harvest stores CORRECTIONS/PREFERENCES/LESSONS with their own categories. These are independent write paths — no overlap.

## Procedure

### 1. Budget Guard

Call `memory_stats`. If total active entries ≥ 400 (of 500 advisory ceiling): emit `"Memory bridge: budget guard triggered (N/500 entries). Skipping store."` and STOP. Do not store.

If `memory_stats` is unavailable (MCP error): fall back to `memory_search(query="bridge-decision", limit=50)` and count results. If fallback also fails: emit `"⚠ Memory bridge: MCP memory server unreachable. Decisions will NOT be persisted to memory. Check MCP server status with install.sh --status."` and STOP (do not silently continue).

### 1.5. Auto-Supersede Check

For each decision to be stored (Step 2), search for existing entries that this decision replaces:

```
results = memory_search(query="bridge-decision <phase-slug>", limit=5)
```

Response schema: each result is `{"memory": {"id": "mem_xxx", "content": "...", "tags": [...]}, "score": N}`. Extract old entry ID via `result["memory"]["id"]`.

For each result tagged `bridge-decision` whose content conflicts with the new decision (same topic, different conclusion), mark it for supersession. **Max 1 supersession per new decision** — pick the highest-scoring conflicting match. If no conflicts found, proceed (no-op).

**MCP call budget:** 10 calls total per bridge run (searches + stores + forgets). If budget exhausted mid-run, log remaining decisions to stdout and skip their supersession.

### 2. Select Key Decisions

From the decisions finalized in Step 15a, select 1-3 that are "key": constrains implementation choices OR would need recall in a future phase. Exclude routine choices (variable naming, file ordering, cosmetic formatting).

### 3. Store Each Decision

For each selected decision, call `memory_store`:

```
memory_store(
  content: "Phase N decided: <decision summary>. Rationale: <why>. Constrains: <what>.",
  category: "custom",
  tags: ["bridge-decision", "<phase-slug>"],
  trust: "medium",
  source: "observed"
)
```

Response schema: `{"id": "mem_new", "action": "created|reinforced"}`. Capture `id` for supersession linking.

If Step 1.5 marked an old entry for supersession, call `memory_forget` immediately after storing:

```
memory_forget(memory_id=old_id, superseded_by=new_id)
```

This soft-deletes the old entry and links it to the replacement. The old entry remains in the database (active=False) for audit trail.

Dedup for non-superseded entries is handled by memory_store's built-in near-duplicate detection (exact matches reinforce, near matches warn).

### 4. Fail-Open

If any MCP call fails (memory_search, memory_store, memory_forget — MCP unavailable, timeout, ValueError): emit `"⚠ Memory bridge: <operation> failed for '<decision>'. MCP memory server may be down."` and continue with remaining decisions. At the end, if ANY call failed, emit: `"⚠ Memory bridge: N operations failed. Run install.sh --status to diagnose."`

### 5. Report

Emit: `"Memory bridge: stored N/M decisions, superseded K entries."` (where M is total decisions, N is successfully stored, K is superseded). If all skipped due to budget or failure, this line still appears with N=0, K=0.
