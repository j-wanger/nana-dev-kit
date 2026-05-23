# Spec: Memory-Wiki Bridge

## Objective

Bridge memory (MCP memory_store/memory_search) and wiki (markdown articles) so that decisions from dev-plan and spec auto-persist to memory, and wiki-query includes memory results when answering questions.

## Context

nana-dev-kit has two parallel knowledge stores that don't cross-reference. The MCP memory server (SQLite, FTS5+vector, 100-entry advisory ceiling, categories: fact/preference/correction/entity/custom) holds corrections and preferences (written by memory-harvest in debrief). The knowledge wiki (markdown articles) holds domain knowledge and decisions (written by dev-plan, spec). Currently: dev-plan creates decision articles but doesn't persist summaries to memory for cross-project recall; wiki-query searches wiki articles but ignores potentially relevant memory entries. This phase closes Gap 1.3 (dev-plan → memory), Gap 3.3 (spec → memory), and starts Gap 4.4 (wiki-query ← memory read path).

## Scope

### In scope
- dev-plan: auto-store key phase decisions to memory after Step 8a (companion file, established pattern)
- spec: auto-store spec objective + key constraints to memory after Step 6 persist (inline, ample headroom)
- wiki-query: add memory_search to Step 1 context gathering, include results in analyst context
- Fail-open on all paths: memory unavailable = silent skip, no degradation of existing behavior
- Tests for all three integration points

### Out of scope
- Full bidirectional sync (memory entries auto-creating wiki articles)
- Changes to memory_server code or MCP protocol
- Changes to memory-harvest in debrief (existing; pre-existing category bugs in its companion are a separate fix)
- wiki-index integration (bridge operates at wiki-query orchestration level, not index level)
- Memory consolidation/compaction automation
- Stale memory detection or automatic cleanup
- Cross-project memory sharing
- install.sh changes (cp -r auto-distributes new files in existing skill dirs)

## Approach

Three independent one-way channels, each fail-open:

**Channel 1 — dev-plan → memory (write):** New companion file `memory-bridge.md` in dev-plan skill dir. After Step 8a (decision articles finalized), summarize 1-3 key decisions into memory entries. A decision is "key" if it constrains implementation choices or would need to be recalled in a future phase; exclude routine choices (variable naming, file ordering). Each entry: `category="custom"`, `tags=["bridge-decision", "<phase-slug>"]`, `trust="medium"`. Content format: single paragraph — `"Phase N decided: <decision>. Rationale: <why>. Constrains: <what>."` Dedup relies on memory_store's built-in near-duplicate detection (exact matches reinforce, near matches warn). dev-plan SKILL.md gets a 2-3 line pointer after Step 8a. Budget guard: call `memory_stats`, check total active count; if ≥80, warn and skip store.

**Channel 2 — spec → memory (write):** After Step 6 (persist to specs/), store one memory entry: spec objective + top 2-3 constraints. Content format: `"Spec <slug>: <objective>. Key constraints: <c1>; <c2>; <c3>."` `category="custom"`, `tags=["bridge-decision", "<spec-slug>"]`, `trust="medium"`. 3-5 lines inline in spec SKILL.md (at ~124 lines, well under 350 ceiling).

**Channel 3 — wiki-query → memory (read):** In Step 1 (gather context), after wiki search/keyword scoring, call `memory_search` with the user's question (limit=5). Include results in the analyst's Runtime Context as a `### Memory Results` section, clearly separated from wiki sources. If MCP unavailable or zero results, silent skip — no "0 results" clutter.

**Single-writer principle:** Wiki articles are canonical for decisions. Memory gets a derived summary for cross-project recall and faster retrieval. No reverse sync.

## Constraints (CRITICAL)

- dev-plan SKILL.md must stay ≤350 lines: bridge logic lives in companion file, not inline. Prevents exceeding complex-orchestration ceiling.
- All memory entries use `category="custom"` with `tags=["bridge-decision"]`: the Category enum (fact/preference/correction/entity/custom) has no "decision" value. Using "custom" + tag avoids modifying vendored memory_server code while enabling tag-based retrieval via FTS (tags are FTS-indexed).
- Budget guard uses `memory_stats` tool (returns `by_category` counts and total active count), NOT `memory_search` with empty query (empty queries return zero results after FTS sanitization). If total active entries ≥80, warn and skip store.
- All three channels are fail-open: if memory_search or memory_store raises an error (MCP unavailable, timeout, ValueError), the calling skill continues with existing behavior. Memory bridge is additive, never blocking.
- Dedup relies on memory_store's built-in near-duplicate detection: exact matches are reinforced (not duplicated), near matches emit a warning. The caller does NOT implement manual search-then-update logic (there is no update API).
- wiki-query presents memory results in a separate `### Memory Results` section in analyst context, not merged into wiki article synthesis: prevents terse memory entries from degrading prose quality in the writer's output.

## Deliverables

1. `templates/.claude/skills/dev-plan/memory-bridge.md` — companion file (~30-40 lines) for auto-storing decisions to memory
2. Modified `templates/.claude/skills/dev-plan/SKILL.md` — 2-3 line pointer to companion after Step 8a
3. Modified `templates/.claude/skills/spec/SKILL.md` — 3-5 line memory-store block after Step 6
4. Modified `templates/.claude/skills/wiki-query/SKILL.md` — memory_search integration in Step 1
5. Updated `tests/test_templates.sh` — cross-reference assertions for all three integration points

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/skills/dev-plan/memory-bridge.md`
- [ ] `grep -q 'memory-bridge\.md' templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]`
- [ ] `grep -q 'memory_store' templates/.claude/skills/spec/SKILL.md`
- [ ] `grep -q 'memory_search\|Memory Results' templates/.claude/skills/wiki-query/SKILL.md`
- [ ] `grep -q 'memory.bridge\|memory-bridge' tests/test_templates.sh`
- [ ] `make test`

## Checkpoints

- After Channel 1 (dev-plan companion) is drafted: report line count of companion and SKILL.md delta
- After all three channels are implemented (before tests): report total lines added across all SKILL.md files, verify no ceiling breaches

## Assumptions

- memory_store and memory_search MCP tools are available during dev-plan, spec, and wiki-query execution. If false: all three channels fail-open silently — bridge is a no-op, existing behavior is unaffected.
- memory_stats tool returns a dict with `total_active` count and `by_category` breakdown. If false: fall back to `memory_search(query="bridge-decision", limit=50)` and count results for budget check.
- wiki-query SKILL.md has sufficient headroom for inline memory_search integration (~10-15 lines). If false: extract to companion file (same pattern as dev-plan).
- Total active memory entries in typical projects stay under 80 (the budget guard threshold). If false: implement consolidation (merge oldest custom entries into summary entries) in a future phase rather than raising the threshold.
- memory-harvest in debrief uses categories correction/preference (valid enum values). Its companion file also references "lesson" and "constraint" which are not valid Category enum values — this is a pre-existing bug outside this spec's scope. If memory-harvest failures surface during testing: document but do not fix (separate scope).
