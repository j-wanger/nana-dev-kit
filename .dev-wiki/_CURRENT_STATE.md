# Current State: nana-dev-kit

> Last updated: 2026-05-23 by /dev-plan (Phase 26 planned)

## Recommended Next Action

Start implementing Phase 26 tasks in order. Task 1: Memory-bridge auto-supersede (rewrite memory-bridge.md with ceiling 500, auto-supersede step, memory_forget).

## Active Phase

**[[phase-26-memory-harness-hardening|Phase 26: Memory & Harness Hardening]]** (status: active)

Entry criteria: MET (Phase 25 complete, 159 tests passing, 41/41 eval)
Exit criteria: memory-bridge + harvest have supersede logic, session-start crash recovery, cross-skill ref test, README Windows note, 2 eval scenarios pass, all tests pass, eval 100%

Progress: ~0% (0/6 tasks done)

## Active Phase Contract

Phase: 26 - Memory & Harness Hardening
Tasks: 6 (3M 2S 1XS)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[memory-supersede-harness-layer]] | high | 2026-05-23 |
| [[crash-recovery-dual-condition]] | high | 2026-05-23 |
| [[cross-skill-ref-test-time]] | high | 2026-05-23 |

## Blockers and Open Questions

- [planning] No wiki articles on temporal memory management patterns (supersession chains, decay) -- knowledge gap
- [planning] No wiki articles on crash recovery in agentic development workflows -- knowledge gap

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `scripts/eval-runner.sh` | Eval corpus runner (~310 lines, jq, HOME isolation, binary scoring, 4 categories) | 2026-05-22 |
| `eval/corpus/` | 41 scenario directories (26 hook-*, 6 skill-*, 5 lifecycle-*, 4 context-*) | 2026-05-22 |
| `eval/schemas/` | 4 JSON input schemas for hook contracts | 2026-05-22 |
| `eval/validators/` | 4 bash validators for skill artifact contracts (spec, phase, decision, prompt) | 2026-05-22 |
| `eval/README.md` | Corpus structure, scoring docs, hook stdin contracts table | 2026-05-22 |
| `install.sh` | Module-group installer (~280 lines, --all/--core-only/--no-python/--dry-run, hooks module, PreCompact, Getting Started output) | 2026-05-22 |
| `templates/.claude/hooks/` | 12 lifecycle hooks + session-start.d/ (8 use jq, detect-loop pure bash, session-start + pre-compact + enforce-loop no JSON) | 2026-05-22 |
| `templates/.claude/hooks/session-start.d/` | Sourced modules (wk-prune.sh, memory-nudge.sh) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST (115 files, ~630KB) | 2026-05-22 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 159 tests (helpers.sh + test_*.sh) | 2026-05-22 |
| `README.md` | v0.4.0 documentation (~95 lines, 7 sections + Requirements) | 2026-05-22 |
| `VERSION` | Semantic version (0.4.0) | 2026-05-22 |

## Session Journal (last 5)

- [2026-05-22] [[2026-05-22-phase-25-postcommit-hook-complete|Phase 25 complete]] -- PostCommit hook, .pending-commit sidecar, 3 eval scenarios, 159 tests, Gap 1.6 closed
- [2026-05-22] [[2026-05-22-phase-24-dx-hook-performance-complete|Phase 24 complete]] -- jq hook migration (6 hooks), install.sh Getting Started, README Requirements, 150 tests
- [2026-05-22] [[2026-05-22-phase-23-bug-fixes-readme-complete|Phase 23 complete]] -- bug fixes (pre-compact registration, memory-harvest API), README rewrite (93 lines), 142 tests
- [2026-05-22] [[2026-05-22-phase-22-session-start-refactor-complete|Phase 22 complete]] -- session-start refactor, scan-secrets fix, gap analysis update, v0.4.0 shipped, 133 tests
- [2026-05-22] [[2026-05-22-phase-21-eval-expansion-complete|Phase 21 complete]] -- eval expansion (38 scenarios, 4 categories, context category, validate-prompt.sh), make eval 38/38

## Cross-References

- Status: [[2026-05-22-codebase-snapshot|Codebase Snapshot 2026-05-22]]
- Phases 1-25: completed (see index.md)
- Decision: [[postcommit-hook-architecture|PostCommit hook architecture (PostToolUse + advisory sidecar + JSON)]] -- high confidence, accepted
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 2 OPEN gaps remain (4.1, 4.3)
- Retro: Phases 21-25 clean (0 blockers, 0 reversals, 0 user corrections)
