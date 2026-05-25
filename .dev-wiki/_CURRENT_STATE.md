# Current State: nana-dev-kit

> Last updated: 2026-05-25 by /dev-debrief (Phase 40 completed)

## Recommended Next Action

Phase 40 complete (7/7 tasks, all exit criteria verified). Run `/dev-plan` to plan the next phase, or review the delivery report and commit.

## Active Phase

**[[phase-40-install-extraction-anti-pattern-hardening|Phase 40: install.sh Extraction & Anti-Pattern Hardening]]** (status: completed, 100%)

Entry criteria: MET -- Phase 39 completed (6/6 tasks, all exit criteria met)
Exit criteria: ALL MET -- install.sh 318 lines (< 320), zero inline Python, modules.json defines 5 modules, register-settings.py passes tests, PostToolUse normalization complete, phase articles cleaned, make test + make eval 100%, functional smoke invariant codified

Progress: 100% (7/7 tasks done)

## Active Phase Contract

Phase: 40 - install.sh Extraction & Anti-Pattern Hardening
Tasks: 7 (3S + 4M, all completed)
Transition: complete
Abort: n/a

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[install-sh-extraction-approach]] | high | 2026-05-25 |
| [[functional-smoke-invariant-rule]] | high | 2026-05-25 |

## Blockers and Open Questions

(none)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Module-group installer (318 lines, zero inline Python) | 2026-05-25 |
| `modules.json` | Declarative module manifest (5 modules, single source of truth) | 2026-05-25 |
| `scripts/register-settings.py` | Extracted settings.json JSON merge (~120 lines, hooks + mcp subcommands) | 2026-05-25 |
| `templates/.claude/hooks/stale-queue.sh` | PostToolUse stale-queue (dual-field fallback applied) | 2026-05-25 |
| `templates/.claude/hooks/post-commit.sh` | PostToolUse post-commit (dual-field fallback applied) | 2026-05-25 |
| `templates/.claude/skills/MANIFEST` | Skill checksums + descriptions (26 skills) | 2026-05-25 |
| `templates/.claude/skills/spec/SKILL.md` | Spec skill (functional smoke invariant codified) | 2026-05-25 |
| `tests/` | 6 test scripts, ~301 tests (helpers.sh + test_*.sh) | 2026-05-25 |
| `eval/` | 50 eval scenarios in 4 categories (100%) | 2026-05-25 |
| `VERSION` | Semantic version (0.5.0) | 2026-05-23 |

## Session Journal (last 5)

- [2026-05-25] [[2026-05-25-phase-40-install-extraction-complete|Phase 40 complete]] -- install.sh extraction: 542 to 318 lines, zero inline Python, modules.json + register-settings.py, functional smoke invariant codified, ~301 tests, 50/50 eval
- [2026-05-25] [[2026-05-25-phase-39-resilience-health-probes-complete|Phase 39 complete]] -- resilience: 3-state health probe, jq migration complete, PostToolUse .tool_input canonical, /init router, 291 tests, 50/50 eval
- [2026-05-25] [[2026-05-25-phase-38-install-integrity-complete|Phase 38 complete]] -- install integrity: MCP CWD fix, 5 skills added, MultiEdit matchers, scope-check fix, 23 new tests, 283 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-37-ceremony-streamlining-complete|Phase 37 complete]] -- ceremony streamlining: 4-gate to 2-gate, --internal spec, delivery report, auto-commit/push, 259 tests, 47/47 eval
- [2026-05-25] [[2026-05-25-phase-36-hooks-audit-housekeeping-complete|Phase 36 complete]] -- hooks audit, 5 backports + 1 delete, install.sh nested schema + --project-local, nanaclaw PR, 240 tests, 47/47 eval

## Cross-References

- Status: [[2026-05-25-codebase-snapshot|Codebase Snapshot 2026-05-25]]
- Phases 1-40: completed (see index.md)
- Decision: [[install-sh-extraction-approach|install.sh extraction approach]] -- high confidence
- Decision: [[functional-smoke-invariant-rule|Functional smoke invariant]] -- high confidence
- Spec: specs/phase-40-install-extraction-anti-pattern-hardening.md
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
