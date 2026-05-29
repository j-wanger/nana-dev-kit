---
parent: dev-debrief
referenced_at: "Step 6"
---

# Memory Harvest (Step 6)

Extract conversation-level institutional knowledge and route to `memory_store` MCP calls. Runs during full debrief, after conversation analysis (Step 4) but before decision extraction (Step 7).

## What to Extract

Scan the conversation analysis output (Step 4) for knowledge that survives beyond this phase:

1. **User corrections** — when the user overrode an agent decision or restored prior state. Tag: `harvest-correction`.
2. **Preferences learned** — communication style, workflow expectations, tool choices revealed through interaction (not stated explicitly). Tag: `harvest-preference`.
3. **Failure lessons** — approaches that failed and why, dead ends explored. Tag: `harvest-lesson`.
4. **Non-obvious constraints** — project rules or boundaries discovered during implementation that aren't documented. Tag: `harvest-constraint`.

## What NOT to Extract

- **Phase decisions** — these go to wiki decision articles (Step 7). Do not duplicate.
- **Task progress** — this goes to tasks.md (Step 11). Do not duplicate.
- **Architecture facts** — these go to _ARCHITECTURE.md (Step 14). Do not duplicate.
- **Anything already in memory** — call `memory_search` with key terms before storing. Skip duplicates.

## Output Format

For each extracted item, call `memory_store` with flat params (matching memory-bridge.md conventions):

```
memory_store(
  content: "<one-sentence fact>",
  category: "custom",
  tags: ["<harvest-correction|harvest-preference|harvest-lesson|harvest-constraint>"],
  trust: "high",
  source: "observed"
)
```

Use `trust: "high"` for explicit user corrections. Use `trust: "medium"` for inferred preferences and lessons.

## Advisory Ceiling

Target ≤500 total entries in the memory store (500 advisory ceiling — SQLite/FTS5 handles thousands). Before storing, check current count via `memory_stats`. If `memory_stats` is unavailable, fall back to `memory_search(query="harvest-", limit=50)` and count results. If at or above 400 entries, prefer updating existing entries over creating new ones.

## Stale Entry Supersession

Before storing a correction, search for prior corrections on the same topic:

```
results = memory_search(query="harvest-correction <topic keywords>", limit=3)
```

For each result tagged with a `harvest-*` tag whose content the new entry reverses or replaces, call `memory_forget` to supersede it:

```
memory_forget(memory_id=old_result["memory"]["id"], superseded_by=new_id)
```

This soft-deletes the old entry (active=False) and links it to the replacement. The old entry remains in the database for audit trail. If `memory_forget` fails, emit `"⚠ Memory harvest: memory_forget failed for entry <id>. Stale entry not superseded."` and continue.

If a prior correction is no longer relevant (code was rewritten, decision was reversed) but no new entry replaces it, call `memory_forget(memory_id=old_id)` without superseded_by to deactivate it.

## Skip Conditions

- Quick debrief mode: skip entirely (insufficient conversation depth).
- No corrections, preferences, or lessons detected: skip. Emit: "Memory harvest: nothing to extract."
- MCP tools unavailable: emit `"⚠ Memory harvest: MCP memory server unreachable. Corrections and preferences will NOT be persisted. Run install.sh --status to diagnose."` Do NOT skip silently.
