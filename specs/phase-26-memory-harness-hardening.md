# Spec: Phase 26 — Memory & Harness Hardening

## Objective

Wire existing memory MCP tools (memory_forget with superseded_by) into harness companions for automatic decision supersession, raise the advisory entry ceiling, add crash recovery detection to session-start, and validate cross-skill reference integrity in the test suite.

## Context

A multi-angle critique of nana-dev-kit v0.4.0 identified 8 unaddressed findings. This phase targets the memory and harness clusters. The vendored memory server already has `memory_forget(memory_id, superseded_by)`, `memory_contradict(id_a, id_b)`, and `memory_prune(dry_run, max_age_days, min_access_count)` tools — but the harness never calls them. Decisions accumulate without supersession, and a 100-entry advisory ceiling caps learning at ~10 phases. The harness has 198 cross-skill path references with no validation, and session-start doesn't detect interrupted sessions (commits without debrief).

Key finding: `memory_prune` only targets entries with `trust='low' AND strength=1`. All bridge entries use `trust='medium'` and harvest entries use `trust='medium'/'high'` — so memory_prune cannot prune any harness-created entries. Auto-supersede via `memory_forget` is the effective mechanism for managing growth.

## Scope

### In scope
- `memory-bridge.md` — raise ceiling from 100 to 500, add auto-supersede logic (search for existing bridge-decision entries with same phase-slug, call memory_forget(old_id, superseded_by=new_id) for conflicting entries)
- `memory-harvest.md` — raise ceiling from 100 to 500, add supersede logic for corrections that reverse prior corrections
- `session-start.sh` — crash recovery block: dual-condition detection (commits newer than _CURRENT_STATE.md mtime AND no debrief commit covering the gap), advisory output only
- `tests/test_templates.sh` — cross-skill reference validation function (grep all `~/.claude/skills/` paths from skill files, verify target exists in templates/)
- `README.md` — Windows setup note (one-liner: WSL2 or Git for Windows required for hooks)

### Out of scope
- Vendor code changes (memory_server/ is vendored from nanaclaw, prior decision)
- Wiring `memory_prune` (targets trust='low' entries; bridge/harvest entries are trust='medium'/'high' — would be dead code)
- Wiring `memory_contradict` (advisory-only marking without downstream consumer — no current skill reads contradiction metadata)
- Unified relevance ranking across memory + wiki stores (different architecture)
- Harness observability (/dev-status skill — separate phase if pursued)
- Fixing pre-existing broken cross-skill references (if any are found, fix as part of this phase, but don't build a baseline mechanism)

## Approach

**Memory ceiling + auto-supersede:** Raise both companion ceilings from 100 to 500 (SQLite/FTS5 handles thousands). In memory-bridge, for each decision (1-3 per run): (1) `memory_search(query="bridge-decision <phase-slug>", limit=5)` — results are `[{"memory": {"id": "mem_xxx", "content": "...", "tags": [...]}, "score": N}, ...]`, extract old ID via `result["memory"]["id"]`, (2) `memory_store(...)` — returns `{"id": "mem_new", "action": "created"}`, (3) for each conflicting old entry (max 1 per decision): `memory_forget(old_id, superseded_by=new_id)`. Cap at 10 MCP calls total per bridge run. In memory-harvest, before storing a correction: search for prior corrections on the same topic, supersede if the new one reverses the old.

**Crash recovery in session-start:** Get `_CURRENT_STATE.md` mtime via `stat -f %m` (macOS) with `stat -c %Y` (Linux) fallback. Get latest commit timestamp via `git log -1 --format=%ct`. If commit_time > state_mtime AND `git log --since="@$STATE_MTIME" --oneline --grep="Debrief" | wc -l` is 0, emit: `[recovery] Commits detected since last state update. Consider /dev-check or /dev-debrief.` Requires both conditions to avoid false-positives on normal mid-phase work.

**Cross-skill reference validation:** New test function in test_templates.sh. Grep all `~/.claude/skills/` path references from templates/.claude/skills/, map to templates/ paths, check file existence. Output file:line and missing target for each broken reference.

**README Windows note:** One line in Requirements section.

## Constraints (CRITICAL)

- **No vendor code changes.** All improvements work through existing MCP tool API. Prevents: breaking upstream compatibility, complicating future memory_server updates.
- **Auto-supersede cap: max 10 MCP calls total per bridge run.** Covers 3 decisions x (1 search + 1 store + 1 forget) = 9 calls. If budget exhausted mid-run, log remaining decisions to stdout and skip their supersession. Prevents: unbounded latency in dev-plan ceremony.
- **Per-decision supersede ceiling: max 1 old entry superseded per new decision.** If search returns multiple conflicting entries, supersede only the highest-scoring match. Prevents: accidental knowledge loss if the search query is too broad.
- **Crash recovery is advisory only (stdout, exit 0).** Never block session start. Prevents: boot loop where crash detection itself prevents recovery.
- **Crash recovery requires dual condition.** Commits-since-mtime AND no-debrief-commit. Single condition (just "commits exist") fires on normal workflow. Prevents: false-positive recovery suggestions on every session (adversarial finding #5).
- **Cross-skill reference test must output file:line and missing target.** Not just a count. Prevents: test being a perpetual red flag with no actionable info (adversarial finding #4).
- **Session-start crash recovery must handle no-.dev-wiki gracefully.** Non-dev-wiki projects must not trigger recovery logic. Prevents: errors in non-lifecycle projects (adversarial finding #8).
- **Fail-open for all memory MCP calls.** If memory_search/memory_forget/memory_stats fails, log and continue. Prevents: blocking dev-plan/dev-debrief flow.

## Deliverables

1. Modified `templates/.claude/skills/dev-plan/memory-bridge.md` — ceiling 500, auto-supersede logic (~15 lines added)
2. Modified `templates/.claude/skills/dev-debrief/memory-harvest.md` — ceiling 500, supersede logic for corrections (~10 lines added)
3. Modified `templates/.claude/hooks/session-start.sh` — crash recovery block (~12 lines added)
4. Modified `tests/test_templates.sh` — cross-skill reference validation function (~20 lines)
5. Modified `README.md` — Windows note (~1 line)
6. 1-2 eval scenarios for crash recovery in session-start

## Exit Criteria (machine-checkable)

- [ ] `grep -q 'ceiling.*500\|500.*ceiling' templates/.claude/skills/dev-plan/memory-bridge.md`
- [ ] `grep -q 'memory_forget.*superseded_by\|superseded_by.*memory_forget' templates/.claude/skills/dev-plan/memory-bridge.md`
- [ ] `grep -q 'ceiling.*500\|500.*ceiling' templates/.claude/skills/dev-debrief/memory-harvest.md`
- [ ] `grep -q 'memory_forget' templates/.claude/skills/dev-debrief/memory-harvest.md`
- [ ] `grep -q '\[recovery\]' templates/.claude/hooks/session-start.sh`
- [ ] `grep -q 'Debrief' templates/.claude/hooks/session-start.sh`
- [ ] `grep -q 'cross.skill.*ref\|skill.*reference' tests/test_templates.sh`
- [ ] `grep -qi 'WSL\|windows' README.md`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints

- After modifying memory-bridge.md: review that the auto-supersede logic handles the case where memory_search returns 0 results (no-op path) and the case where it returns stale entries to supersede
- After session-start crash recovery: test with a mock scenario where commits are newer than _CURRENT_STATE.md and no debrief commit exists
- After cross-skill reference test: run it and fix any pre-existing broken references before declaring the test complete
- If memory_forget or memory_search MCP calls have unexpected response schemas: STOP and verify against memory_server source

## Assumptions

- `memory_search(query="bridge-decision <phase-slug>", limit=5)` returns entries tagged with `bridge-decision` that are relevant to the phase. If false: search by tag directly if the API supports it, or broaden the query.
- `memory_forget` returns `{"success": true, "memory_id": "..."}` on success. If false: check actual return schema in memory_server/server.py and adjust response handling.
- `stat -f %m` works on macOS and `stat -c %Y` works on Linux for file mtime in epoch seconds. If false: use `date -r` or `python3 -c` as fallback.
- `git log --since="@$EPOCH" --oneline --grep="Debrief"` correctly filters debrief commits by timestamp. If false: use `git log --after` or compare commit hashes instead.
- All 198 cross-skill references use the `~/.claude/skills/` prefix (not `$HOME` or relative paths). If false: extend the grep pattern to cover all forms.
