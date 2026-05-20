# Current State: nana-dev-kit

> Last updated: 2026-05-19 by /dev-debrief (Phase 8 complete)

## Recommended Next Action

Phase 8 complete. Review docs/workflow.html for usability assessment. Run /dev-plan when ready for Phase 9.

## Active Phase

**[[phase-08-spec-skill|Phase 8: Spec Skill]]** (status: completed)

Entry criteria: MET (Phase 7 complete, all templates functional)
Exit criteria: 4/4 -- spec skill + reviewer, phase template backport, install + tests, README

Progress: 100% (4/4 tasks done)

## Active Phase Contract

Phase: 8 - Spec Skill
Tasks: 4 (2M + 2S, see tasks.md)
Transition: continue this session
Abort: If SKILL.md exceeds 120 lines after 3 trim attempts, escalate

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[spec-two-tier-review-gate]] | high | 2026-05-19 |
| [[spec-persistence-adaptive]] | high | 2026-05-19 |
| [[soul-vs-agents-delineation]] | high | 2026-05-19 |

## Blockers and Open Questions

- [resolved] Spec persistence: adaptive routing — enrich phase article in dev-wiki, standalone specs/ otherwise. Two-critic validated.
- [resolved] Spec vs dev-plan overlap: /spec is portable standalone, /dev-plan uses spec template internally.

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Global installer (5 items: py-init + spec + soul + personal + memory_server) | 2026-05-19 |
| `templates/.claude/skills/spec/SKILL.md` | Spec creation skill (113 lines, two-tier review gate) | 2026-05-19 |
| `templates/.claude/skills/spec/spec-reviewer-prompt.md` | Spec quality reviewer (77 lines, 6 dimensions) | 2026-05-19 |
| `specs/phase-08-spec-skill.md` | First formal spec (Opus-reviewed 8/10, exemplar) | 2026-05-19 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `scripts/sync-rules.sh` | AGENTS.md to 4 agent surfaces (writability check) | 2026-05-15 |
| `scripts/generate-report.py` | Package inventory HTML generator | 2026-05-19 |
| `scripts/generate-workflow.py` | Workflow breakdown HTML generator (738 lines) | 2026-05-19 |
| `VERSION` | Semantic version (0.2.0) | 2026-05-19 |
| `.github/workflows/kit-ci.yml` | Kit CI: shellcheck + make test | 2026-05-15 |
| `Makefile` | Project targets (sync-rules, test, report, workflow) | 2026-05-19 |
| `tests/test_install.sh` | Install + venv + MCP + spec tests (20) | 2026-05-19 |
| `tests/test_sync_rules.sh` | Sync correctness + edge-case tests (16) | 2026-05-15 |
| `tests/test_templates.sh` | Protocol + spec + budget regression (19 tests) | 2026-05-19 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (51 lines, 3 protocols) | 2026-05-19 |
| `templates/.claude/rules/nana-personal.md` | Personal profile (installed globally) | 2026-05-19 |
| `templates/AGENTS.md` | Operational contract (Pre-commit sequence) | 2026-05-19 |
| `templates/` | 5-layer scaffolding templates (30+ files) | 2026-05-19 |
| `docs/report.html` | Generated package inventory (v0.2.0) | 2026-05-19 |
| `docs/workflow.html` | Generated workflow breakdown (v0.2.0) | 2026-05-19 |
| `README.md` | Install + usage + /spec + memory/dev-wiki + upgrading | 2026-05-19 |

## Session Journal (last 5)

- [2026-05-19] [[2026-05-19-phase-8-spec-skill-complete|Phase 8 complete]] -- spec skill + reviewer, two-tier review gate, 55 tests, budget 195/300
- [2026-05-19] [[2026-05-19-phase-7-soul-and-instructions-complete|Phase 7 complete]] -- soul restructured, personal extracted, 48 tests, budget 191/300
- [2026-05-19] [[2026-05-19-phase-5-and-6-complete|Phase 5 & 6 complete]] -- venv bootstrap, HTML reports, v0.2.0 shipped to GitHub
- [2026-05-15] [[2026-05-15-phase-4-dev-wiki-and-memory-integration-complete|Phase 4 complete]] -- 5 tasks done, memory_server vendored, 38 tests
- [2026-05-15] [[2026-05-15-phase-3-distribution-and-polish-complete|Phase 3 complete]] -- 6 tasks done, v0.1.0 tagged, 34 tests

## Cross-References

- Status: [[2026-05-15-codebase-snapshot|Codebase Snapshot 2026-05-15]]
- Phase: [[phase-01-foundation-and-packaging|Phase 1]] -- completed
- Phase: [[phase-02-automated-testing|Phase 2]] -- completed
- Phase: [[phase-03-distribution-and-polish|Phase 3]] -- completed
- Phase: [[phase-04-dev-wiki-and-memory-integration|Phase 4]] -- completed
- Phase: [[phase-05-memory-bootstrap-and-report|Phase 5]] -- completed
- Phase: [[phase-06-ship-and-workflow-assessment|Phase 6]] -- completed
- Phase: [[phase-07-soul-and-instructions-enhancement|Phase 7]] -- completed
- Phase: [[phase-08-spec-skill|Phase 8]] -- completed
- Decision: [[spec-two-tier-review-gate|Spec two-tier review gate]] -- high confidence
- Decision: [[spec-persistence-adaptive|Spec persistence adaptive routing]] -- high confidence
- Decision: [[soul-vs-agents-delineation|Soul vs AGENTS.md delineation]] -- high confidence
