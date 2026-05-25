---
title: "Phase 39: Resilience & Health Probes"
aliases: [phase-39]
category: phases
tags: [health-probe, jq-migration, posttooluse, init-router, resilience]
parents: []
created: 2026-05-25
updated: 2026-05-25
source: plan
status: completed
scope: [templates/.claude/hooks/session-start.sh, templates/.claude/hooks/context-size-check.sh, templates/.claude/hooks/post-commit.sh, templates/.claude/hooks/stale-queue.sh, templates/.claude/hooks/audit-log.sh, templates/.claude/hooks/auto-ruff-format.sh, templates/.claude/hooks/scan-secrets.sh, templates/.claude/skills/init/SKILL.md, install.sh, eval/]
entry_criteria: "Phase 38 completed (6/6 tasks, all exit criteria met)"
exit_criteria: "session-start.sh jq migration + 3-state health probe, context-size-check.sh jq migration, PostToolUse field path verified + normalized, /init router installed in CORE_SKILLS, make test passes, make eval 100%"
---

# Phase 39: Resilience & Health Probes

## Objective

Fix resilience gaps: migrate remaining python3 JSON parsing to jq, add 3-state memory health probe to session-start.sh, resolve PostToolUse field path inconsistency via live verification, and add the /init language router skill.

## Approach

Fix resilience gaps first (health probe, jq migration, PostToolUse verification), then add the /init router. The session-start.sh MCP block rewrite migrates python3 to jq for config reading AND enhances the health probe to emit 3-state diagnostics with sqlite3 entry count. context-size-check.sh is a standalone jq migration. PostToolUse verification creates a diagnostic to determine actual field path, normalizes all hooks, and adds defensive fallback. The /init router checks filesystem markers and dispatches.

## Scope

- `templates/.claude/hooks/session-start.sh` — MCP block rewrite + health probe
- `templates/.claude/hooks/context-size-check.sh` — jq migration
- `templates/.claude/hooks/{post-commit,stale-queue,audit-log,auto-ruff-format,scan-secrets}.sh` — PostToolUse normalization
- `templates/.claude/skills/init/SKILL.md` — language router
- `install.sh` + `MANIFEST` — init skill registration
- `eval/` — updated fixtures/schemas
- `tests/` — new assertions

## Exit Criteria

- [x] No python3 -c in session-start.sh or context-size-check.sh
- [x] session-start.sh emits 3-state memory diagnostic (healthy/broken/not configured)
- [x] All PostToolUse hooks use verified canonical field path (.tool_input)
- [x] /init router skill exists and routes based on filesystem markers
- [x] init in CORE_SKILLS, MANIFEST updated (26 skills)
- [x] make test passes (291 tests)
- [x] make eval 100% (50/50 scenarios)

## Decisions

- [[health-probe-3-layer]] — 3-layer health probe (jq config + import check + sqlite3 count)
- [[posttooluse-normalize-after-verification]] — verify then normalize all hooks to canonical path
- [[init-router-in-core]] — /init router in CORE_SKILLS (language-agnostic routing)

## Notes

- jq fail-open guard pattern established Phase 24: `command -v jq >/dev/null 2>&1 || exit 0`
- Hook fixes require tmpdir testing per hook-reconciliation-approach decision
- install.sh cp -r auto-distributes init/ skill dir
