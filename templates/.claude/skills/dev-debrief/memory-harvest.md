# Memory Harvest (Step 4.7)

Extract conversation-level institutional knowledge and route to `memory_store` MCP calls. Runs during full debrief, after conversation analysis (Step 4) but before decision extraction (Step 5).

## What to Extract

Scan the conversation analysis output (Step 4) for knowledge that survives beyond this phase:

1. **User corrections** — when the user overrode an agent decision or restored prior state. Tag: `harvest-correction`.
2. **Preferences learned** — communication style, workflow expectations, tool choices revealed through interaction (not stated explicitly). Tag: `harvest-preference`.
3. **Failure lessons** — approaches that failed and why, dead ends explored. Tag: `harvest-lesson`.
4. **Non-obvious constraints** — project rules or boundaries discovered during implementation that aren't documented. Tag: `harvest-constraint`.

## What NOT to Extract

- **Phase decisions** — these go to wiki decision articles (Step 5). Do not duplicate.
- **Task progress** — this goes to tasks.md (Step 7). Do not duplicate.
- **Architecture facts** — these go to _ARCHITECTURE.md (Step 9). Do not duplicate.
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

Target ≤100 total entries in the memory store. Before storing, check current count via `memory_stats`. If `memory_stats` is unavailable, fall back to `memory_search(query="harvest-", limit=50)` and count results. If approaching the ceiling, prefer updating existing entries over creating new ones.

## Stale Entry Removal

If a new fact contradicts an existing memory entry, update the existing entry rather than creating a duplicate. If a prior correction is no longer relevant (code was rewritten, decision was reversed), note it for removal.

## Skip Conditions

- Quick debrief mode: skip entirely (insufficient conversation depth).
- No corrections, preferences, or lessons detected: skip. Emit: "Memory harvest: nothing to extract."
- MCP tools unavailable (subagent context): skip. Emit: "Memory harvest: skipped (no MCP access)."
