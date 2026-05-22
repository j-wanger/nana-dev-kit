# Spec: Harden (Phase 17)

## Objective

Add three hardening capabilities: (1) loop/drift detection that warns when an agent repeats failed approaches, (2) memory consolidation nudge at SessionStart when the store exceeds a threshold, and (3) working-knowledge auto-pruning that removes stale entries based on access count and age.

## Context

Phase 16 shipped enforcement hooks (spec-enforcement + deliverable check, 107 tests). The kit now has preventive enforcement but lacks detective/hygiene capabilities. These are Tier 3 gaps from the engineering gap analysis: loop detection (Gap 2.3), memory consolidation (Gap 3.2), working-knowledge lifecycle (Gap 3.4). The memory server is MCP-based (memory_store/memory_search/memory_stats). Working-knowledge.md has a 100-entry cap enforced by dev-debrief but no staleness pruning — the `[uses: N]` counter only increments when dev-plan or wiki-query explicitly reference an entry.

## Scope

### In scope

- PostToolUse hook for loop/drift detection: track recent Bash commands, warn on repeated identical failures
- SessionStart enhancement: memory_stats threshold check with cooldown, working-knowledge pruning
- Working-knowledge pruning logic: age + access count, minimum age floor, pinned entries, staged to `.stale-queue`
- Tests for all three capabilities
- Update session-start.sh and install.sh

### Out of scope

- Subagent loop detection (can't observe subagent internals from hooks)
- Escalating loop severity (block on persistence) — advisory only for v1
- Memory ↔ wiki bidirectional bridge (Gap 4.4)
- Language-neutrality audit (Gap 4.1)
- Changes to memory_server itself

## Approach

**Three independent capabilities, minimal coupling:**

1. **`detect-loop.sh` (PostToolUse on Bash):** Track recent Bash commands and exit codes in a session-local file (`.claude/.loop-state`). When 3+ Bash invocations in a row have the same command string AND same non-zero exit code (any intervening Bash call with a different command string resets the counter), emit advisory: "Loop detected: same command failed N times. Consider a different approach." No TDD awareness in v1 — the advisory is non-blocking, so a false positive during RED phase is a harmless warning.

2. **SessionStart memory nudge:** Add to session-start.sh: if MCP server is reachable (2s timeout), call `memory_stats` and check total_active count. If >500, emit "[memory] N active entries. Consider running memory_consolidate." Cooldown: write timestamp to `~/.claude/.memory-nudge-ts`, suppress for 7 days.

3. **Working-knowledge pruning in session-start.sh:** On SessionStart, read `working-knowledge.md`. For entries with `[uses: 1]` AND activated >30 days ago AND not marked `[pinned]`: move to `.dev-wiki/.stale-queue` (append with date). Limit: prune at most 5 entries per session to avoid large context shifts. Entries with `[uses: 2+]` or `[pinned]` are exempt.

## Constraints (CRITICAL)

- Loop detection is advisory only (stdout, not exit 2). Prevents: blocking legitimate TDD RED cycles or multi-attempt debugging. Guard: the hook emits warnings, never blocks.
- Loop detection requires 3+ Bash invocations in a row where command string AND exit code are identical, with any different-command invocation resetting the counter. Prevents: false positives from different approaches. Guard: compare full command text; reset counter on any command string mismatch.
- Memory nudge has 2s MCP timeout and 7-day cooldown. Prevents: SessionStart latency and persistent noise. Guard: `timeout 2` on the MCP call; timestamp comparison before emitting.
- Working-knowledge pruning exempts `[pinned]` entries. Prevents: deleting manually-added safety invariants or architectural decisions. Guard: grep for `[pinned]` marker before considering an entry for pruning.
- Working-knowledge pruning has 30-day minimum age floor. Prevents: pruning entries added in the current or recent phase. Guard: parse `activated: YYYY-MM-DD` and compare against today.
- Pruning moves to `.stale-queue` (append, not overwrite) rather than deleting. Prevents: irreversible data loss. Guard: entries can be recovered by reading .stale-queue.
- Maximum 5 entries pruned per SessionStart. Prevents: large context shifts that confuse the agent. Guard: counter in pruning loop.
- `detect-loop.sh` must execute in <50ms. Prevents: latency on every Bash call. Guard: single file read + append, no Python, no subprocess. Use pure bash.
- Session-local loop state (`.claude/.loop-state`) is cleared on SessionStart AND detect-loop.sh self-heals with `rm -f` if the file is malformed. Prevents: cross-session false positives and stale state from crashed sessions.

## Deliverables

1. `templates/.claude/hooks/detect-loop.sh` — PostToolUse hook for Bash (~40 lines, pure bash)
2. Updated `templates/.claude/hooks/session-start.sh` — memory nudge + working-knowledge pruning + loop state clear
3. Updated `install.sh` — detect-loop.sh alongside enforcement hooks in dev-wiki module, hook registration in settings.json
4. New `tests/test_harden.sh` — loop detection tests (identical failures, different failures, below threshold), memory nudge (cooldown, threshold), pruning (age, pinned, stale-queue output)
5. Updated `Makefile` — test_harden.sh target

## Exit Criteria (machine-checkable)

- [ ] `test -f templates/.claude/hooks/detect-loop.sh && bash -n templates/.claude/hooks/detect-loop.sh`
- [ ] `grep -q 'memory_stats\|memory.*nudge\|consolidat' templates/.claude/hooks/session-start.sh`
- [ ] `grep -q 'stale\|prune\|pinned' templates/.claude/hooks/session-start.sh`
- [ ] `bash tests/test_harden.sh`
- [ ] `grep -q 'test_harden' Makefile`
- [ ] `make test`

## Checkpoints

- After detect-loop.sh: test 3 scenarios (below threshold, at threshold, TDD exemption) before integration
- After session-start.sh changes: verify existing tests still pass before adding new ones
- If session-start.sh exceeds 100 lines: consider extracting pruning to a separate helper script

## Assumptions

- PostToolUse hooks receive tool input JSON on stdin with the command field for Bash tools. If false: adapt JSON parsing approach.
- `memory_stats` MCP tool returns a JSON response with `total_active` field. If false: skip memory nudge, document degradation.
- Working-knowledge entries follow the format `- [uses: N] description\n  source: ... | activated: YYYY-MM-DD`. If false: adjust the grep/sed parsing patterns.
- The `.claude/.loop-state` file can be written/read by hooks within the same session. If false: use /tmp with a session-unique name.
- `date -d` or `date -j -f` is available for date arithmetic. If false (portability): use Python one-liner for date comparison.
