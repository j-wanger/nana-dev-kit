# Current State: nana-dev-kit

> Last updated: 2026-05-23 by /dev-debrief (Phase 28 completed)

## Recommended Next Action

Run /dev-plan to plan Phase 29. Candidates: language-agnostic core (Gap 4.1, last OPEN gap), dev-wiki-hooks rules templating, MANIFEST automation.

## Active Phase

**[[phase-28-dx-discoverability|Phase 28: DX Discoverability]]** (status: completed)

Entry criteria: MET (Phase 27 complete, 163 tests passing, 43/43 eval, v0.5.0 tagged)
Exit criteria: All met -- hooks prefixed, --status works, MANIFEST enriched, [nana:kit] line, make test + make eval pass

Progress: 100% (6/6 tasks done)

## Active Phase Contract

Phase: 28 - DX Discoverability
Tasks: 6 (all complete)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[hook-prefix-nana-namespace]] | high | 2026-05-23 |
| [[status-in-install-sh]] | high | 2026-05-23 |

## Blockers and Open Questions

None

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `scripts/eval-runner.sh` | Eval corpus runner (~310 lines, jq, HOME isolation, binary scoring, 4 categories) | 2026-05-23 |
| `eval/corpus/` | 43 scenario directories (28 hook-*, 6 skill-*, 5 lifecycle-*, 4 context-*) | 2026-05-23 |
| `install.sh` | Module-group installer (~320 lines, --all/--core-only/--no-python/--dry-run/--status, hooks module, 5 global hooks) | 2026-05-23 |
| `templates/.claude/hooks/` | 12 lifecycle hooks + session-start.d/ (all use [nana:<hook>] prefix, 8 use jq) | 2026-05-23 |
| `templates/.claude/hooks/session-start.d/` | Sourced modules (wk-prune.sh, memory-nudge.sh) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST with descriptions (115 files, ~630KB) | 2026-05-23 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 169 tests (helpers.sh + test_*.sh) | 2026-05-23 |
| `README.md` | v0.5.0 documentation (~95 lines, 7 sections + Requirements + Windows note) | 2026-05-23 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-23] [[2026-05-23-phase-28-dx-discoverability-complete|Phase 28 complete]] -- hook prefix normalization, install.sh --status, MANIFEST descriptions, [nana:kit] summary, 169 tests
- [2026-05-23] [[2026-05-23-phase-27-dx-ship-complete|Phase 27 complete]] -- README refresh, 3 staleness regression tests, install.sh summary polish, v0.5.0 shipped, 163 tests
- [2026-05-23] [[2026-05-23-phase-26-memory-harness-hardening-complete|Phase 26 complete]] -- memory supersession, crash recovery, cross-skill ref test, 4 decisions, 43 eval scenarios
- [2026-05-22] [[2026-05-22-phase-25-postcommit-hook-complete|Phase 25 complete]] -- PostCommit hook, .pending-commit sidecar, 3 eval scenarios, 159 tests, Gap 1.6 closed
- [2026-05-22] [[2026-05-22-phase-24-dx-hook-performance-complete|Phase 24 complete]] -- jq hook migration (6 hooks), install.sh Getting Started, README Requirements, 150 tests

## Cross-References

- Status: [[2026-05-23-codebase-snapshot|Codebase Snapshot 2026-05-23]]
- Phases 1-28: completed (see index.md)
- Decision: [[gap-43-wont-build|Gap 4.3 worktree/parallel won't-build]] -- high confidence, closed
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 21-25 clean (0 blockers, 0 reversals, 0 user corrections)
- Release: v0.5.0 tagged and pushed
