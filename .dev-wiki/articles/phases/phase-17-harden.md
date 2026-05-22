---
title: "Phase 17: Harden"
status: active
started: 2026-05-22
updated: 2026-05-22
ceremony: standard
scope:
  - templates/.claude/hooks/detect-loop.sh
  - templates/.claude/hooks/session-start.sh
  - install.sh
  - tests/test_harden.sh
  - Makefile
exit_criteria:
  - detect-loop.sh detects 3+ consecutive identical failed Bash commands and emits advisory warning
  - session-start.sh nudges memory consolidation via sqlite3 query with cooldown
  - session-start.sh prunes stale working-knowledge entries to .stale-queue (max 5 per session)
  - session-start.sh clears .loop-state on session start
  - 8 fixture tests pass in test_harden.sh
  - install.sh copies detect-loop.sh and registers PostToolUse hook
  - make test passes (all existing + new tests)
tags: [hardening, hooks, memory, working-knowledge, loop-detection]
---

# Phase 17: Harden

## Objective

Add three independent hardening capabilities: loop/drift detection hook (PostToolUse), memory consolidation nudge + working-knowledge auto-pruning at session start, and install.sh distribution of the new hook.

## Background

Phase 16 added enforcement hooks (spec gate + deliverable check). This phase adds advisory hardening: detecting when the agent is stuck in a loop, nudging memory consolidation when entry count is high, and pruning stale working-knowledge entries. All signals are advisory (exit 0), not blocking.

## Approach

Three independent capabilities: (1) detect-loop.sh pure bash PostToolUse hook tracking consecutive identical failed Bash commands via .loop-state file, (2) session-start.sh enhancement with sqlite3-based memory nudge + working-knowledge auto-pruning + loop state clear, (3) install.sh hook registration. All advisory, no blocking.

## Key Decisions

- [[pure-bash-loop-detection]] — exception to python-json-parsing-hooks. <50ms budget requires no Python subprocess.
- [[sqlite3-memory-nudge]] — shell hooks can't call MCP tools. Query memory.db directly via sqlite3 with 2s timeout.
- [[staged-pruning-stale-queue]] — entries moved to .stale-queue, not deleted. Recoverable. Max 5 per session.

## Constraints

- detect-loop.sh must run <50ms (pure bash, no Python subprocess)
- All hooks exit 0 (advisory only, never block)
- sqlite3 dependency is soft — skip silently if unavailable
- Working-knowledge pruning max 5 entries per session
- `[pinned]` entries are never pruned

## Assumptions

- memory.db exists at ~/.claude/memory_server/memory.db with queryable tables. If false: skip memory nudge silently.
- PostToolUse hook JSON includes tool_name, tool_input, stdout, stderr, exit_code fields. If false: adapt parsing.
- working-knowledge.md entries follow `[uses: N]` format with `activated: YYYY-MM-DD` date. If false: skip age check for entries without dates.

## Formal Spec

specs/phase-17-harden.md (approved).
