# Current State: nana-dev-kit

> Last updated: 2026-05-19 by /dev-debrief (Phase 7 complete)

## Recommended Next Action

Phase 7 complete. Review docs/workflow.html for usability assessment. Run /dev-plan when ready for Phase 8.

## Active Phase

**[[phase-07-soul-and-instructions-enhancement|Phase 7: Soul & Instructions Enhancement]]** (status: active)

Entry criteria: MET (Phase 6 complete, all templates functional)
Exit criteria: 0/5 -- cognitive protocols, personal extraction, rename, sync, budget test

Progress: ~0% (0/5 tasks done)

## Active Phase Contract

Phase: 7 - Soul & Instructions Enhancement
Tasks: 5 (2M + 3S, see tasks.md)
Transition: continue this session
Abort: If protocol content exceeds 300-line budget after 3 trim attempts, escalate

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[soul-vs-agents-delineation]] | high | 2026-05-19 |
| [[venv-isolated-memory-deps]] | medium | 2026-05-15 |
| [[install-sh-scope-expansion]] | medium | 2026-05-15 |

## Blockers and Open Questions

- [resolved] Soul vs AGENTS.md delineation: soul = cognitive identity (universal), AGENTS.md = operational contract (project-specific). Three-critic review confirmed.

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Global installer (4 files + memory_server + MCP + venv) | 2026-05-19 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `scripts/sync-rules.sh` | AGENTS.md to 4 agent surfaces (writability check) | 2026-05-15 |
| `scripts/generate-report.py` | Package inventory HTML generator | 2026-05-19 |
| `scripts/generate-workflow.py` | Workflow breakdown HTML generator (738 lines) | 2026-05-19 |
| `VERSION` | Semantic version (0.2.0) | 2026-05-19 |
| `.github/workflows/kit-ci.yml` | Kit CI: shellcheck + make test | 2026-05-15 |
| `Makefile` | Project targets (sync-rules, test, report, workflow) | 2026-05-19 |
| `tests/helpers.sh` | Shared test assertions + summary | 2026-05-15 |
| `tests/test_install.sh` | Install + venv + MCP tests | 2026-05-19 |
| `tests/test_sync_rules.sh` | Sync correctness + edge-case tests (16) | 2026-05-15 |
| `tests/test_templates.sh` | Protocol assertions + budget regression (14 tests) | 2026-05-19 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (50 lines, 3 protocols) | 2026-05-19 |
| `templates/.claude/rules/nana-personal.md` | Personal profile (installed globally) | 2026-05-19 |
| `templates/AGENTS.md` | Operational contract (Pre-commit sequence) | 2026-05-19 |
| `templates/` | 5-layer scaffolding templates (28 files) | 2026-05-19 |
| `docs/report.html` | Generated package inventory (v0.2.0) | 2026-05-19 |
| `docs/workflow.html` | Generated workflow breakdown (v0.2.0) | 2026-05-19 |
| `README.md` | Install + usage + memory/dev-wiki + upgrading | 2026-05-19 |

## Session Journal (last 5)

- [2026-05-19] [[2026-05-19-phase-7-soul-and-instructions-complete|Phase 7 complete]] -- soul restructured, personal extracted, 48 tests, budget 191/300
- [2026-05-19] [[2026-05-19-phase-5-and-6-complete|Phase 5 & 6 complete]] -- venv bootstrap, HTML reports, v0.2.0 shipped to GitHub
- [2026-05-15] [[2026-05-15-phase-4-dev-wiki-and-memory-integration-complete|Phase 4 complete]] -- 5 tasks done, memory_server vendored, 38 tests
- [2026-05-15] [[2026-05-15-phase-3-distribution-and-polish-complete|Phase 3 complete]] -- 6 tasks done, v0.1.0 tagged, 34 tests
- [2026-05-15] [[2026-05-15-phase-2-automated-testing-complete|Phase 2 complete]] -- 30 tests added, make test passes

## Cross-References

- Status: [[2026-05-15-codebase-snapshot|Codebase Snapshot 2026-05-15]]
- Phase: [[phase-01-foundation-and-packaging|Phase 1]] -- completed
- Phase: [[phase-02-automated-testing|Phase 2]] -- completed
- Phase: [[phase-03-distribution-and-polish|Phase 3]] -- completed
- Phase: [[phase-04-dev-wiki-and-memory-integration|Phase 4]] -- completed
- Phase: [[phase-05-memory-bootstrap-and-report|Phase 5]] -- completed
- Phase: [[phase-06-ship-and-workflow-assessment|Phase 6]] -- completed
- Phase: [[phase-07-soul-and-instructions-enhancement|Phase 7]] -- completed
- Decision: [[soul-vs-agents-delineation|Soul vs AGENTS.md delineation]] -- high confidence
