# Spec: Phase 10 — Memory Lifecycle Convergence

## Objective

Eliminate the two-store memory problem by removing the stale `.memory/MEMORY.md` read from session-start.sh and making memory access MCP-only. One store (memory.db via MCP), one access path (memory_search/memory_store tools).

## Context

The kit has a split-brain memory problem: the agent writes to `memory_store` (MCP tool → SQLite `memory.db`), but session-start.sh reads `.memory/MEMORY.md` (a markdown file). Nothing connects them — no auto-export, no sync. The `memory_export` tool exists but nothing calls it automatically. Result: if a user follows file-lifecycle guidance and calls `memory_store`, session-start reads an empty/stale MEMORY.md and memories aren't loaded.

### Current state (for post-compaction self-containment)

`templates/.claude/hooks/session-start.sh` currently reads 3 sources (PROJECT_STATE.md was removed in Phase 9):
1. `.dev-wiki/_CURRENT_STATE.md` — dev-wiki lifecycle state
2. `.memory/MEMORY.md` — memory snapshot (THE PROBLEM — reads stale file)
3. `.claude/rules/py-session-state.md` — compaction anchor

`templates/.claude/rules/nana-soul.md` has a "Memory discipline" section (3 bullets) that tells the agent to use memory_store. It does not mention session-start memory loading.

`templates/.claude/rules/file-lifecycle.md` lists `memory_store (MCP tool)` as agent-updated and `.memory/MEMORY.md` as read by session-start hook — this is the inconsistency.

Instruction budget: 227/300. nana-soul.md is 51 lines. Adding 1 line brings it to 52.

## Scope

### In scope
- `templates/.claude/hooks/session-start.sh` — remove `.memory/MEMORY.md` read block
- `templates/.claude/rules/nana-soul.md` — add session-start memory_search guidance to Memory discipline
- `templates/.claude/rules/file-lifecycle.md` — update memory entry (remove .memory/MEMORY.md, clarify MCP-only)
- `templates/.github/instructions/nana.instructions.md` — sync to match soul
- `tests/test_templates.sh` — verify budget still holds

### Out of scope
- Changes to memory_server Python code
- Changes to memory_server MCP tools
- Removing .memory/MEMORY.md from existing projects (it's legacy, not harmful if present)
- Adding memory_search auto-invocation hooks (the soul convention is sufficient)

## Approach

Option B from the analysis: accept MEMORY.md as legacy, remove it from session-start, make memory access agent-driven via MCP tools.

1. Remove the `.memory/MEMORY.md` read block from session-start.sh (lines ~17-22). Update the header comment to reflect 2 sources instead of 3.
2. Add one line to nana-soul.md Memory discipline: "At session start, call `memory_search` with a broad query to load relevant prior decisions."
3. Update file-lifecycle.md: remove the `.memory/MEMORY.md` row from hooks section, update memory_store entry to clarify it's the sole memory access path.
4. Sync nana.instructions.md to match soul.
5. Run tests to verify budget still holds.

## Constraints (CRITICAL)

- **No new stores**: This phase REMOVES a read path. It does NOT add any new file or store. The MCP memory_store/memory_search tools are the single access path.
- **Legacy-safe**: Existing `.memory/MEMORY.md` files in user projects are NOT deleted. They become inert — nothing reads them. Users can remove them manually.
- **Budget**: nana-soul.md goes from 51 → 52 lines (one line added). Total budget stays ~228/300.
- **Session-start must still work without memory**: The removal is inside an `if [ -f ... ]` guard that already no-ops when the file is absent. Removing the block entirely is cleaner — session-start reads 2 sources, not 3.

## Deliverables

1. `templates/.claude/hooks/session-start.sh` (updated: MEMORY.md block removed)
2. `templates/.claude/rules/nana-soul.md` (updated: +1 line in Memory discipline)
3. `templates/.claude/rules/file-lifecycle.md` (updated: memory entry corrected)
4. `templates/.github/instructions/nana.instructions.md` (updated: synced to soul)
5. `tests/test_templates.sh` (verified: budget still holds)

## Exit Criteria (machine-checkable)

- [ ] `! grep -q 'MEMORY_FILE\|MEMORY.md' templates/.claude/hooks/session-start.sh`
- [ ] `grep -qi 'memory_search' templates/.claude/rules/nana-soul.md`
- [ ] `! grep -q 'MEMORY.md' templates/.claude/rules/file-lifecycle.md`
- [ ] `diff <(tail -n +5 templates/.github/instructions/nana.instructions.md) templates/.claude/rules/nana-soul.md`
- [ ] `bash tests/test_templates.sh`

## Checkpoints

- After session-start.sh edited: run `bash -n templates/.claude/hooks/session-start.sh` to verify syntax.
- After all edits: run full test suite before commit.

## Assumptions

- session-start.sh has the MEMORY.md block at lines ~17-22 (with `MEMORY_FILE=".memory/MEMORY.md"` pattern). If absent: skip removal, note in issues.
- nana-soul.md Memory discipline section exists at its current location. If missing: skip soul update, note in issues.
- The MCP memory_search tool is available in projects where memory_server is installed. If not installed: the soul guidance is advisory (agent skips if tool unavailable).
