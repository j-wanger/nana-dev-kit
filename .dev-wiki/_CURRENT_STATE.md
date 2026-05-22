# Current State: nana-dev-kit

> Last updated: 2026-05-22 by /dev-plan (Phase 17 planned)

## Recommended Next Action

Begin Phase 17 implementation: start with task 1 (detect-loop.sh pure bash PostToolUse hook).

## Active Phase

**[[phase-17-harden|Phase 17: Harden]]** (status: active, ~0%)

Entry criteria: MET (Phase 16 completed, 107 tests passing, all enforcement hooks working)
Exit criteria: detect-loop.sh detects repetitive tool calls, session-start.sh nudges memory consolidation, working-knowledge auto-pruning implemented, tests pass, make test passes

Progress: ~0% (0/4 tasks done)

## Active Phase Contract

Phase: 17 - Harden
Tasks: 4 (3M 1S)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[pure-bash-loop-detection]] | high | 2026-05-22 |
| [[sqlite3-memory-nudge]] | medium | 2026-05-22 |
| [[staged-pruning-stale-queue]] | high | 2026-05-22 |
| [[global-hooks-project-opt-in]] | high | 2026-05-22 |
| [[lightweight-deliverable-check-stop]] | high | 2026-05-22 |

## Blockers and Open Questions

- /spec routing: skill listed in available skills but not recognized as command. Needs investigation. Orthogonal to Phase 17 work. (raised 2026-05-21, carried forward)
- memory.db schema: sqlite3 query depends on knowing the table/column names in vendored memory_server. Unverified — may need discovery during implementation. (raised 2026-05-22)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `install.sh` | Module-group installer (~260 lines, --all/--core-only/--no-python/--dry-run, hooks module) | 2026-05-22 |
| `templates/.claude/hooks/enforce-spec.sh` | PreToolUse spec enforcement hook (58 lines) | 2026-05-22 |
| `templates/.claude/hooks/enforce-loop.sh` | Stop deliverable check hook (85 lines) | 2026-05-22 |
| `templates/.claude/hooks/session-start.sh` | SessionStart hook (2 sources + gate-check + memory guidance + enforcement status) | 2026-05-22 |
| `templates/.claude/hooks/pre-compact.sh` | PreCompact hook (pure bash, reads committed state) | 2026-05-22 |
| `templates/.claude/skills/` | 22 skill dirs + MANIFEST (115 files, ~630KB) | 2026-05-22 |
| `templates/.claude/rules/nana-soul.md` | Cognitive identity (59 lines, 3 protocols + Voice & presence + H8/H9 + memory_search) | 2026-05-20 |
| `templates/.claude/rules/file-lifecycle.md` | File lifecycle routing table (MCP-only memory, 4 categories) | 2026-05-19 |
| `templates/.claude/skills/spec/SKILL.md` | Spec creation skill (124 lines, two-tier review gate + adversarial Step 2.5) | 2026-05-21 |
| `memory_server/` | Vendored MCP memory server (12 .py, 2,373 LOC from nanaclaw) | 2026-05-15 |
| `tests/test_enforce.sh` | Enforcement hook fixture tests (10 tests) | 2026-05-22 |
| `tests/test_install.sh` | Install flag combos, skill dirs, MCP, enforcement assertions (43 tests) | 2026-05-22 |
| `VERSION` | Semantic version (0.3.0) | 2026-05-20 |

## Session Journal (last 5)

- [2026-05-22] [[2026-05-22-phase-16-enforce-the-loop-complete|Phase 16 complete]] -- enforcement hooks (spec gate + deliverable check), global hooks + opt-in, tests 92 -> 107
- [2026-05-22] [[2026-05-22-phase-15-wire-the-lifecycle-complete|Phase 15 complete]] -- monorepo skills (17 dirs), modular install, PreCompact hook, tests 67 -> 92, retro check clean
- [2026-05-21] [[2026-05-21-phase-14-adversarial-thinking-and-review-complete|Phase 14 complete]] -- T0 output-format forcing, adversarial spec Step 2.5, tests 65 -> 67, soul/budget unchanged
- [2026-05-20] [[2026-05-20-phase-13-final-polish-and-ship-complete|Phase 13 complete]] -- H8+H9 heuristics, personal template, ceiling 350, v0.3.0 shipped, tests 63 -> 65, budget 245/300
- [2026-05-20] [[2026-05-20-phase-12-soul-enhancement-memory-harvest-complete|Phase 12 complete]] -- soul warmth + memory-harvest + spec/thinking enforcement, tests 61 -> 63, budget 239/300

## Cross-References

- Status: [[2026-05-22-codebase-snapshot|Codebase Snapshot 2026-05-22]]
- Phases 1-16: completed (see index.md)
- Decision: [[global-hooks-project-opt-in|Global hooks with project-level opt-in]] -- high confidence, accepted
- Decision: [[lightweight-deliverable-check-stop|Lightweight deliverable check at Stop]] -- high confidence, accepted
- Decision: [[python-json-parsing-hooks|Python JSON parsing in hooks]] -- high confidence, accepted
- Retro: Phases 11-15 clean (0 blockers, 0 reversals, 1 low-signal user correction)
