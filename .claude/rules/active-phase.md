# Active Phase Context

Phase: 16 - Enforce the Loop
Objective: Add deterministic enforcement hooks — enforce-spec.sh (PreToolUse, blocks writes without approved spec) and enforce-loop.sh (Stop, checks deliverable files) — distributed globally via install.sh with per-project opt-in via .claude/enforce marker.

Scope: templates/.claude/hooks/enforce-*.sh, install.sh, tests/test_enforce.sh, tests/test_install.sh, templates/.claude/hooks/session-start.sh, Makefile

Key constraints: 100ms hook budget, fail-open without marker, Python JSON parsing, path allowlist for meta/test/md files, advisory-only for open tasks and debrief.

Exit criteria: enforce-spec blocks no-spec writes, enforce-loop checks deliverables, 10 enforcement tests, install.sh distributes hooks, session-start reports enforcement status, make test passes.

Abort: if blocked >3 attempts on any task, ask user: skip or abort phase.

Tests: 92 passing. Soul: 59/60. Budget: 245/300.

Gates: [x] spec (pending formal write) [x] approach [x] plan-review [x] tasks
