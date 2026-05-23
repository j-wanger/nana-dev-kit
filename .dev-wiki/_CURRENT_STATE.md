# Current State: nana-dev-kit

> Last updated: 2026-05-22 by /dev-plan (Phase 22 planned)

## Recommended Next Action

Begin Phase 22 Task 1: extract session-start modules into session-start.d/wk-prune.sh and memory-nudge.sh.

## Active Phase

**[[phase-22-session-start-refactor|Phase 22: Session-Start Refactor + v0.4.0 Ship]]** (status: active)

Entry criteria: MET (Phase 21 complete, 128 tests passing, 38/38 eval)
Exit criteria: session-start.sh ≤70 lines, sourced modules, scan-secrets fix, gap analysis updated, v0.4.0 tagged

Progress: ~0% (0/5 tasks done)

## Active Phase Contract

Phase: 22 - Session-Start Refactor + v0.4.0 Ship
Tasks: 5 (1M 4S, see tasks.md)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[session-start-modular-source]] | medium | 2026-05-22 |

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
| `install.sh` | Module-group installer (~270 lines, --all/--core-only/--no-python/--dry-run, hooks module) | 2026-05-22 |
| `templates/.claude/hooks/` | 11 lifecycle hooks (session-start, pre-compact, enforce-spec, enforce-loop, detect-loop, etc.) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST (115 files, ~630KB) | 2026-05-22 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/` | 6 test scripts, 128 tests (helpers.sh + test_*.sh) | 2026-05-22 |
| `VERSION` | Semantic version (0.3.0) | 2026-05-20 |

## Session Journal (last 5)

- [2026-05-22] [[2026-05-22-phase-21-eval-expansion-complete|Phase 21 complete]] -- eval expansion (38 scenarios, 4 categories, context category, validate-prompt.sh), make eval 38/38
- [2026-05-22] [[2026-05-22-phase-20-eval-harness-complete|Phase 20 complete]] -- eval harness (18 scenarios, runner, validators, schemas), make eval 18/18
- [2026-05-22] [[2026-05-22-phase-19-memory-wiki-bridge-complete|Phase 19 complete]] -- memory-wiki bridge (3 channels: dev-plan+spec write, wiki-query read), tests 120 -> 128
- [2026-05-22] [[2026-05-22-phase-18-spec-devplan-ux-complete|Phase 18 complete]] -- spec auto-invocation companion, routing investigation, STOP removed, tests 115 -> 120
- [2026-05-22] [[2026-05-22-phase-17-harden-complete|Phase 17 complete]] -- loop detection hook, memory nudge, working-knowledge pruning, tests 107 -> 115

## Cross-References

- Status: [[2026-05-22-codebase-snapshot|Codebase Snapshot 2026-05-22]]
- Phases 1-21: completed (see index.md)
- Decision: [[context-eval-new-category|Context eval as new runner category]] -- medium confidence, accepted
- Decision: [[hook-stdin-per-hook-contracts|Per-hook stdin JSON field contracts]] -- high confidence, accepted
- Decision: [[eval-missing-tool-fallback-only|Test missing-tool fallback paths only]] -- medium confidence, accepted
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- Gaps 1.3+3.3+4.4 closed by Phase 19
- Retro: Phases 16-20 clean (0 blockers, 0 reversals, 0 user corrections)
