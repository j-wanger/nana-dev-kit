---
title: "Phase 39: Resilience & Health Probes complete"
aliases: []
category: journal
tags: [health-probe, jq-migration, posttooluse, init-router, resilience]
parents: [phase-39-resilience-health-probes]
created: 2026-05-25
updated: 2026-05-25
source: debrief
---

# Phase 39: Resilience & Health Probes complete

## What Happened
- Rewrote session-start.sh MCP block: python3 JSON parsing replaced with jq for settings.json reads, kept $MCP_CMD import check, added sqlite3 entry count with graceful fallback, emits 3-state output (healthy/broken/not configured).
- Migrated context-size-check.sh from python3 to jq — last non-jq JSON-parsing hook eliminated.
- Resolved PostToolUse field path inconsistency via live verification: .tool_input is canonical (verified via stale-queue.sh production evidence). All 5 PostToolUse Edit/Write hooks normalized to .tool_input.file_path // .input.file_path defensive fallback. 6 eval fixtures updated.
- Created /init router skill (44 lines): detects pyproject.toml/package.json markers, handles polyglot/empty cases, dispatches to py-init or ts-init.
- Added init to CORE_SKILLS in install.sh, regenerated MANIFEST (26 skills, was 25).
- Added 8 new test assertions and 3 new eval scenarios (hook-context-size-jq, hook-session-start-memory-healthy, hook-session-start-memory-broken).

## Decisions Made
- [[health-probe-3-layer|3-layer health probe]] -- high confidence (implemented and verified)
- [[posttooluse-normalize-after-verification|PostToolUse normalize after verification]] -- high confidence (live-verified via stale-queue production evidence)
- [[init-router-in-core|/init router in CORE_SKILLS]] -- high confidence (implemented)

## Problems Solved
- PostToolUse field path inconsistency (was MEDIUM known issue since Phase 38) -- resolved: .tool_input is canonical
- python3 dependency in JSON-parsing hooks -- eliminated (all hooks now use jq)
- No unified project init command -- /init now routes to py-init or ts-init based on filesystem markers

## Artifacts Changed
- `templates/.claude/hooks/session-start.sh` (MCP block rewrite: python3→jq + sqlite3 health probe)
- `templates/.claude/hooks/context-size-check.sh` (python3→jq migration)
- `templates/.claude/hooks/{audit-log,auto-ruff-format,scan-secrets}.sh` (PostToolUse field path: .input.file_path → .tool_input.file_path // .input.file_path)
- `templates/.claude/hooks/{post-commit,stale-queue}.sh` (added defensive fallback)
- `templates/.claude/skills/init/SKILL.md` (new, 44 lines)
- `install.sh` (init added to CORE_SKILLS)
- `templates/.claude/skills/MANIFEST` (26 skills, +init)
- `eval/schemas/post-tool-use.json` (updated to canonical field path)
- `eval/corpus/hook-{audit-log,auto-ruff,scan-secrets}-*` (fixture field path updates)
- `eval/corpus/hook-context-size-jq/` (new scenario)
- `eval/corpus/hook-session-start-memory-{healthy,broken}/` (new scenarios)
- `tests/test_install.sh` + `tests/test_templates.sh` (+8 assertions)

## Health Delta
- Tests: 283 to 291 (+8 new assertions)
- Eval: 47/47 to 50/50 (+3 scenarios: hook-context-size-jq, hook-session-start-memory-healthy, hook-session-start-memory-broken)
- All hooks now use jq for JSON parsing (python3 eliminated from JSON-parsing hooks)
- PostToolUse field path inconsistency RESOLVED

## Related
- [[phase-39-resilience-health-probes|Phase 39]]

## Soft Observations / Phase N+1 Candidates
- install.sh Getting Started output doesn't mention /init (shows py-init, ts-init, dev-init, wiki-init but not init)
- README doesn't document /init yet (deferred to next phase per spec out-of-scope)
- PostToolUse .tool_input finding should be added to working-knowledge
