---
title: "Phase 17: Harden — complete"
aliases: []
category: journal
tags: [hardening, hooks, memory, working-knowledge, loop-detection, session-start]
parents: [phase-17-harden]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 17: Harden — complete

## What Happened
- Built detect-loop.sh (54 lines, pure bash) as PostToolUse hook: tracks consecutive identical failed Bash commands via .loop-state file, emits advisory warning after 3+ identical failures. Exception to python-json-parsing-hooks convention for <50ms budget.
- Enhanced session-start.sh from ~53 to ~95 lines with three new capabilities: sqlite3-based memory entry count nudge (with 2s timeout + daily cooldown), working-knowledge auto-pruning (moves [uses:1] + >30d entries to .stale-queue, max 5/session, respects [pinned]), and .loop-state cleanup.
- Created test_harden.sh with 8 fixture-based tests covering loop detection edge cases, memory nudge fallback, and pruning behavior.
- Updated install.sh to copy detect-loop.sh and register PostToolUse hook in settings.json.

## Decisions Made
- [[pure-bash-loop-detection|Pure bash for detect-loop.sh]] -- high confidence (exception to python-json-parsing-hooks for <50ms budget)
- [[sqlite3-memory-nudge|sqlite3 for memory nudge]] -- medium confidence (shell can't call MCP; schema dependency risk accepted)
- [[staged-pruning-stale-queue|Staged pruning to .stale-queue]] -- high confidence (recoverable, max 5/session)

## Problems Solved
- sqlite3 schema discovery: needed table/column names from vendored memory_server's DB. Resolved by querying memory.db directly with graceful fallback if unavailable.

## Open Questions
- /spec routing: skill listed in available skills but not recognized as command. Persisted across 4 phases now. (raised 2026-05-21, carried forward)
- Spec/dev-plan UX: user flagged that /spec should auto-invoke from dev-plan, not be a separate manual step. Saved to memory.

## Artifacts Changed
- `templates/.claude/hooks/detect-loop.sh` (new — PostToolUse loop detection, 54 lines)
- `templates/.claude/hooks/session-start.sh` (enhanced — memory nudge, pruning, loop clear, ~95 lines)
- `tests/test_harden.sh` (new — 8 fixture-based tests)
- `install.sh` (detect-loop.sh hook copy + PostToolUse registration)
- `Makefile` (test_harden.sh target added)

## Health Delta
- Tests: 107 -> 115 (+8 hardening)
- Budget: 245/300 (unchanged)
- Soul: 59/60 (unchanged)

## Related
- [[phase-17-harden|Phase 17: Harden]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- session-start.sh approaching complexity threshold (~95 lines) — consider extracting pruning logic to helper script | suggest: session-start refactoring phase | evidence: line count growth across phases
- sqlite3 memory nudge depends on memory_server DB schema (is_active column) — if schema changes, nudge silently fails (graceful degradation, but invisible breakage) | suggest: schema version check or integration test | evidence: [[sqlite3-memory-nudge]]
- User flagged significant UX friction: /spec and /dev-plan should be one flow, not two manual steps | suggest: unified spec-then-plan command | evidence: saved to memory
