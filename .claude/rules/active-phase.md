# Active Phase Context

Phase: 26 - Memory & Harness Hardening
Status: Active, 0/6 tasks done
Objective: Memory supersession (bridge + harvest), session-start crash recovery, cross-skill ref test, README Windows note, 2 eval scenarios.

Scope: templates/.claude/skills/dev-plan/memory-bridge.md, templates/.claude/skills/dev-debrief/memory-harvest.md, templates/.claude/hooks/session-start.sh, tests/test_templates.sh, README.md, eval/corpus/hook-session-start-*/

Constraints: No vendor code changes. memory_forget only (not memory_prune). Crash recovery advisory-only (exit 0).
Exit: memory-bridge + harvest have supersede, session-start crash recovery, cross-skill ref test passes, README Windows note, 2 eval scenarios, all tests + eval pass.
Abort: if blocked >3 attempts on any task, ask user: skip or abort.

Tests: 159 passing. Eval: 41/41. Budget: 245/300.

Gates: [x] spec [x] approach [x] plan-review [x] tasks
