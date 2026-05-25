<!-- nana:approved 2026-05-25 -->
# Spec: Phase 39 — Resilience & Health Probes

## Objective
Prevent silent failures by adding runtime health detection, complete the jq migration for the last 2 python3 hooks, resolve the PostToolUse field path ambiguity, and add a language-detection router so users don't need to know which /init skill to invoke.

## Context
Phase 38 revealed the MCP memory server was non-functional for 33 phases — a CWD path bug in settings.json that structural tests never caught. The CWD is fixed and functional tests added, but there's no session-start health probe to catch future configuration regressions. Meanwhile, 2 of 13 hooks still use python3 for JSON parsing (context-size-check.sh and session-start.sh MCP block) despite all others migrating to jq in Phase 24. PostToolUse hooks have an unresolved field path inconsistency: 3 hooks use `.input.file_path`, 2 use `.tool_input.file_path`. Both patterns pass their eval scenarios because fixtures match each hook's expectation. Finally, Phase 35 added /ts-init alongside /py-init but there's no router — users must know which language scaffold to invoke.

## Scope
### In scope
- Memory server health probe in session-start.sh: rewrite MCP block from python3→jq for config reading, keep `$MCP_CMD -c "import memory_server"` functional check, add sqlite3 DB entry count, emit 3-state status: `[nana:memory] server healthy (N entries)` / `[nana:memory] server broken (<reason>)` / `[nana:memory] not configured`
- context-size-check.sh: replace python3 JSON parsing with jq + fail-open guard
- PostToolUse field path: live-verify which field Claude Code sends for Write/Edit PostToolUse, fix hooks using wrong path, update eval schema if needed
- /init router skill: detect language from project markers (pyproject.toml/setup.py → Python, package.json/tsconfig.json → TypeScript), route to /py-init or /ts-init, prompt user when ambiguous or empty
- Tests, eval scenarios, MANIFEST for all changes

### Out of scope
- install.sh Python extraction (deferred — Phase 38 functional tests cover the risk)
- New hooks or enforcement mechanisms
- Changing hook behavior beyond field path fixes
- Adding new language scaffolds (only routing between existing py-init and ts-init)
- README/AGENTS.md updates for /init router (next phase — keep py-init/ts-init docs as-is)
- Stale code article updates (.dev-wiki/articles/files/)

## Approach
Fix resilience gaps first (health probe, jq migration, PostToolUse verification), then add the /init router. Tasks 1 and 3 from the original plan merge: the session-start.sh MCP block rewrite migrates python3→jq for config reading AND enhances the health probe to emit 3-state diagnostics with sqlite3 entry count. The `$MCP_CMD -c "import memory_server"` functional check remains (it's the server's own Python binary, not system python3). context-size-check.sh is a standalone jq migration. PostToolUse verification creates a temporary diagnostic hook that dumps stdin to a file, triggers a Write tool use, reads the dump, then fixes hooks using the wrong field path. The /init router is a new ~30-40 line SKILL.md that checks filesystem markers and dispatches.

Note: bash hooks cannot call MCP tools directly (memory_stats, memory_search). The health probe uses 3 layers: (1) jq reads settings.json config, (2) `$MCP_CMD` tests module import from CWD, (3) sqlite3 checks memory.db entry count. Actual MCP protocol testing requires Claude to run memory_search in-session — the hook emits guidance for this.

## Constraints (CRITICAL)
- Health probe must NOT block session start on failure. Emit advisory, exit 0 always. Must distinguish 3 states: not configured / configured but broken (with reason) / healthy (with entry count). Prevents: broken session-start blocking all sessions + losing diagnostic signal.
- jq fail-open guard (`command -v jq >/dev/null 2>&1 || exit 0`) must be added to context-size-check.sh AND verified present in the migrated session-start.sh MCP block. Prevents: session failures in environments without jq.
- jq migration must produce identical output to python3 on representative inputs (transcript_path extraction, MCP config reading). Verify behavioral equivalence before replacing. Prevents: subtle behavioral differences (null handling, missing keys).
- PostToolUse field path fix must update BOTH the hooks AND the eval schema/fixtures to match reality. Each fixed hook should include a defensive null-check: if expected field yields empty, log warning to stderr and exit 0 (fail-open). Prevents: tests passing against wrong fixtures + future upstream schema changes.
- /init router must NOT auto-invoke a scaffold without user confirmation when both Python and TypeScript markers exist (polyglot repos) or when no markers exist (empty/ambiguous). Prevents: scaffolding wrong language.
- The session-start.sh MCP block rewrite must preserve existing health checks (command path validation, CWD import test) while adding sqlite3 entry count. Prevents: regression in failure detection.
- All hook changes must be tested in tmpdir isolation before touching live state. Prevents: self-lockout (established pattern from hook-reconciliation-approach decision).

## Deliverables
1. `templates/.claude/hooks/session-start.sh` — MCP block rewritten: python3→jq + memory_stats health probe
2. `templates/.claude/hooks/context-size-check.sh` — python3→jq migration with fail-open guard
3. PostToolUse hooks (post-commit.sh and/or stale-queue.sh and/or audit-log.sh etc.) — field path fixes based on live verification
4. `eval/schemas/post-tool-use.json` — updated if field path changes
5. `templates/.claude/skills/init/SKILL.md` — language-detection router (~30-40 lines)
6. `templates/.claude/skills/MANIFEST` — regenerated with init skill
7. `install.sh` — add init skill to core module
8. `tests/test_install.sh` + `tests/test_templates.sh` — new assertions
9. `eval/corpus/` — new scenarios for health probe, jq hooks, PostToolUse field path

## Exit Criteria (machine-checkable)
- [ ] `grep -q 'jq' templates/.claude/hooks/context-size-check.sh && ! grep -q 'python3' templates/.claude/hooks/context-size-check.sh`
- [ ] `! grep 'python3 -c' templates/.claude/hooks/session-start.sh` — no python3 for JSON parsing (note: `$MCP_CMD -c "import ..."` is the server's own Python, not system python3)
- [ ] `grep -q 'memory.*healthy' templates/.claude/hooks/session-start.sh && grep -q 'memory.*broken' templates/.claude/hooks/session-start.sh && grep -q 'memory.*configured' templates/.claude/hooks/session-start.sh` — all 3 health states present
- [ ] `make test` — all tests pass
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'` — eval 100%
- [ ] `test -f templates/.claude/skills/init/SKILL.md` — router skill exists
- [ ] `grep -q '# init:' templates/.claude/skills/MANIFEST` — MANIFEST updated with description

## Checkpoints
- After PostToolUse live verification (Task 4): report findings before applying fixes — the field path answer determines scope of subsequent hook changes
- After all hook changes (Tasks 1-4): run make test + make eval before proceeding to /init router

## Assumptions
- The session-start bash hook cannot call MCP tools directly. Health probe uses jq + python import + sqlite3 instead of memory_stats. If MCP stdio invocation from bash becomes possible: upgrade to a direct memory_stats call.
- jq is available in the typical Claude Code environment. If false: the fail-open guard handles this gracefully (hooks exit 0).
- PostToolUse stdin has a single canonical field path for file_path (either `.input.file_path` or `.tool_input.file_path`, not both). If false: hooks should try both paths with fallback (`jq -r '.input.file_path // .tool_input.file_path // empty'`).
- The /init router can detect language from filesystem markers (pyproject.toml → Python, package.json/tsconfig.json → TypeScript). If false: always prompt the user.
- sqlite3 is available for DB health check. If false: skip entry count, report "healthy (db check skipped)" based on import success alone.
