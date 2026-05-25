# Current State: nana-dev-kit

> Last updated: 2026-05-25 by /dev-debrief (Phase 37 completed)

## Recommended Next Action

Run /dev-plan for Phase 38. Phase 37 (Ceremony Streamlining) is complete. Consider soft observations: stale installed skill files at ~/.claude/skills/, context-size-check.sh python3 vs jq inconsistency, delivery report diff content enhancement.

## Active Phase

**[[phase-37-ceremony-streamlining-autonomous-flow|Phase 37: Ceremony Streamlining & Autonomous Flow]]** (status: completed)

Entry criteria: MET -- Phase 36 complete, 240 tests, 47/47 eval, approach approved by user
Exit criteria: All 10 items met. 259 tests, 47/47 eval.

Progress: 100% (7/7 tasks done)

## Active Phase Contract

Phase: 37 - Ceremony Streamlining & Autonomous Flow (COMPLETED)
Tasks: 7 (all done)
Transition: run /dev-plan for Phase 38
Abort: n/a

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[ceremony-streamlining-2-gate-model]] | high | 2026-05-25 |
| [[spec-internal-mode]] | high | 2026-05-25 |
| [[delivery-report-before-commit]] | high | 2026-05-25 |

## Blockers and Open Questions

None.

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `templates/.claude/skills/dev-plan/SKILL.md` | Dev-plan orchestrator with 2-gate ceremony (direction + delivery), agent-internal flow | 2026-05-25 |
| `templates/.claude/skills/dev-plan/plan-review-companion.md` | Extracted plan-review Steps 7.5/7.6 | 2026-05-25 |
| `templates/.claude/skills/spec/SKILL.md` | Spec skill with --internal mode for autonomous flow | 2026-05-25 |
| `templates/.claude/skills/dev-debrief/SKILL.md` | Dev-debrief with delivery gate + auto-commit/push | 2026-05-25 |
| `templates/.claude/skills/dev-debrief/delivery-flow.md` | Delivery gate companion (report + accept/reject) | 2026-05-25 |
| `scripts/generate-delivery-report.py` | HTML delivery report generator (196 lines) | 2026-05-25 |
| `install.sh` | Module-group installer (~508 lines, 5 module groups, --project-local flag, 11 global hooks) | 2026-05-25 |
| `templates/.claude/skills/MANIFEST` | Skill checksums + descriptions (regenerated for Phase 37) | 2026-05-25 |
| `tests/` | 6 test scripts, 259 tests (helpers.sh + test_*.sh) | 2026-05-25 |
| `memory_server/storage.py` | MCP memory storage (_find_near_duplicate uses indexed lookups: vec0 KNN + FTS5 MATCH) | 2026-05-24 |
| `benchmark/longmemeval.py` | LongMemEval-S benchmark (FTS5+hybrid, turn-level indexing, per-question DB isolation, recall@5/10) | 2026-05-24 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-25] [[2026-05-25-phase-37-ceremony-streamlining-complete|Phase 37 complete]] -- ceremony streamlining: 4-gate to 2-gate, --internal spec, delivery report, auto-commit/push, 259 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-36-hooks-audit-housekeeping-complete|Phase 36 complete]] -- hooks audit, 5 backports + 1 delete, install.sh nested schema + --project-local, nanaclaw PR, 240 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-35-ts-init-implementation-complete|Phase 35 complete]] -- ts-init implementation (SKILL.md + scanner.md + transform.md), AGENTS-ts.md, ci-ts.yml, install.sh typescript module, 23 new tests, 224 tests, 47/47 eval
- [2026-05-24] [[2026-05-24-phase-34-upstream-sync-store-opt-ts-design-complete|Phase 34 complete]] -- upstream sync, store() optimization (indexed lookups), ts-init design spec, 11 new memory tests, 201 tests, 47/47 eval
- [2026-05-24] [[2026-05-24-phase-33-hybrid-retrieval-benchmark-complete|Phase 33 complete]] -- sanitizer fix, hybrid benchmark, turn-level RRF wins (+27.6% lift on failures, no degradation), 190 tests, 47/47 eval

## Cross-References

- Status: [[2026-05-25-codebase-snapshot|Codebase Snapshot 2026-05-25]]
- Phases 1-37: completed (see index.md)
- Decision: [[ceremony-streamlining-2-gate-model|Ceremony streamlining: 2-gate model]] -- high confidence
- Decision: [[spec-internal-mode|Spec --internal mode]] -- high confidence
- Decision: [[delivery-report-before-commit|Delivery report before commit]] -- high confidence
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 31-35 clean (0 blockers, 0 reversals, 0 user corrections)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
