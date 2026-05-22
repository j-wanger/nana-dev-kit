# Current State: nana-dev-kit

> Last updated: 2026-05-21 by /dev-debrief (Phase 14 complete)

## Recommended Next Action

Run `/dev-plan` to plan Phase 15. Candidates: /spec routing investigation, T0 challenge quality rubric, generalize adversarial pre-generation pattern.

## Active Phase

**[[phase-14-adversarial-thinking-and-review|Phase 14: Adversarial Thinking & Review]]** (status: completed)

Entry criteria: MET (Phase 13 complete, v0.3.0 shipped)
Exit criteria: ALL MET — T0 forces named assumptions, spec has adversarial Step 2.5, companion exists, install.sh copies it, 67 tests pass

Progress: 100% (3/3 tasks done)

## Active Phase Contract

Phase: 14 - Adversarial Thinking & Review (COMPLETED)
Tasks: 3/3 done
Transition: run /dev-plan for Phase 15
Abort: n/a (phase complete)

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[t0-wording-over-structural-subagent]] | high | 2026-05-21 |
| [[adversarial-constraint-generation-as-spec-step]] | high | 2026-05-21 |
| [[personal-profile-template-for-shipping]] | high | 2026-05-20 |

## Blockers and Open Questions

- /spec routing: skill listed in available skills but not recognized as command. Needs investigation. Orthogonal to Phase 14 work. (raised 2026-05-21)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Global installer (7 items + conditional personal copy + memory_server + MCP) | 2026-05-21 |
| `templates/.claude/hooks/session-start.sh` | SessionStart hook (reads 2 sources + gate-check) | 2026-05-19 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `templates/.claude/rules/nana-personal.md` | Personal profile template (generic, no user-specific content) | 2026-05-20 |
| `templates/.claude/rules/file-lifecycle.md` | File lifecycle routing table (MCP-only memory, 4 categories) | 2026-05-19 |
| `templates/.claude/skills/spec/SKILL.md` | Spec creation skill (124 lines, two-tier review gate + adversarial Step 2.5) | 2026-05-21 |
| `templates/.claude/skills/spec/spec-reviewer-prompt.md` | Spec quality reviewer (77 lines, 6 dimensions) | 2026-05-19 |
| `templates/.claude/skills/spec/adversarial-constraints-prompt.md` | Clean-context adversarial constraint generator (41 lines) | 2026-05-21 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `scripts/sync-rules.sh` | AGENTS.md to 4 agent surfaces (writability check) | 2026-05-15 |
| `scripts/generate-report.py` | Package inventory HTML generator | 2026-05-19 |
| `scripts/generate-workflow.py` | Workflow breakdown HTML generator (738 lines) | 2026-05-19 |
| `VERSION` | Semantic version (0.3.0) | 2026-05-20 |
| `.github/workflows/kit-ci.yml` | Kit CI: shellcheck + make test | 2026-05-15 |
| `Makefile` | Project targets (sync-rules, test, report, workflow) | 2026-05-19 |
| `tests/test_install.sh` | Install + venv + MCP + spec + lifecycle + conditional-copy + adversarial tests (23) | 2026-05-21 |
| `tests/test_sync_rules.sh` | Sync correctness + edge-case tests (16) | 2026-05-15 |
| `tests/test_templates.sh` | Protocol + spec + lifecycle + gate-check + soul ceiling + budget + adversarial (28 tests) | 2026-05-21 |
| `templates/AGENTS.md` | Operational contract (Pre-commit sequence) | 2026-05-19 |
| `templates/` | 5-layer scaffolding templates (30+ files) | 2026-05-21 |
| `docs/report.html` | Generated package inventory (v0.3.0) | 2026-05-20 |
| `docs/workflow.html` | Generated workflow breakdown (v0.3.0) | 2026-05-20 |
| `README.md` | Install + usage + /spec + memory/dev-wiki + upgrading | 2026-05-19 |
| `~/.claude/skills/dev-plan/SKILL.md` | Dev planning skill (T0 with output-format forcing) | 2026-05-21 |
| `~/.claude/skills/dev-plan/self-check-checklist.md` | Post-implementation self-check (ceiling 350) | 2026-05-20 |

## Session Journal (last 5)

- [2026-05-21] [[2026-05-21-phase-14-adversarial-thinking-and-review-complete|Phase 14 complete]] -- T0 output-format forcing, adversarial spec Step 2.5, tests 65 -> 67, soul/budget unchanged
- [2026-05-20] [[2026-05-20-phase-13-final-polish-and-ship-complete|Phase 13 complete]] -- H8+H9 heuristics, personal template, ceiling 350, v0.3.0 shipped, tests 63 -> 65, budget 245/300
- [2026-05-20] [[2026-05-20-phase-12-soul-enhancement-memory-harvest-complete|Phase 12 complete]] -- soul warmth + memory-harvest + spec/thinking enforcement, tests 61 -> 63, budget 239/300
- [2026-05-19] [[2026-05-19-phase-11-process-hardening-complete|Phase 11 complete]] -- layered gate enforcement (preventive + detective), tests 59 -> 61, budget 229/300
- [2026-05-19] [[2026-05-19-phase-10-memory-lifecycle-convergence-complete|Phase 10 complete]] -- memory MCP-only, gate enforcement, retro check, budget 229/300

## Cross-References

- Status: [[2026-05-15-codebase-snapshot|Codebase Snapshot 2026-05-15]]
- Phases 1-14: completed (see index.md)
- Decision: [[t0-wording-over-structural-subagent|T0 wording over structural subagent]] -- high confidence
- Decision: [[adversarial-constraint-generation-as-spec-step|Adversarial constraint generation as spec Step 2.5]] -- high confidence
- Decision: [[personal-profile-template-for-shipping|Personal profile template for shipping]] -- high confidence
