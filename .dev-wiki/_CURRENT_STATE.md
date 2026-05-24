# Current State: nana-dev-kit

> Last updated: 2026-05-24 by /dev-debrief (Phase 32 completed)

## Recommended Next Action

Run /dev-plan to plan Phase 33. Candidates: language-agnostic core (Gap 4.1, last OPEN gap), hybrid retrieval benchmark (fastembed + sqlite-vec), memory_server upstream fixes (_sanitize_fts_query `?` handling), generator refactoring, generalized MCP enforcement.

## Active Phase

**[[phase-32-longmemeval-s-benchmark|Phase 32: LongMemEval-S Memory Benchmark]]** (status: active)

Entry criteria: MET (Phase 31 complete, 190 tests passing, 47/47 eval)
Exit criteria: benchmark/longmemeval.py exists + parses, --smoke-test exits 0, --dry-run 3 exits 0, benchmark/README.md exists, .gitignore updated, make test passes

Progress: 100% (3/3 tasks done)

## Active Phase Contract

Phase: 32 - LongMemEval-S Memory Benchmark
Tasks: 3 (1M + 1L + 1S, see tasks.md)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[diagnostic-first-benchmark]] | high | 2026-05-24 |

## Blockers and Open Questions

None currently.

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `benchmark/longmemeval.py` | LongMemEval-S memory retrieval benchmark (FTS5+hybrid, per-question DB isolation, recall@5/10 scoring) | 2026-05-24 |
| `benchmark/README.md` | Benchmark usage instructions and interpretation guide | 2026-05-24 |
| `scripts/generate-report.py` | Package inventory report generator (7-Layer, v0.5.0, Eval/Specs categories, test_start counting) | 2026-05-23 |
| `scripts/generate-workflow.py` | Workflow breakdown generator (~800 lines, 7-Layer, 12-hook table, Enforcement + Memory Bridge sections) | 2026-05-23 |
| `scripts/eval-runner.sh` | Eval corpus runner (~310 lines, jq, HOME isolation, binary scoring, 4 categories) | 2026-05-23 |
| `eval/corpus/` | 47 scenario directories (31 hook-*, 6 skill-*, 6 lifecycle-*, 4 context-*) | 2026-05-24 |
| `install.sh` | Module-group installer (~320 lines, --all/--core-only/--no-python/--dry-run/--status, hooks module, 6 global hooks) | 2026-05-24 |
| `templates/.claude/hooks/` | 13 lifecycle hooks + session-start.d/ (all use [nana:<hook>] prefix, 9 use jq, enforce-spec + enforce-loop + enforce-memory write enforcement.log) | 2026-05-24 |
| `templates/.claude/hooks/session-start.d/` | Sourced modules (wk-prune.sh, memory-nudge.sh) | 2026-05-22 |
| `templates/.claude/skills/` | 24 skill dirs + MANIFEST with descriptions (~120 files, ~650KB) | 2026-05-23 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 190 tests (helpers.sh + test_*.sh) | 2026-05-24 |
| `docs/report.html` | Generated package inventory report (7-Layer, Eval/Specs categories) | 2026-05-23 |
| `docs/workflow.html` | Generated workflow breakdown (7-Layer, 12-hook table, Enforcement + Memory Bridge) | 2026-05-23 |
| `README.md` | v0.5.1 documentation (~100 lines, 7 sections + Requirements + Windows note + Memory Benchmark) | 2026-05-24 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-24] [[2026-05-24-phase-32-longmemeval-s-benchmark-complete|Phase 32 complete]] -- LongMemEval-S benchmark, FTS5 recall@5 91.0%, benchmark/longmemeval.py, README updated, 190 tests, 47/47 eval
- [2026-05-24] [[2026-05-24-phase-31-integration-eval-memory-gating-complete|Phase 31 complete]] -- lifecycle eval scenario, enforce-memory.sh hook, install.sh registration, 3 eval scenarios, 190 tests, 47/47 eval
- [2026-05-23] [[2026-05-23-phase-30-data-driven-reports-complete|Phase 30 complete]] -- generate-report.py + generate-workflow.py 7-Layer updates, Enforcement + Memory Bridge sections, 6 staleness regression tests, 181 tests
- [2026-05-23] [[2026-05-23-phase-29-grade-push-complete|Phase 29 complete]] -- root-skip, companion extraction, /nana + /memory-consolidate skills, spec provenance, enforcement logging, 175 tests
- [2026-05-23] [[2026-05-23-phase-28-dx-discoverability-complete|Phase 28 complete]] -- hook prefix normalization, install.sh --status, MANIFEST descriptions, [nana:kit] summary, 169 tests

## Cross-References

- Status: [[2026-05-23-codebase-snapshot|Codebase Snapshot 2026-05-23]]
- Phases 1-32: completed (see index.md)
- Decision: [[diagnostic-first-benchmark|Diagnostic-first benchmark]] -- high confidence, validated (FTS5 recall@5 91.0%)
- Decision: [[gap-43-wont-build|Gap 4.3 worktree/parallel won't-build]] -- high confidence, closed
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 26-30 clean (0 blockers, 0 reversals, 0 user corrections)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, recall@10 95.2% (500 questions, LongMemEval-S)
