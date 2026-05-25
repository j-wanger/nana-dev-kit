# Current State: nana-dev-kit

> Last updated: 2026-05-25 by /dev-debrief (Phase 39 completed)

## Recommended Next Action

Run /dev-plan for Phase 40. Consider soft observations from journal:
- install.sh Getting Started output doesn't mention /init (shows py-init, ts-init, dev-init, wiki-init but not init)
- README doesn't document /init yet (deferred to next phase per spec out-of-scope)
- PostToolUse .tool_input finding should be added to working-knowledge

## Active Phase

**[[phase-39-resilience-health-probes|Phase 39: Resilience & Health Probes]]** (status: COMPLETED, 6/6 tasks done, all 7 exit criteria met)

Entry criteria: MET -- Phase 38 completed (6/6 tasks, all exit criteria met)
Exit criteria: session-start.sh jq migration + 3-state health probe, context-size-check.sh jq migration, PostToolUse field path normalized, /init router installed, make test + make eval 100%

Progress: 100% (6/6 tasks done)

## Active Phase Contract

Phase: 39 - Resilience & Health Probes
Tasks: 6 (2S + 4M, dependency chain: T4→T5, T1-5→T6)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[health-probe-3-layer]] | high | 2026-05-25 |
| [[posttooluse-normalize-after-verification]] | high | 2026-05-25 |
| [[init-router-in-core]] | high | 2026-05-25 |
| [[mcp-memory-server-cwd-fix]] | high | 2026-05-25 |
| [[fail-loud-over-fail-silent-memory]] | high | 2026-05-25 |

## Blockers and Open Questions

(none)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Module-group installer (~535 lines, 5 module groups, CORE_SKILLS iteration incl. init, MCP verify, 11 global hooks) | 2026-05-25 |
| `templates/.claude/skills/MANIFEST` | Skill checksums + descriptions (26 skills) | 2026-05-25 |
| `templates/.claude/hooks/session-start.sh` | Session start with jq-based 3-state MCP health probe | 2026-05-25 |
| `templates/.claude/hooks/context-size-check.sh` | Context size check (jq migrated, no python3) | 2026-05-25 |
| `templates/.claude/skills/init/SKILL.md` | /init language router (44 lines, pyproject.toml/package.json detection) | 2026-05-25 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Dev-plan orchestrator with 2-gate ceremony (direction + delivery) | 2026-05-25 |
| `templates/.claude/skills/spec/SKILL.md` | Spec skill with --internal mode | 2026-05-25 |
| `scripts/generate-delivery-report.py` | HTML delivery report generator (196 lines) | 2026-05-25 |
| `tests/` | 6 test scripts, 291 tests (helpers.sh + test_*.sh) | 2026-05-25 |
| `eval/` | 50 eval scenarios in 4 categories (100%) | 2026-05-25 |
| `memory_server/storage.py` | MCP memory storage (indexed lookups: vec0 KNN + FTS5 MATCH) | 2026-05-24 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-25] [[2026-05-25-phase-39-resilience-health-probes-complete|Phase 39 complete]] -- resilience: 3-state health probe, jq migration complete, PostToolUse .tool_input canonical, /init router, 291 tests, 50/50 eval
- [2026-05-25] [[2026-05-25-phase-38-install-integrity-complete|Phase 38 complete]] -- install integrity: MCP CWD fix, 5 skills added, MultiEdit matchers, scope-check fix, 23 new tests, 283 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-37-ceremony-streamlining-complete|Phase 37 complete]] -- ceremony streamlining: 4-gate to 2-gate, --internal spec, delivery report, auto-commit/push, 259 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-36-hooks-audit-housekeeping-complete|Phase 36 complete]] -- hooks audit, 5 backports + 1 delete, install.sh nested schema + --project-local, nanaclaw PR, 240 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-35-ts-init-implementation-complete|Phase 35 complete]] -- ts-init implementation (SKILL.md + scanner.md + transform.md), AGENTS-ts.md, ci-ts.yml, install.sh typescript module, 224 tests, 47/47 eval

## Cross-References

- Status: [[2026-05-25-codebase-snapshot|Codebase Snapshot 2026-05-25]]
- Phases 1-39: completed (see index.md)
- Decision: [[health-probe-3-layer|3-layer health probe]] -- high confidence
- Decision: [[posttooluse-normalize-after-verification|PostToolUse .tool_input canonical]] -- high confidence
- Decision: [[init-router-in-core|/init router in CORE_SKILLS]] -- high confidence
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 31-35 clean (0 blockers, 0 reversals, 0 user corrections)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
