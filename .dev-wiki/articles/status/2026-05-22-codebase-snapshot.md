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
| Files (tracked) | 150+ (115 skill files, 12 memory_server .py, 8 hooks/rules, 4 scripts, 7 test/config) |
| Test count | 92 (23 install + 16 sync + 38 templates + 15 other) |
| Test status | All passing (~5.2s) |
| Soul lines | 59/60 |
| Instruction budget | 245/300 |
| VERSION | 0.3.0 |
| Phases completed | 15 |
| Skill directories | 22 (6 dev-wiki + 11 knowledge-wiki + 5 original) |

## Module Structure

| Module | Files | Purpose |
|--------|-------|---------|
| templates/.claude/skills/ | 115 | 22 skill directories + MANIFEST |
| memory_server/ | 12 .py | Vendored MCP memory server |
| scripts/ | 3 | sync-rules.sh, generate-report.py, generate-workflow.py |
| tests/ | 4 | helpers.sh + 3 test scripts (92 tests) |
| templates/.claude/hooks/ | 8 | Lifecycle hooks (session-start, pre-compact, audit-log, etc.) |
| templates/.claude/rules/ | 4 | Identity + lifecycle rules |

## Recent Commits (last 5)

- 05e69e0 Phase 15: Wire the lifecycle -- monorepo skills, modular install, 92 tests
- de64747 Phase 14: Adversarial thinking & review -- T0 rewrite, spec Step 2.5, 67 tests
- d2fdcfe Debrief Phase 13: soul H8+H9, personal template, v0.3.0, 65 tests
- 631e30a Phase 13: Final polish -- H8+H9 heuristics, personal template, v0.3.0
- 7c03d66 Debrief Phase 12: soul warmth, memory-harvest, 63 tests, gate audit

## Key Changes Since Last Snapshot

- 17 skill directories imported from ~/.claude/skills/ (monorepo consolidation)
- install.sh refactored to module-group architecture with --all/--core-only/--no-python/--dry-run flags
- PreCompact hook added (pure bash)
- session-start.sh enhanced with memory_search guidance
- MANIFEST generated (114 entries)
- Tests: 67 -> 92 (+25)
