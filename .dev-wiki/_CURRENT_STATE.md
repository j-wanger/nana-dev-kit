# Current State: nana-dev-kit

> Last updated: 2026-05-27 by /dev-debrief (Phase 51 completed)

## Recommended Next Action

Phase 51 complete. Run /dev-plan to plan Phase 52. Candidates: heuristic evolution scoring (helpful/harmful counters), domain-gap heuristic seeding (4 blind-spot scenarios), runtime validation of LLM trigger matcher.

## Active Phase

**[[phase-51-prompt-type-hooks|Phase 51: Prompt-Type Hooks — Heuristic-Informed Runtime Judging]]** (status: completed)

Entry criteria: MET -- Phase 50 completed (8/8 tasks done). 15 heuristic articles with triggers exist. Reasoning eval with 25 scenarios and judge v2 ready.
Exit criteria: ALL MET -- heuristic-matcher.md, heuristic-judge-prompt.md, SKILL.md Step 6.5, ground-truth.json (25 entries), --selective mode, selective/results.json, phase-51-analysis.md, make test + make eval pass.

Progress: 100% (7/7 tasks done)

## Active Phase Contract

Phase: 51 - Prompt-Type Hooks — Heuristic-Informed Runtime Judging
Tasks: 7 (5M + 2S)
Transition: continue
Abort: If blocked >3 attempts, ask user: skip or abort. Matcher checkpoint at Task 1 (if most scenarios have 0 matches, concept is degenerate).

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[fire-and-forget-heuristic-judge]] | high | 2026-05-27 |
| [[ground-truth-first-falsification]] | medium | 2026-05-27 |

## Blockers and Open Questions

- Haiku judge inter-run variance: mean ranges 2.97-4.85 across runs. Possibly caused by recommendation length sensitivity. Needs investigation. (raised 2026-05-27)
- IRON-004 scoping for deadline-constrained scenarios: "simpler system wins" overrides domain reasoning on 015. (raised 2026-05-27)
- Whether "meta-decision" scenarios (like 020) can be systematically expanded for capacity-multiplier reasoning. (raised 2026-05-27)
- MCP memory data loss: 0 entries at Phase 50 start despite population in prior phases. Not investigated this phase. (raised 2026-05-27)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `templates/.claude/skills/dev-plan/heuristic-matcher.md` | Trigger matching subagent prompt (60 lines, LLM + domain-tag) | 2026-05-27 |
| `templates/.claude/skills/dev-plan/heuristic-judge-prompt.md` | Plan-adapted judge (57 lines, Score N/10 + Verdict) | 2026-05-27 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Step 6.5 with heuristic judge integration (316/350 lines) | 2026-05-27 |
| `eval/reasoning/selective/ground-truth.json` | Manual heuristic-to-scenario mapping (25 scenarios, 84% coverage) | 2026-05-27 |
| `eval/reasoning/selective/results.json` | Matching coverage analysis | 2026-05-27 |
| `eval/reasoning/run-eval.py` | Reasoning eval with 9 modes (--selective added) | 2026-05-27 |
| `eval/reasoning/traces/phase-51-analysis.md` | Matching analysis: coverage, blind spots, budget compliance | 2026-05-27 |

## Session Journal (last 5)

- [2026-05-27] [[2026-05-27-phase-51-prompt-type-hooks-complete|Phase 51 complete (heuristic-informed runtime judging)]] -- ground-truth.json (25 scenarios, 84% coverage), heuristic-matcher.md, heuristic-judge-prompt.md, SKILL.md Step 6.5 integration, --selective mode, 2 decisions (1 upgraded), +6 test assertions, 96/96 companions, 50/50 eval
- [2026-05-27] [[2026-05-27-phase-50-eval-advancement-complete|Phase 50 complete (length-sensitivity negative, Haiku judge passes, harder scenarios 15/15)]] -- 3 experiments: filler text discarded by model, Haiku passes calibration (mean=4.07, 37.8% below 5), 5 harder scenarios at ceiling, two-phase eval methodology discovered, 1 decision, make test + make eval pass
- [2026-05-27] [[2026-05-27-phase-49-conditional-heuristic-injection-complete|Phase 49 complete (negative result — conditional injection zero delta)]] -- 3-type taxonomy, 20 scenario_type fields, conditional template, --conditional mode, 3-condition fresh eval, stochastic interference did not reproduce, 0 new decisions (3 existing confirmed), 162+ tests, 50/50 eval
- [2026-05-27] [[2026-05-27-phase-48-trace-collection-pattern-analysis-complete|Phase 48 complete (stochastic interference — negative result)]] -- LOO ablation on 5 IRON RULES x 3 training scenarios (~75 invocations), stochastic interference finding, IRON-001 load-bearing, attribution matrix + selection criteria, 5 decisions (4 upgraded, 1 new), +5 test assertions, 162+ tests, 50/50 eval
- [2026-05-27] [[2026-05-27-phase-47-self-dialogue-in-dev-plan-complete|Phase 47 complete (negative result)]] -- self-dialogue in dev-plan: dual-condition eval (inline net negative, subagent net neutral), production companion + Step 6.0.5 wired, 1 decision, +4 test assertions, ~158 tests, 50/50 eval

## Cross-References

- Status: [[2026-05-27-codebase-snapshot|Codebase Snapshot 2026-05-27]]
- Phases 1-51: 51 completed (see index.md)
- Decision: [[fire-and-forget-heuristic-judge|Fire-and-Forget Heuristic Judge]] -- high confidence, Phase 51
- Decision: [[ground-truth-first-falsification|Ground-Truth-First Falsification]] -- high confidence (upgraded from medium), Phase 51
- Spec: specs/phase-51-prompt-type-hooks.md
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement]] -- 7/7 phases done (Phase 50 eval advancement complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 10 heuristics + 5 IRON RULES, heuristic judge + matcher wired at Step 6.5
- Retro: Phases 46-50 clean (0 recurring blockers, 0 reversals, 2 documented user overrides)
