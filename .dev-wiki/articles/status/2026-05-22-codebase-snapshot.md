---
title: "Codebase Snapshot 2026-05-22"
category: status
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Codebase Snapshot — 2026-05-22

## Metrics

| Metric | Value |
|--------|-------|
| Files (tracked) | 150+ (115 skill files, 14 memory_server .py, 10 hooks, 4 rules, 5 scripts, 8 test/config) |
| Test count | 107 (23 install + 16 sync + 38 templates + 10 enforce + 20 other) |
| Test status | All passing |
| Soul lines | 59/60 |
| Instruction budget | 245/300 |
| VERSION | 0.3.0 |
| Phases completed | 16 |
| Skill directories | 22 (6 dev-wiki + 11 knowledge-wiki + 5 original) |

## Module Structure

| Module | Files | Purpose |
|--------|-------|---------|
| templates/.claude/skills/ | 115 | 22 skill directories + MANIFEST |
| templates/.claude/hooks/ | 10 | Lifecycle hooks (session-start, pre-compact, enforce-spec, enforce-loop, etc.) |
| memory_server/ | 12 .py | Vendored MCP memory server |
| scripts/ | 3 | sync-rules.sh, generate-report.py, generate-workflow.py |
| tests/ | 5 | helpers.sh + 4 test scripts (107 tests) |
| templates/.claude/rules/ | 4 | Identity + lifecycle rules |

## Recent Commits (last 5)

- 1cdf613 Phase 16: Enforce the loop — spec enforcement hook, stop-hook deliverable check, 107 tests
- 05e69e0 Phase 15: Wire the lifecycle — monorepo skills, modular install, 92 tests
- de64747 Phase 14: Adversarial thinking & review — T0 rewrite, spec Step 2.5, 67 tests
- d2fdcfe Debrief Phase 13: soul H8+H9, personal template, v0.3.0, 65 tests
- 631e30a Phase 13: Final polish — H8+H9 heuristics, personal template, v0.3.0

## Key Changes Since Last Snapshot

- enforce-spec.sh (58 lines): PreToolUse hook blocks writes without approved spec
- enforce-loop.sh (85 lines): Stop hook checks file-existence deliverables
- install.sh gained hooks module + enforce marker + JSON merge for hooks registration
- session-start.sh gained enforcement status reporting
- test_enforce.sh created (10 fixture-based tests)
- test_install.sh gained 5 enforcement assertions (43 total)
- Tests: 92 -> 107 (+15)
