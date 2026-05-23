# Current State: nana-dev-kit

> Last updated: 2026-05-23 by /dev-plan (Phase 27 planned)

## Recommended Next Action

Begin Phase 27 implementation. Task 1: README refresh.

## Active Phase

**[[phase-27-dx-ship|Phase 27: DX + Ship]]** (status: active)

Entry criteria: MET (Phase 26 complete, 159 tests passing, 43/43 eval)
Exit criteria: README numbers fixed, staleness regression tests pass, install.sh summary updated, v0.5.0 tagged, make test + make eval pass

Progress: ~0% (0/4 tasks done)

## Active Phase Contract

Phase: 27 - DX + Ship
Tasks: 4 (see tasks.md)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[memory-supersede-harness-layer]] | high | 2026-05-23 |
| [[crash-recovery-dual-condition]] | high | 2026-05-23 |
| [[cross-skill-ref-test-time]] | high | 2026-05-23 |
| [[gap-43-wont-build]] | high | 2026-05-23 |

## Blockers and Open Questions

None

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `scripts/eval-runner.sh` | Eval corpus runner (~310 lines, jq, HOME isolation, binary scoring, 4 categories, init_git/touch_old support) | 2026-05-23 |
| `eval/corpus/` | 43 scenario directories (28 hook-*, 6 skill-*, 5 lifecycle-*, 4 context-*) | 2026-05-23 |
| `eval/schemas/` | 4 JSON input schemas for hook contracts | 2026-05-22 |
| `eval/validators/` | 4 bash validators for skill artifact contracts | 2026-05-22 |
| `eval/README.md` | Corpus structure, scoring docs, hook stdin contracts table | 2026-05-22 |
| `install.sh` | Module-group installer (~280 lines, --all/--core-only/--no-python/--dry-run, hooks module, PreCompact, Getting Started output) | 2026-05-22 |
| `templates/.claude/hooks/` | 12 lifecycle hooks + session-start.d/ (8 use jq, detect-loop pure bash, session-start + pre-compact + enforce-loop no JSON) | 2026-05-23 |
| `templates/.claude/hooks/session-start.d/` | Sourced modules (wk-prune.sh, memory-nudge.sh) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST (115 files, ~630KB) | 2026-05-23 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 159 tests (helpers.sh + test_*.sh) | 2026-05-23 |
| `README.md` | v0.4.0 documentation (~95 lines, 7 sections + Requirements + Windows note) | 2026-05-23 |
| `VERSION` | Semantic version (0.4.0) | 2026-05-22 |

## Session Journal (last 5)

- [2026-05-23] [[2026-05-23-phase-26-memory-harness-hardening-complete|Phase 26 complete]] -- memory supersession, crash recovery, cross-skill ref test, 4 decisions, 43 eval scenarios
- [2026-05-22] [[2026-05-22-phase-25-postcommit-hook-complete|Phase 25 complete]] -- PostCommit hook, .pending-commit sidecar, 3 eval scenarios, 159 tests, Gap 1.6 closed
- [2026-05-22] [[2026-05-22-phase-24-dx-hook-performance-complete|Phase 24 complete]] -- jq hook migration (6 hooks), install.sh Getting Started, README Requirements, 150 tests
- [2026-05-22] [[2026-05-22-phase-23-bug-fixes-readme-complete|Phase 23 complete]] -- bug fixes (pre-compact registration, memory-harvest API), README rewrite (93 lines), 142 tests
- [2026-05-22] [[2026-05-22-phase-22-session-start-refactor-complete|Phase 22 complete]] -- session-start refactor, scan-secrets fix, gap analysis update, v0.4.0 shipped, 133 tests

## Cross-References

- Status: [[2026-05-22-codebase-snapshot|Codebase Snapshot 2026-05-22]]
- Phases 1-26: completed (see index.md)
- Decision: [[gap-43-wont-build|Gap 4.3 worktree/parallel won't-build]] -- high confidence, closed
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 21-25 clean (0 blockers, 0 reversals, 0 user corrections)
