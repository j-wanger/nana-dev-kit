---
title: "Phase 54: Maintenance Sweep"
aliases: []
category: phases
tags: [hooks, bug-fix, maintenance]
parents: []
created: 2026-05-27
updated: 2026-05-28
source: plan
status: completed
scope: ["templates/.claude/hooks/session-start.sh", "templates/.claude/hooks/session-start.d/memory-nudge.sh", ".claude/rules/working-knowledge.md", "tests/test_harden.sh"]
entry_criteria: "Phase 53 completed, spec approved"
exit_criteria: "All 7 exit criteria from spec pass, make test + make eval green"
---

# Phase 54: Maintenance Sweep

## Objective

Fix 3 documented bugs in session-start hooks (wrong DB paths, wrong column name) and remove a stale working-knowledge entry that contradicts Phase 53 findings.

## Scope

Files and modules affected:
- `templates/.claude/hooks/session-start.d/memory-nudge.sh` — column name fix
- `templates/.claude/hooks/session-start.sh` — two DB path fixes
- `.claude/rules/working-knowledge.md` — stale entry removal
- `tests/test_harden.sh` — new test assertions

## Exit Criteria

- [ ] `! grep -q 'is_active' templates/.claude/hooks/session-start.d/memory-nudge.sh`
- [ ] `grep -qE 'WHERE.*\bactive\b' templates/.claude/hooks/session-start.d/memory-nudge.sh`
- [ ] `! grep -qF 'memory_server/memory.db' templates/.claude/hooks/session-start.sh`
- [ ] `grep -qF '.memory/memory.db' templates/.claude/hooks/session-start.sh`
- [ ] `! grep -q 'consistently wrong.*020' .claude/rules/working-knowledge.md`
- [ ] `make test`
- [ ] `make eval 2>&1 | grep -qE 'Score.*100'`

## Constraints

- All session-start hooks must exit 0 (fail-open invariant): prevents session startup blocking
- memory-nudge.sh must handle missing `.memory/` directory gracefully: prevents crash on fresh installs
- DB path must be project-relative (`.memory/memory.db`), not absolute: matches Claude Code's actual CWD behavior

## Notes

Bugs documented in mcp-memory-diagnosis.md (Phase 53). Stale entry at line 34 of working-knowledge.md claims scenario 020 is "consistently wrong" but Phase 53 proved clean baseline solves it correctly.
