# Current State: nana-dev-kit

> Last updated: 2026-05-28 by /dev-plan (Phase 57 planned)

## Recommended Next Action

Phase 57 (Fix 1) implementation complete and verified — 10/10 test scripts green under CI conditions. Delivery report pending acceptance → on accept, commit + push. Next: /dev-plan for Phase 58 (Fix 5 nana-init discoverability is the other plumbing item; Fix 2 domain-research-in-dev-plan is the +1.75 high-impact item).

## Active Phase

**[[phase-57-hook-consolidation-and-enforcement-activation|Phase 57: Hook Consolidation and Enforcement Activation]]** (status: completed)

Entry criteria: MET (Phase 56 completed; C/D experiment root-caused enforcement to never-fired hooks; registry audit confirmed 3 disagreeing sources + global-marker gap)
Exit criteria: One scope-tagged hook source in modules.json; template generated + drift-tested; marker project-reachable; enforce-spec fires (exit 2) in a fresh scaffold; make test green

Progress: 100% (5/5 tasks, pending delivery gate)

## Active Phase Contract

Phase: 57 - Hook Consolidation and Enforcement Activation
Tasks: 5 (Fix 1 of the Phase 57+ harness-activation roadmap)
Transition: continue
Abort: if Claude Code double-fires registered hooks harmfully, STOP and reconsider scope project-only + kit migration; if firing test passes only with the global marker, the marker fix is incomplete.

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[single-source-scope-tagged-hook-registration]] One scope-tagged hooks array in modules.json; template generated + drift-tested; marker project-reachable | high | 2026-05-28 |
| [[memory-architecture-classification]] Memory architecture 5-layer classification (mandatory/automatic/voluntary) | high | 2026-05-28 |

## Blockers and Open Questions

- Haiku judge inter-run variance: mean ranges 2.97-4.85 across runs. Possibly caused by recommendation length sensitivity. Needs investigation. (raised 2026-05-27)
- Memory server venv broken: libpython3.11.dylib not found (pre-existing, unrelated to Phase 56). (raised 2026-05-28)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `modules.json` | Single canonical scope-tagged `hooks` array (17 project + 1 global) — hook source of truth | 2026-05-28 |
| `scripts/register-settings.py` | Scope-aware hook filtering + `--regenerate` (deterministic template generation) | 2026-05-28 |
| `templates/.claude/settings.json` | GENERATED per-project template (`make template`); drift-tested | 2026-05-28 |
| `templates/.claude/enforce` | Shipped enforce opt-in marker — scaffolds self-enforce | 2026-05-28 |
| `templates/.claude/hooks/enforce-{spec,loop,memory}.sh` | Marker check now project `.claude/enforce` OR global (backward-compatible) | 2026-05-28 |
| `tests/test_settings_template.sh` | Drift + firing (exit 2) + backward-compat + scaffolder-marker guard | 2026-05-28 |
| `install.sh` | Scope-aware global vs --project-local hook install; --project-local creates marker | 2026-05-28 |

## Session Journal (last 5)

- [2026-05-28] [[2026-05-28-phase-57-hook-consolidation-enforcement-activation-complete|Phase 57 complete (hook consolidation & enforcement activation — Fix 1)]] -- 3 disagreeing hook sources → 1 scope-tagged modules.json array (17 project + 1 global), template generated + drift-tested, enforce marker project-reachable, enforce-spec FIRES (exit 2) in fresh scaffold; py-init/ts-init marker gap caught by self-check + guarded; 23 block events confirm live enforcement; 10/10 scripts green (CI-equiv)
- [2026-05-28] [[2026-05-28-phase-56-cognitive-activation-memory-design-complete|Phase 56 complete (cognitive activation & memory design — 5-layer classification, actionable cognitive readiness, domain seed)]] -- memory architecture classified (mandatory/automatic/voluntary), cognitive readiness actionable, dev-plan wiki strengthened, 4 domain articles seeded, 54/54 eval
- [2026-05-28] [[2026-05-28-phase-55-harness-activation-overhaul-complete|Phase 55 complete (harness activation overhaul — cascade fix, spec reform, cognitive readiness)]] -- cascade failure fixed (nana-init -> enforce -> all disabled), spec reformed (prescriptive -> reasoning), +40 registration test assertions, cognitive readiness diagnostic, 52/52 eval
- [2026-05-28] [[2026-05-28-phase-54-maintenance-sweep-complete|Phase 54 complete (maintenance sweep — hook bug fixes, stale knowledge removal)]] -- 3 hook bugs fixed (memory-nudge column, session-start DB paths), stale working-knowledge removed, +2 test assertions, 52/52 eval
- [2026-05-27] [[2026-05-27-phase-53-open-questions-complete|Phase 53 complete (open questions — IRON-004 scoping, HEU-011, MCP memory)]] -- 3 investigations resolved, HEU-011 drafted (1/25 match), clean baseline solves 020, MCP CWD root cause, +3 test assertions, 52/52 eval

## Cross-References

- Phases 1-57: 56 completed + Phase 57 implementation complete (delivery pending) (see index.md)
- Roadmap: Phase 57+ Harness Activation — Fix 1 (hook consolidation) DONE; Fixes 2-5 remain (domain research in dev-plan, AGENTS.md reshape, cognitive-readiness actionable, nana-init discoverability)
- Spec: Phase 55 used USER OVERRIDE (experiment data replaced prescriptive spec)
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES + 4 domain pattern articles, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 51-55 clean (0 recurring blockers, 0 reversals, 1 documented user override)
