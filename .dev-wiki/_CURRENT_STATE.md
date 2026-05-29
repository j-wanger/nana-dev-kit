# Current State: nana-dev-kit

> Last updated: 2026-05-28 by /dev-debrief (Phase 58 complete, delivery accepted)

## Recommended Next Action

Phase 58 (Fix 2 — Active Domain Research in dev-plan) implementation COMPLETE: 4/4 tasks done, all exit criteria pass. Gap-gated Step 2.7 companion shipped (per-DRQ wiki-query gate, numeric caps, injection-safety, ~1200-char distill, provenance + contradiction-check persistence, fail-open); wired via Read-pointer (SKILL.md 326/350). Residual-delta measurement: +0.5 composite at n=1 (reasoning 3→4) on a research-favorable topic, non-theatrical, kept at Checkpoint 2 (`eval/research-measurement/results.md`). COMPLETED — delivery accepted, committed + pushed. Next: /dev-plan for Phase 59. Candidates: (a) strengthen the n=1 residual-delta with 2-3 more topics incl. a research-poor one; (b) Fix 3 (AGENTS.md reshape); (c) Fix 5 residual (kit-uninitialized session-start nudge); (d) repair the memory venv (sqlite-vec) so `make test` runs end-to-end.

## Active Phase

**[[phase-58-active-domain-research-in-dev-plan|Phase 58: Active Domain Research in dev-plan]]** (status: completed)

Entry criteria: MET (Phase 57 Fix 1 complete; approved spec specs/domain-research-in-dev-plan.md; Phase 55 poses Domain Research Questions but nothing answers them)
Exit criteria: Step 2.7 companion exists + wired via pointer with Lite-skip; SKILL.md ≤350 (test_templates green); companion encodes numeric caps + fail-open + provenance + injection safety; measurement records both branches (covered→skip, uncovered→fires+cited) + numeric residual delta vs Phase-55 baseline (Checkpoint 2 human-gated); make test green + make eval 100%

Progress: 100% (4/4 tasks, delivery accepted, committed)

## Active Phase Contract

Phase: 58 - Active Domain Research in dev-plan
Tasks: 4 (Fix 2 of the Phase 57+ harness-activation roadmap) — all complete
Transition: done (Phase 59 next)
Abort: if research never changes the approach (residual delta ~0/negative), STOP at Checkpoint 2, present honestly, let the user decide keep/trim/cut — do not silently ship a feature that earns nothing.

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[domain-research-dev-plan-step-2-7]] Gap-gated Step 2.7 research (mechanism c); findings injected at named approach decisions; persisted with provenance via capture path | medium | 2026-05-28 |
| [[measure-residual-research-delta]] Measure residual research delta vs Phase-55 baseline, not the headline +1.75; negative result acceptable → keep/trim/cut | high | 2026-05-28 |
| [[single-source-scope-tagged-hook-registration]] One scope-tagged hooks array in modules.json; template generated + drift-tested; marker project-reachable | high | 2026-05-28 |

## Blockers and Open Questions
- Phase 58 residual research delta is +0.5 composite at n=1 (at significance threshold, topic-favorable). Kept Step 2.7 (Checkpoint 2). Strengthen with 2-3 more topics incl. a research-poor one before trusting the number. (raised 2026-05-28)

- Haiku judge inter-run variance: mean ranges 2.97-4.85 across runs. Possibly caused by recommendation length sensitivity. Needs investigation. (raised 2026-05-27)
- **Memory venv broken (FLAGGED, recurring across Phases 56-58):** the memory venv exists but `sqlite-vec` is absent (`libpython3.11.dylib not found` / `no such table: memories_vec`), so `make test` HALTS at `test_memory.sh` locally — masking the 9 non-memory suites unless run individually. CI is unaffected (venv absent → skipped). MCP memory tool path itself works (18 active entries). Fix options: (a) repair/rebuild the venv with sqlite-vec, OR (b) guard test_memory.sh to skip cleanly when sqlite-vec is unavailable (it currently assumes venv-present ⟹ sqlite-vec-present). Candidate Phase 59 maintenance item. (raised 2026-05-28)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `templates/.claude/skills/dev-plan/domain-research-spec.md` | Step 2.7 companion: per-DRQ wiki-query gate, numeric caps, injection-safety, ~1200-char distill, provenance + contradiction-check persistence (wiki capture path), fail-open | 2026-05-28 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Step 2.7 Read-pointer + Lite-skip; Step 6 anti-theater citation bullet; 326/350 lines | 2026-05-28 |
| `eval/research-measurement/results.md` | Residual-delta measurement (functional test of Step 2.7): gate verified both ways, +0.5 composite n=1, Checkpoint 2 | 2026-05-28 |
| `modules.json` | Single canonical scope-tagged `hooks` array (17 project + 1 global) — hook source of truth | 2026-05-28 |
| `scripts/register-settings.py` | Scope-aware hook filtering + `--regenerate` (deterministic template generation) | 2026-05-28 |
| `templates/.claude/settings.json` | GENERATED per-project template (`make template`); drift-tested | 2026-05-28 |
| `templates/.claude/enforce` | Shipped enforce opt-in marker — scaffolds self-enforce | 2026-05-28 |

## Session Journal (last 5)

- [2026-05-28] [[2026-05-28-phase-58-active-domain-research-complete|Phase 58 complete (active domain research in dev-plan — Fix 2)]] -- gap-gated Step 2.7 companion (per-DRQ wiki-query gate, numeric caps, injection-safety, ~1200-char distill, provenance + contradiction-check persist, fail-open) wired via pointer (SKILL.md 326/350); residual-delta measurement +0.5 composite n=1 (reasoning 3→4) on research-favorable topic, non-theatrical, kept at Checkpoint 2; 9/9 non-memory suites green, 54/54 eval; delivery accepted, committed
- [2026-05-28] [[2026-05-28-phase-57-hook-consolidation-enforcement-activation-complete|Phase 57 complete (hook consolidation & enforcement activation — Fix 1)]] -- 3 disagreeing hook sources → 1 scope-tagged modules.json array (17 project + 1 global), template generated + drift-tested, enforce marker project-reachable, enforce-spec FIRES (exit 2) in fresh scaffold; py-init/ts-init marker gap caught by self-check + guarded; 23 block events confirm live enforcement; 10/10 scripts green (CI-equiv)
- [2026-05-28] [[2026-05-28-phase-56-cognitive-activation-memory-design-complete|Phase 56 complete (cognitive activation & memory design — 5-layer classification, actionable cognitive readiness, domain seed)]] -- memory architecture classified (mandatory/automatic/voluntary), cognitive readiness actionable, dev-plan wiki strengthened, 4 domain articles seeded, 54/54 eval
- [2026-05-28] [[2026-05-28-phase-55-harness-activation-overhaul-complete|Phase 55 complete (harness activation overhaul — cascade fix, spec reform, cognitive readiness)]] -- cascade failure fixed (nana-init -> enforce -> all disabled), spec reformed (prescriptive -> reasoning), +40 registration test assertions, cognitive readiness diagnostic, 52/52 eval
- [2026-05-28] [[2026-05-28-phase-54-maintenance-sweep-complete|Phase 54 complete (maintenance sweep — hook bug fixes, stale knowledge removal)]] -- 3 hook bugs fixed (memory-nudge column, session-start DB paths), stale working-knowledge removed, +2 test assertions, 52/52 eval

## Cross-References

- Phases 1-58: 58 completed (Phase 58 delivery accepted) (see index.md)
- Roadmap: Phase 57+ Harness Activation — Fix 1 (hook consolidation) + Fix 2 (domain research in dev-plan) DONE; Fixes 4/5 mostly closed by Phases 55/57; remaining: Fix 3 (AGENTS.md reshape) + Fix 5 residual (kit-uninitialized session-start nudge)
- Spec: Phase 55 used USER OVERRIDE (experiment data replaced prescriptive spec)
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES + 4 domain pattern articles, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 51-55 clean (0 recurring blockers, 0 reversals, 1 documented user override)
