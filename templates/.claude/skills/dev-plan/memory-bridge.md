# Memory Bridge (Step 8a-bis)

Auto-store key phase decisions to memory after decision articles are finalized (Step 8a). Runs inline in the orchestrator — Agent subagents cannot access MCP tools.

## Scope Boundary

This companion stores DECISIONS (approach choices, constraints, trade-offs) with `category="custom"`. The dev-debrief memory-harvest stores CORRECTIONS/PREFERENCES/LESSONS with their own categories. These are independent write paths — no overlap.

## Procedure

### 1. Budget Guard

Call `memory_stats`. If total active entries ≥ 80 (of 100 advisory ceiling): emit `"Memory bridge: budget guard triggered (N/100 entries). Skipping store."` and STOP. Do not store.

If `memory_stats` is unavailable (MCP error): fall back to `memory_search(query="bridge-decision", limit=50)` and count results. If fallback also fails: skip silently.

### 2. Select Key Decisions

From the decisions finalized in Step 8a, select 1-3 that are "key": constrains implementation choices OR would need recall in a future phase. Exclude routine choices (variable naming, file ordering, cosmetic formatting).

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

Dedup is handled by memory_store's built-in near-duplicate detection (exact matches reinforce, near matches warn). Do NOT implement manual search-then-update.

### 4. Fail-Open

If any memory_store call fails (MCP unavailable, timeout, ValueError): log `"Memory bridge: store failed for '<decision>'. Continuing."` and proceed. Memory bridge is additive — never block dev-plan flow.

### 5. Report

Emit: `"Memory bridge: stored N/M decisions to memory."` (where M is total decisions, N is successfully stored). If all skipped due to budget or failure, this line still appears with N=0.
