# Current State: nana-dev-kit

> Last updated: 2026-05-23 by /dev-plan (Phase 30 planned)

## Recommended Next Action

Begin Task 1: generate-report.py updates (LAYERS 5→7, WORKFLOWS v0.5.0, categorize_files() Eval/Specs, test_start counting, MANIFEST reading).

## Active Phase

**[[phase-30-data-driven-report-generators|Phase 30: Data-Driven Report Generators]]** (status: active)

Entry criteria: MET (Phase 29 complete, 175 tests passing, 43/43 eval)
Exit criteria: reports show 7-Layer, no stale strings, Enforcement + Memory Bridge sections in workflow, staleness regression test, README numbers fixed

Progress: 0% (0/4 tasks done)

## Active Phase Contract

Phase: 30 - Data-Driven Report Generators
Tasks: 4 (1S + 2M + 1L, see tasks.md)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| None new — spec decisions from Phase 29 carry forward | — | — |

## Blockers and Open Questions

None currently.

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `scripts/eval-runner.sh` | Eval corpus runner (~310 lines, jq, HOME isolation, binary scoring, 4 categories) | 2026-05-23 |
| `eval/corpus/` | 43 scenario directories (28 hook-*, 6 skill-*, 5 lifecycle-*, 4 context-*) | 2026-05-23 |
| `install.sh` | Module-group installer (~320 lines, --all/--core-only/--no-python/--dry-run/--status, hooks module, 5 global hooks) | 2026-05-23 |
| `templates/.claude/hooks/` | 12 lifecycle hooks + session-start.d/ (all use [nana:<hook>] prefix, 8 use jq, enforce-spec + enforce-loop write enforcement.log) | 2026-05-23 |
| `templates/.claude/hooks/session-start.d/` | Sourced modules (wk-prune.sh, memory-nudge.sh) | 2026-05-22 |
| `templates/.claude/skills/` | 24 skill dirs + MANIFEST with descriptions (~120 files, ~650KB) | 2026-05-23 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 175 tests (helpers.sh + test_*.sh) | 2026-05-23 |
| `README.md` | v0.5.1 documentation (~95 lines, 7 sections + Requirements + Windows note) | 2026-05-23 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-23] [[2026-05-23-phase-29-grade-push-complete|Phase 29 complete]] -- root-skip, companion extraction, /nana + /memory-consolidate skills, spec provenance, enforcement logging, 175 tests
- [2026-05-23] [[2026-05-23-phase-28-dx-discoverability-complete|Phase 28 complete]] -- hook prefix normalization, install.sh --status, MANIFEST descriptions, [nana:kit] summary, 169 tests
- [2026-05-23] [[2026-05-23-phase-27-dx-ship-complete|Phase 27 complete]] -- README refresh, 3 staleness regression tests, install.sh summary polish, v0.5.0 shipped, 163 tests
- [2026-05-23] [[2026-05-23-phase-26-memory-harness-hardening-complete|Phase 26 complete]] -- memory supersession, crash recovery, cross-skill ref test, 4 decisions, 43 eval scenarios
- [2026-05-22] [[2026-05-22-phase-25-postcommit-hook-complete|Phase 25 complete]] -- PostCommit hook, .pending-commit sidecar, 3 eval scenarios, 159 tests, Gap 1.6 closed

## Cross-References

- Status: [[2026-05-23-codebase-snapshot|Codebase Snapshot 2026-05-23]]
- Phases 1-29: completed (see index.md)
- Decision: [[gap-43-wont-build|Gap 4.3 worktree/parallel won't-build]] -- high confidence, closed
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 21-25 clean (0 blockers, 0 reversals, 0 user corrections)
- Release: v0.5.0 tagged and pushed
