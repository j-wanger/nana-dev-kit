# Current State: nana-dev-kit

> Last updated: 2026-05-25 by /dev-debrief (Phase 38 completed)

## Recommended Next Action

Run /dev-plan for Phase 39. Consider soft observations from journal: installed skill files at ~/.claude/skills/ are stale (need re-install), context-size-check.sh python3 vs jq inconsistency (carried from Phase 36), delivery-flow.md companion not installed.

## Active Phase

**[[phase-38-install-integrity-functional-verification|Phase 38: Install Integrity & Functional Verification]]** (status: completed, 100%)

Entry criteria: MET -- Phase 37 complete, spec approved (internal)
Exit criteria: ALL 7 MET (5 skills installed, MultiEdit matchers, scope-check fix, make test, make eval 100%, MANIFEST updated, PostToolUse inconsistency documented)

Progress: 100% (6/6 tasks done)

## Active Phase Contract

Phase: 38 - Install Integrity & Functional Verification
Tasks: 6 (4S + 1M + 1S, dependency chain: T1->T4, T1-4->T5)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[mcp-memory-server-cwd-fix]] | high | 2026-05-25 |
| [[fail-loud-over-fail-silent-memory]] | high | 2026-05-25 |
| [[install-skill-module-assignment]] | high | 2026-05-25 |
| [[posttooluse-field-path-inconsistency]] | high | 2026-05-25 |

## Blockers and Open Questions

- PostToolUse stdin contract: does Claude Code send .input or .tool_input for Write/Edit PostToolUse hooks? Both patterns appear in working hooks. (raised 2026-05-25)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Module-group installer (~535 lines, 5 module groups, CORE_SKILLS iteration, MCP verify, 11 global hooks) | 2026-05-25 |
| `templates/.claude/skills/MANIFEST` | Skill checksums + descriptions (25 skills, 124 files) | 2026-05-25 |
| `templates/.claude/hooks/dev-wiki-scope-check.sh` | PreToolUse scope check (fixed .input.file_path) | 2026-05-25 |
| `templates/.claude/hooks/session-start.sh` | Session start with MCP health check | 2026-05-25 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Dev-plan orchestrator with 2-gate ceremony (direction + delivery) | 2026-05-25 |
| `templates/.claude/skills/spec/SKILL.md` | Spec skill with --internal mode | 2026-05-25 |
| `scripts/generate-delivery-report.py` | HTML delivery report generator (196 lines) | 2026-05-25 |
| `tests/` | 6 test scripts, 283 tests (helpers.sh + test_*.sh) | 2026-05-25 |
| `memory_server/storage.py` | MCP memory storage (indexed lookups: vec0 KNN + FTS5 MATCH) | 2026-05-24 |
| `benchmark/longmemeval.py` | LongMemEval-S benchmark (FTS5+hybrid, recall@5/10) | 2026-05-24 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-25] [[2026-05-25-phase-38-install-integrity-complete|Phase 38 complete]] -- install integrity: MCP CWD fix, 5 skills added, MultiEdit matchers, scope-check fix, 23 new tests, 283 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-37-ceremony-streamlining-complete|Phase 37 complete]] -- ceremony streamlining: 4-gate to 2-gate, --internal spec, delivery report, auto-commit/push, 259 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-36-hooks-audit-housekeeping-complete|Phase 36 complete]] -- hooks audit, 5 backports + 1 delete, install.sh nested schema + --project-local, nanaclaw PR, 240 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-35-ts-init-implementation-complete|Phase 35 complete]] -- ts-init implementation (SKILL.md + scanner.md + transform.md), AGENTS-ts.md, ci-ts.yml, install.sh typescript module, 224 tests, 47/47 eval
- [2026-05-24] [[2026-05-24-phase-34-upstream-sync-store-opt-ts-design-complete|Phase 34 complete]] -- upstream sync, store() optimization (indexed lookups), ts-init design spec, 201 tests, 47/47 eval

## Cross-References

- Status: [[2026-05-25-codebase-snapshot|Codebase Snapshot 2026-05-25]]
- Phases 1-38: completed (see index.md)
- Decision: [[mcp-memory-server-cwd-fix|MCP memory server CWD fix]] -- high confidence
- Decision: [[fail-loud-over-fail-silent-memory|Fail-loud over fail-silent]] -- high confidence
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Retro: Phases 31-35 clean (0 blockers, 0 reversals, 0 user corrections)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
