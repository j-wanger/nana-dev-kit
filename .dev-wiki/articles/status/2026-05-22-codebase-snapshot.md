---
title: "Codebase Snapshot 2026-05-22"
category: status
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Codebase Snapshot -- 2026-05-22

## Metrics

| Metric | Value |
|--------|-------|
| Files (tracked) | 190+ (115 skill files, 14 memory_server .py, 11 hooks, 4 rules, 5 scripts, 38 eval scenarios, 4 eval schemas, 4 eval validators, 8 test/config) |
| Test count | 128 (6 scripts: 44 install + 16 sync + 38 templates + 10 enforce + 8 harden + 12 other) |
| Test status | All passing |
| Eval scenarios | 38 (23 hook, 6 skill, 4 context, 5 lifecycle) -- all scoring 38/38 |
| Soul lines | 59/60 |
| Instruction budget | 245/300 |
| VERSION | 0.3.0 |
| Phases completed | 21 |
| Skill directories | 22 (6 dev-wiki + 11 knowledge-wiki + 5 original) |

## Module Structure

| Module | Files | Purpose |
|--------|-------|---------|
| templates/.claude/skills/ | 115 | 22 skill directories + MANIFEST |
| templates/.claude/hooks/ | 11 | Lifecycle hooks (session-start, pre-compact, enforce-*, detect-loop, etc.) |
| memory_server/ | 12 .py | Vendored MCP memory server |
| eval/ | 50+ | Eval harness: 38 corpus scenarios, 4 schemas, 4 validators, README |
| scripts/ | 4 | sync-rules.sh, generate-report.py, generate-workflow.py, eval-runner.sh |
| tests/ | 6 | helpers.sh + 5 test scripts (128 tests) |
| templates/.claude/rules/ | 4 | Identity + lifecycle rules |

## Recent Commits (last 5)

- 42edaa8 Phase 17: Harden -- loop detection, memory nudge, working-knowledge pruning, 115 tests
- 1cdf613 Phase 16: Enforce the loop -- spec enforcement hook, stop-hook deliverable check, 107 tests
- 05e69e0 Phase 15: Wire the lifecycle -- monorepo skills, modular install, 92 tests
- de64747 Phase 14: Adversarial thinking & review -- T0 rewrite, spec Step 2.5, 67 tests
- d2fdcfe Debrief Phase 13: soul H8+H9, personal template, v0.3.0, 65 tests

## Key Changes Since Last Snapshot

- scripts/eval-runner.sh: added context) category case (~40 lines), now ~310 lines total
- eval/corpus/: 18 -> 38 scenarios (20 new: 13 hook, 4 context, 1 skill, 2 lifecycle)
- eval/validators/validate-prompt.sh: new prompt validator
- eval/README.md: updated with context category docs, hook stdin contracts table
- Phase 21 completed (eval expansion)
