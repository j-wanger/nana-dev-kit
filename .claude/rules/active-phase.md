# Active Phase Context

Phase: 17 - Harden
Status: Active, 0/4 tasks done
Objective: Loop detection hook (PostToolUse), memory nudge + working-knowledge pruning (session-start), install.sh distribution.

Scope: templates/.claude/hooks/detect-loop.sh, templates/.claude/hooks/session-start.sh, tests/test_harden.sh, Makefile, install.sh

Key constraints:
- detect-loop.sh: pure bash, <50ms, advisory only (exit 0)
- sqlite3 soft dependency (skip if unavailable); pruning max 5/session, [pinned] exempt
- All signals advisory, never blocking

Exit criteria: detect-loop warns on 3+ identical failures, memory nudge with cooldown, stale entries pruned to .stale-queue, 8 new tests, make test passes

Abort: if blocked >3 attempts on any task, ask user

Tests: 107 passing. Soul: 59/60. Budget: 245/300.

Gates: [x] spec [x] approach [x] plan-review [x] tasks
