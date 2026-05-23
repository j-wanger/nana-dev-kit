# Current State: nana-dev-kit

> Last updated: 2026-05-22 by /dev-debrief (Phase 23 completed)

## Recommended Next Action

Run /dev-plan to plan Phase 24. Candidates: language-agnostic core (Gap 4.1), session-start.sh refactor (U.3), eval corpus expansion (template-only hooks), bash 3.2 convention doc, scan-secrets BSD grep fix, install.sh cosmetic output fix.

## Active Phase

**[[phase-23-bug-fixes-readme|Phase 23: Bug Fixes + README Rewrite]]** (status: completed)

Entry criteria: MET (Phase 22 complete, 133 tests passing, 38/38 eval, v0.4.0 shipped)
Exit criteria: MET (PreCompact registered, memory-harvest.md aligned, README rewritten 93 lines, 142 tests + 38/38 eval pass)

Progress: 100% (6/6 tasks done)

## Active Phase Contract

Phase: 23 - Bug Fixes + README Rewrite
Tasks: 6 (2M 4S, see tasks.md)
Transition: complete
Abort: n/a (completed)

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[pre-compact-dev-wiki-module]] | high | 2026-05-22 |
| [[readme-budget-superseded]] | high | 2026-05-22 |

## Blockers and Open Questions

- None

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `scripts/eval-runner.sh` | Eval corpus runner (~310 lines, jq, HOME isolation, binary scoring, 4 categories) | 2026-05-22 |
| `eval/corpus/` | 38 scenario directories (23 hook-*, 6 skill-*, 5 lifecycle-*, 4 context-*) | 2026-05-22 |
| `eval/schemas/` | 4 JSON input schemas for hook contracts | 2026-05-22 |
| `eval/validators/` | 4 bash validators for skill artifact contracts (spec, phase, decision, prompt) | 2026-05-22 |
| `eval/README.md` | Corpus structure, scoring docs, hook stdin contracts table | 2026-05-22 |
| `install.sh` | Module-group installer (~270 lines, --all/--core-only/--no-python/--dry-run, hooks module, PreCompact) | 2026-05-22 |
| `templates/.claude/hooks/` | 11 lifecycle hooks + session-start.d/ (session-start, pre-compact, enforce-spec, enforce-loop, detect-loop, etc.) | 2026-05-22 |
| `templates/.claude/hooks/session-start.d/` | Sourced modules (wk-prune.sh, memory-nudge.sh) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST (115 files, ~630KB) | 2026-05-22 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 142 tests (helpers.sh + test_*.sh) | 2026-05-22 |
| `README.md` | v0.4.0 documentation (93 lines, 7 sections) | 2026-05-22 |
| `VERSION` | Semantic version (0.4.0) | 2026-05-22 |

## Session Journal (last 5)

- [2026-05-22] [[2026-05-22-phase-23-bug-fixes-readme-complete|Phase 23 complete]] -- bug fixes (pre-compact registration, memory-harvest API), README rewrite (93 lines), 142 tests
- [2026-05-22] [[2026-05-22-phase-22-session-start-refactor-complete|Phase 22 complete]] -- session-start refactor, scan-secrets fix, gap analysis update, v0.4.0 shipped, 133 tests
- [2026-05-22] [[2026-05-22-phase-21-eval-expansion-complete|Phase 21 complete]] -- eval expansion (38 scenarios, 4 categories, context category, validate-prompt.sh), make eval 38/38
- [2026-05-22] [[2026-05-22-phase-20-eval-harness-complete|Phase 20 complete]] -- eval harness (18 scenarios, runner, validators, schemas), make eval 18/18
- [2026-05-22] [[2026-05-22-phase-19-memory-wiki-bridge-complete|Phase 19 complete]] -- memory-wiki bridge (3 channels: dev-plan+spec write, wiki-query read), tests 120 -> 128

## Cross-References

- Status: [[2026-05-22-codebase-snapshot|Codebase Snapshot 2026-05-22]]
- Phases 1-23: completed (see index.md)
- Decision: [[pre-compact-dev-wiki-module|pre-compact.sh in dev-wiki module]] -- high confidence, accepted
- Decision: [[readme-budget-superseded|README budget 58 -> 90-100 lines]] -- high confidence, accepted
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 3 OPEN gaps remain (1.6, 4.1, 4.3)
- Retro: Phases 16-20 clean (0 blockers, 0 reversals, 0 user corrections)
