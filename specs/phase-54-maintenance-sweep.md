<!-- nana:approved 2026-05-27 -->
# Spec: Maintenance Sweep — Hook Bugs + Knowledge Corrections

## Objective
Fix 3 documented bugs in session-start hooks (wrong DB paths, wrong column name) and remove a stale working-knowledge entry that contradicts Phase 53 findings.

## Context
Phase 53 investigated MCP memory data loss and documented root causes in mcp-memory-diagnosis.md. The bugs were identified but explicitly deferred ("Bugs to fix in a future phase"). The stale working-knowledge entry (scenario 020 "consistently wrong") directly contradicts the corrected entry added in the same phase.

## Scope
### In scope
- Fix memory-nudge.sh: `is_active` → `active` column name
- Fix session-start.sh line 83: wrong DB path passed to memory-nudge function
- Fix session-start.sh lines 110-112: wrong DB path in MCP health check
- Remove stale working-knowledge entry (line 34, scenario 020 contradiction)
- Update/add test assertions for the fixed behavior

### Out of scope
- Changing MCP server CWD behavior (Claude Code platform issue)
- Adding `scope: "global"` to bridge-decisions (separate concern)
- Refactoring session-start.sh beyond the bug fixes
- memory_server/ source changes

## Approach
Surgical fixes to 3 files: memory-nudge.sh (column name), session-start.sh (two DB path references), working-knowledge.md (remove stale entry). DB path fix: use `.memory/memory.db` (project-relative, matching where Claude Code actually creates the DB). Add test assertions that validate the correct column and path.

## Constraints (CRITICAL)
- All session-start hooks must exit 0 (fail-open invariant): prevents session startup blocking
- memory-nudge.sh must handle missing `.memory/` directory gracefully: prevents crash on fresh installs or --core-only setups
- DB path must be project-relative (`.memory/memory.db`), not absolute: matches Claude Code's actual CWD behavior documented in mcp-memory-diagnosis.md
- Column name change must match storage.py:53 schema (`active INTEGER NOT NULL DEFAULT 1`): prevents silent query failure

## Deliverables
3 files modified:
1. `templates/.claude/hooks/session-start.d/memory-nudge.sh` — column fix
2. `templates/.claude/hooks/session-start.sh` — two DB path fixes
3. `.claude/rules/working-knowledge.md` — stale entry removed

Test updates:
4. `tests/test_harden.sh` — assertions for correct column and path

## Exit Criteria (machine-checkable)
- [ ] `! grep -q 'is_active' templates/.claude/hooks/session-start.d/memory-nudge.sh`
- [ ] `grep -qE 'WHERE.*\bactive\b' templates/.claude/hooks/session-start.d/memory-nudge.sh`
- [ ] `! grep -qF 'memory_server/memory.db' templates/.claude/hooks/session-start.sh`
- [ ] `grep -qF '.memory/memory.db' templates/.claude/hooks/session-start.sh`
- [ ] `! grep -q 'consistently wrong.*020' .claude/rules/working-knowledge.md`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Checkpoints
- After fixing memory-nudge.sh and session-start.sh: run `bash -n` on both to verify syntax
- If any test_harden.sh test fails after changes: STOP and investigate before proceeding

## Assumptions
- Claude Code runs session-start hooks with CWD = project root. If false: the `.memory/memory.db` path won't resolve either, but it's still more correct than the current `$HOME/.claude/memory_server/` path.
- storage.py column name `active` is stable. If false: check memory_server/storage.py before applying fix.
- The scenario 020 stale entry (line 34) is the only contradicted entry in working-knowledge. If false: search for other Phase 50 entries that reference "8/9" or "consistently wrong".
