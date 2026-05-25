---
title: "Codebase Snapshot 2026-05-25"
aliases: []
category: status
tags: [snapshot]
parents: []
created: 2026-05-25
updated: 2026-05-25
---

# Codebase Snapshot 2026-05-25

## Metrics

- Files: ~370 (excluding .git, .dev-wiki, benchmark/data, benchmark/.venv)
- Tests: 240 (6 scripts)
- Eval: 47/47 scenarios (4 categories)
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated
- Version: 0.5.0
- Phases completed: 36
- Skill dirs: 25
- Hook scripts: 17 (5 new backports in Phase 36)
- install.sh: ~508 lines (11 global hooks, --project-local flag)

## Recent Commits

- Phase 36: Hooks Audit & Housekeeping (8 tasks, 240 tests, 47/47 eval)
- Phase 35: ts-init Implementation (7 tasks, 224 tests)
- Phase 34: Upstream Sync + store() Optimization + TypeScript Design Spec
- Phase 33: Hybrid Retrieval Benchmark + Memory Server Fixes
- Phase 32: LongMemEval-S Memory Benchmark

## Key Changes Since Last Snapshot (Phase 35 -> 36)

- templates/.claude/hooks/: 12 -> 17 scripts (+context-size-check, dev-wiki-scope-check, post-compact, session-stop, stale-queue)
- install.sh: ~330 -> ~508 lines (nested schema, 11 global hooks, --project-local flag, flat->nested migration)
- tests/test_install.sh: +16 assertions (nested schema, migration, project-local, backported hooks)
- README.md: 110 -> 117 lines (ts-init coverage, --no-typescript, --project-local)
- templates/.claude/skills/MANIFEST: regenerated (142 lines, 25 dirs)
- Nanaclaw upstream PR: https://github.com/j-wanger/nanaclaw/pull/1
