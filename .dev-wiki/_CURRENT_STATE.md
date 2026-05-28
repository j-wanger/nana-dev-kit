# Current State: nana-dev-kit

> Last updated: 2026-05-27 by /dev-plan (Phase 53 planned)

## Recommended Next Action

Start Phase 53 implementation. Task 1: MCP Memory Diagnosis (S, orthogonal quick diagnostic). Back up DB files, check CWD config, document root cause.

## Active Phase

**[[phase-53-open-questions|Phase 53: Open Questions — IRON-004 Scoping, Meta-Decision Expansion, MCP Memory]]** (status: active)

Entry criteria: MET (Phase 52 complete, open questions documented)
Exit criteria: 3 investigations documented with findings, HEU-011 drafted + eval'd, make test + make eval pass

Progress: ~0% (0/6 tasks done)

## Active Phase Contract

Phase: 53 - Open Questions: IRON-004 Scoping, Meta-Decision Expansion, MCP Memory
Tasks: 6 (see tasks.md)
Transition: continue
Abort: if blocked >3 attempts, ask user: skip or abort

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[verification-first-iron004]] | medium | 2026-05-27 |
| [[counter-attribution-uniform-global-verdict]] | medium (confirmed) | 2026-05-27 |

## Blockers and Open Questions

- Haiku judge inter-run variance: mean ranges 2.97-4.85 across runs. Possibly caused by recommendation length sensitivity. Needs investigation. (raised 2026-05-27)
- [CLOSED Phase 53] IRON-004 scoping for deadline-constrained scenarios: resolved by selective injection (Phase 51). Ground-truth maps 015 to IRON-005 only. No IRON-004 edit needed.
- [CLOSED Phase 53] Meta-decision scenarios (020): HEU-011 capacity-multiplier heuristic drafted. Clean baseline already solves 020 correctly; IRON-RULES-condition eval deferred.
- [CLOSED Phase 53] MCP memory data loss: root cause is CWD mismatch + health probe bugs. Phase 19-48 entries irrecoverable. See mcp-memory-diagnosis.md.
- session-start.d/memory-nudge.sh has two bugs: wrong DB path + wrong column name. Fix in future phase. (raised 2026-05-27)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `templates/.claude/skills/dev-plan/heuristic-counter-update.md` | Counter attribution rules (helpful/harmful updates) | 2026-05-27 |
| `templates/.claude/skills/dev-plan/heuristic-lifecycle.md` | Deprecation lifecycle transitions (active->under-review) | 2026-05-27 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Step 6.5 with counter + lifecycle pointers (317/350 lines) | 2026-05-27 |
| `scripts/heuristic-dashboard.py` | Terminal table of heuristic counter stats (~70 lines) | 2026-05-27 |
| `wiki/heuristics/SCHEMA.md` | Heuristic schema with lifecycle transitions | 2026-05-27 |
| `tests/test_heuristic_evolution.sh` | 8 assertions covering counters, lifecycle, dashboard | 2026-05-27 |
| `eval/reasoning/selective/ground-truth.json` | Manual heuristic-to-scenario mapping (25 scenarios, 84% coverage) | 2026-05-27 |

## Session Journal (last 5)

- [2026-05-27] [[2026-05-27-phase-52-heuristic-evolution-complete|Phase 52 complete (heuristic evolution — counter scoring, deprecation lifecycle, dashboard)]] -- heuristic-counter-update.md, heuristic-lifecycle.md, SKILL.md pointer (317/350), dashboard + make target, SCHEMA.md lifecycle, 8 tests, 2 eval scenarios (52/52 100%), roadmap Phase 7 DONE, 1 decision confirmed
- [2026-05-27] [[2026-05-27-phase-51-prompt-type-hooks-complete|Phase 51 complete (heuristic-informed runtime judging)]] -- ground-truth.json (25 scenarios, 84% coverage), heuristic-matcher.md, heuristic-judge-prompt.md, SKILL.md Step 6.5 integration, --selective mode, 2 decisions (1 upgraded), +6 test assertions, 96/96 companions, 50/50 eval
- [2026-05-27] [[2026-05-27-phase-50-eval-advancement-complete|Phase 50 complete (length-sensitivity negative, Haiku judge passes, harder scenarios 15/15)]] -- 3 experiments: filler text discarded by model, Haiku passes calibration (mean=4.07, 37.8% below 5), 5 harder scenarios at ceiling, two-phase eval methodology discovered, 1 decision, make test + make eval pass
- [2026-05-27] [[2026-05-27-phase-49-conditional-heuristic-injection-complete|Phase 49 complete (negative result — conditional injection zero delta)]] -- 3-type taxonomy, 20 scenario_type fields, conditional template, --conditional mode, 3-condition fresh eval, stochastic interference did not reproduce, 0 new decisions (3 existing confirmed), 162+ tests, 50/50 eval
- [2026-05-27] [[2026-05-27-phase-48-trace-collection-pattern-analysis-complete|Phase 48 complete (stochastic interference — negative result)]] -- LOO ablation on 5 IRON RULES x 3 training scenarios (~75 invocations), stochastic interference finding, IRON-001 load-bearing, attribution matrix + selection criteria, 5 decisions (4 upgraded, 1 new), +5 test assertions, 162+ tests, 50/50 eval

## Cross-References

- Status: [[2026-05-27-codebase-snapshot|Codebase Snapshot 2026-05-27]]
- Phases 1-52: 52 completed (see index.md)
- Decision: [[counter-attribution-uniform-global-verdict|Counter Attribution — Uniform Global Verdict]] -- medium (confirmed), Phase 52
- Decision: [[fire-and-forget-heuristic-judge|Fire-and-Forget Heuristic Judge]] -- high confidence, Phase 51
- Spec: specs/phase-52-heuristic-evolution.md
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 10 heuristics + 5 IRON RULES, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 46-50 clean (0 recurring blockers, 0 reversals, 2 documented user overrides)
