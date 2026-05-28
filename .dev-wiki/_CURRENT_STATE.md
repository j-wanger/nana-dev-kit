# Current State: nana-dev-kit

> Last updated: 2026-05-27 by /dev-debrief (Phase 53 completed)

## Recommended Next Action

Run `/dev-plan` when ready for next phase. Candidates: fix memory-nudge.sh bugs (hooks maintenance), run HEU-011 under IRON-RULES condition (counterweight eval), or update working-knowledge entries corrected by Phase 53 findings.

## Active Phase

**[[phase-53-open-questions|Phase 53: Open Questions — IRON-004 Scoping, Meta-Decision Expansion, MCP Memory]]** (status: completed)

Entry criteria: MET (Phase 52 complete, open questions documented)
Exit criteria: All 7 exit criteria met — 3 investigations documented, HEU-011 drafted + eval'd, make test + make eval pass

Progress: 100% (6/6 tasks done)

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
| `wiki/heuristics/HEU-011-capacity-multiplier.md` | 16th heuristic article (capacity-multiplier for meta-decisions) | 2026-05-27 |
| `.dev-wiki/articles/decisions/mcp-memory-diagnosis.md` | MCP memory data loss root cause (CWD mismatch + probe bugs) | 2026-05-27 |
| `.dev-wiki/articles/decisions/phase-53-investigation-findings.md` | All 3 investigation findings consolidated | 2026-05-27 |
| `eval/reasoning/selective/ground-truth.json` | Manual heuristic-to-scenario mapping (25 scenarios, HEU-011 added) | 2026-05-27 |
| `tests/test_heuristic_evolution.sh` | 11 assertions covering counters, lifecycle, dashboard, HEU-011 | 2026-05-27 |
| `scripts/heuristic-dashboard.py` | Terminal table of heuristic counter stats (~70 lines) | 2026-05-27 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Step 6.5 with counter + lifecycle pointers (317/350 lines) | 2026-05-27 |

## Session Journal (last 5)

- [2026-05-27] [[2026-05-27-phase-53-open-questions-complete|Phase 53 complete (open questions — IRON-004 scoping, HEU-011, MCP memory)]] -- 3 investigations resolved, HEU-011 drafted (1/25 match), clean baseline solves 020 (corrects Phase 50 claim), MCP CWD root cause, +3 test assertions (11 total), 52/52 eval
- [2026-05-27] [[2026-05-27-phase-52-heuristic-evolution-complete|Phase 52 complete (heuristic evolution — counter scoring, deprecation lifecycle, dashboard)]] -- heuristic-counter-update.md, heuristic-lifecycle.md, SKILL.md pointer (317/350), dashboard + make target, SCHEMA.md lifecycle, 8 tests, 2 eval scenarios (52/52 100%), roadmap Phase 7 DONE, 1 decision confirmed
- [2026-05-27] [[2026-05-27-phase-51-prompt-type-hooks-complete|Phase 51 complete (heuristic-informed runtime judging)]] -- ground-truth.json (25 scenarios, 84% coverage), heuristic-matcher.md, heuristic-judge-prompt.md, SKILL.md Step 6.5 integration, --selective mode, 2 decisions (1 upgraded), +6 test assertions, 96/96 companions, 50/50 eval
- [2026-05-27] [[2026-05-27-phase-50-eval-advancement-complete|Phase 50 complete (length-sensitivity negative, Haiku judge passes, harder scenarios 15/15)]] -- 3 experiments: filler text discarded by model, Haiku passes calibration (mean=4.07, 37.8% below 5), 5 harder scenarios at ceiling, two-phase eval methodology discovered, 1 decision, make test + make eval pass
- [2026-05-27] [[2026-05-27-phase-49-conditional-heuristic-injection-complete|Phase 49 complete (negative result — conditional injection zero delta)]] -- 3-type taxonomy, 20 scenario_type fields, conditional template, --conditional mode, 3-condition fresh eval, stochastic interference did not reproduce, 0 new decisions (3 existing confirmed), 162+ tests, 50/50 eval

## Cross-References

- Status: [[2026-05-27-codebase-snapshot|Codebase Snapshot 2026-05-27]]
- Phases 1-53: 53 completed (see index.md)
- Decision: [[verification-first-iron004|Verification-First IRON-004]] -- medium, Phase 53
- Decision: [[counter-attribution-uniform-global-verdict|Counter Attribution — Uniform Global Verdict]] -- medium (confirmed), Phase 52
- Spec: specs/phase-53-open-questions.md
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES (HEU-011 added), heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 46-50 clean (0 recurring blockers, 0 reversals, 2 documented user overrides)
