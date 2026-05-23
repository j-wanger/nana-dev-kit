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
| Test count | 142 (6 scripts: 46 install + 16 sync + 48 templates + 10 enforce + 8 harden + 14 other) |
| Test status | All passing |
| Eval scenarios | 38 (23 hook, 6 skill, 4 context, 5 lifecycle) -- all scoring 38/38 |
| Soul lines | 59/60 |
| Instruction budget | 245/300 |
| VERSION | 0.4.0 |
| Phases completed | 23 |
| Skill directories | 22 (6 dev-wiki + 11 knowledge-wiki + 5 original) |

## Module Structure

| Module | Files | Purpose |
|--------|-------|---------|
| templates/.claude/skills/ | 115 | 22 skill directories + MANIFEST |
| templates/.claude/hooks/ | 11 + 2 modules | Lifecycle hooks (session-start + session-start.d/, pre-compact, enforce-*, detect-loop, etc.) |
| memory_server/ | 12 .py | Vendored MCP memory server |
| eval/ | 50+ | Eval harness: 38 corpus scenarios, 4 schemas, 4 validators, README |
| scripts/ | 4 | sync-rules.sh, generate-report.py, generate-workflow.py, eval-runner.sh |
| tests/ | 6 | helpers.sh + 5 test scripts (142 tests) |
| templates/.claude/rules/ | 4 | Identity + lifecycle rules |

## Recent Commits (last 5)

- 0f5ea35 Phases 18-22: spec/dev-plan UX, memory-wiki bridge, eval harness, session-start refactor, v0.4.0
- 42edaa8 Phase 17: Harden -- loop detection, memory nudge, working-knowledge pruning, 115 tests
- 1cdf613 Phase 16: Enforce the loop -- spec enforcement hook, stop-hook deliverable check, 107 tests
- 05e69e0 Phase 15: Wire the lifecycle -- monorepo skills, modular install, 92 tests
- de64747 Phase 14: Adversarial thinking & review -- T0 rewrite, spec Step 2.5, 67 tests

## Key Changes Since Last Snapshot

- pre-compact.sh: registered in settings.json hooks + added to install.sh dev-wiki module
- memory-harvest.md: API rewritten to match memory-bridge.md (category=custom, tags, trust param)
- README.md: full rewrite (59 -> 93 lines, 7 sections for v0.4.0)
- Tests: 133 -> 142 (+9 new: PreCompact install, memory-harvest, README assertions)
- Phase 23 completed (bug fixes + README rewrite)
- Phase 22 completed (session-start refactor + v0.4.0)
