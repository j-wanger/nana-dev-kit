# Current State: nana-dev-kit

> Last updated: 2026-05-22 by /dev-plan (Phase 16 planned)

## Recommended Next Action

Begin Phase 16 implementation. Task 1: enforce-spec.sh — PreToolUse hook for spec enforcement.

## Active Phase

**[[phase-16-enforce-the-loop|Phase 16: Enforce the Loop]]** (status: active)

Entry criteria: MET (Phase 15 complete, spec pending, approach approved, plan reviewed, tasks approved)
Exit criteria: enforce-spec.sh blocks writes without approved spec, enforce-loop.sh checks deliverables at Stop, 10 enforcement tests pass, install.sh distributes hooks globally, session-start reports enforcement status

Progress: ~0% (0/6 tasks done)

## Active Phase Contract

Phase: 16 - Enforce the Loop
Tasks: 6 (4M 2S)
Transition: continue (same session or new)
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[global-hooks-project-opt-in]] | medium | 2026-05-22 |
| [[lightweight-deliverable-check-stop]] | medium | 2026-05-22 |
| [[python-json-parsing-hooks]] | medium | 2026-05-22 |
| [[monorepo-skill-distribution]] | high | 2026-05-21 |
| [[import-source-canonical-installed]] | high | 2026-05-21 |

## Blockers and Open Questions

- /spec routing: skill listed in available skills but not recognized as command. Needs investigation. Orthogonal to Phase 16 work. (raised 2026-05-21, carried forward)
- Claude Code hook JSON schema not formally documented — relying on reverse-engineering from existing hooks. Low risk (pattern is stable). (raised 2026-05-22)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Module-group installer (~240 lines, --all/--core-only/--no-python/--dry-run) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST (115 files, ~630KB) | 2026-05-22 |
| `templates/.claude/hooks/session-start.sh` | SessionStart hook (2 sources + gate-check + memory_search guidance) | 2026-05-22 |
| `templates/.claude/hooks/pre-compact.sh` | PreCompact hook (pure bash, reads committed state) | 2026-05-22 |
| `templates/.claude/skills/MANIFEST` | Sorted file listing + md5 checksums (114 entries) | 2026-05-22 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `templates/.claude/rules/nana-personal.md` | Personal profile template (generic, no user-specific content) | 2026-05-20 |
| `templates/.claude/rules/file-lifecycle.md` | File lifecycle routing table (MCP-only memory, 4 categories) | 2026-05-19 |
| `templates/.claude/skills/spec/SKILL.md` | Spec creation skill (124 lines, two-tier review gate + adversarial Step 2.5) | 2026-05-21 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `scripts/sync-rules.sh` | AGENTS.md to 4 agent surfaces (writability check) | 2026-05-15 |
| `VERSION` | Semantic version (0.3.0) | 2026-05-20 |
| `tests/test_install.sh` | Install flag combos, skill dirs, MCP, conditional-copy tests | 2026-05-22 |
| `tests/test_templates.sh` | Protocol + spec + budget + imported skills spot-checks | 2026-05-22 |

## Session Journal (last 5)

- [2026-05-22] [[2026-05-22-phase-15-wire-the-lifecycle-complete|Phase 15 complete]] -- monorepo skills (17 dirs), modular install, PreCompact hook, tests 67 -> 92, retro check clean
- [2026-05-21] [[2026-05-21-phase-14-adversarial-thinking-and-review-complete|Phase 14 complete]] -- T0 output-format forcing, adversarial spec Step 2.5, tests 65 -> 67, soul/budget unchanged
- [2026-05-20] [[2026-05-20-phase-13-final-polish-and-ship-complete|Phase 13 complete]] -- H8+H9 heuristics, personal template, ceiling 350, v0.3.0 shipped, tests 63 -> 65, budget 245/300
- [2026-05-20] [[2026-05-20-phase-12-soul-enhancement-memory-harvest-complete|Phase 12 complete]] -- soul warmth + memory-harvest + spec/thinking enforcement, tests 61 -> 63, budget 239/300
- [2026-05-19] [[2026-05-19-phase-11-process-hardening-complete|Phase 11 complete]] -- layered gate enforcement (preventive + detective), tests 59 -> 61, budget 229/300

## Cross-References

- Status: [[2026-05-22-codebase-snapshot|Codebase Snapshot 2026-05-22]]
- Phases 1-15: completed (see index.md)
- Decision: [[monorepo-skill-distribution|Monorepo Skill Distribution]] -- high confidence, accepted
- Decision: [[import-source-canonical-installed|Import Source -- Canonical Installed Versions]] -- high confidence, accepted
- Retro: Phases 11-15 clean (0 blockers, 0 reversals, 1 low-signal user correction)
