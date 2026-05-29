# Current State: nana-dev-kit

> Last updated: 2026-05-28 by /dev-debrief (Phase 59 complete — CUT verdict; delivery accepted + committed)

## Recommended Next Action

Phase 59 delivered the **CUT** verdict (active web-research injection removed from dev-plan Step 2.7; measured net-negative). All 7 tasks `[x]`, exit criteria MET — **delivered and committed** (delivery gate accepted; phase completed). The measurement (3 new topics, 13 paired runs at n≥3): poor topic delta=−1.0 REAL harm, both rich topics variance-dominated (0.0 / −0.4) — not one n≥3 topic positive; Phase 58's +0.5 sits inside the noise band. Next: `/dev-plan` for Phase 60 — candidates Fix 3 (AGENTS.md reshape), Fix 5 residual (kit-uninitialized session-start nudge), vector-search-default-on design call. **Cooldown note:** 2+ phases this session (58 maintenance + 59) — a fresh session may be warranted before Phase 60.

## Active Phase

**[[phase-59-validate-research-delta|Phase 59: Validate Active-Research Residual Delta]]** (status: completed)

Entry criteria: MET (Phase 58 complete + accepted; approved spec specs/phase-59-validate-research-delta.md; Phase 58 left a +0.5 composite n=1 delta at the significance threshold with unknown variance; user chose to strengthen before the keep/trim/cut call)
Exit criteria: Phase-59 section appended to results.md (Phase-58 preserved) with pre-registration block ordered first; ≥3 per-topic numeric deltas with per-topic mean(A)/mean(B) over ≥3 runs/condition; both richness classes present incl. ≥1 verified research-poor-but-gate-firing topic; gate-fired evidence (search/fetch counts) + poor-topic retrieval quality + load-bearing-vs-decorative recorded; mechanical keep/trim/cut verdict against the pre-registered rule; make test green + make eval 100%; IF trim/cut: companion/SKILL.md edited with test_templates green and SKILL.md ≤350

Progress: 100% (7/7 tasks; T6 fired — verdict was CUT). COMPLETED — delivery accepted, committed.

## Active Phase Contract

Phase: 59 - Validate Active-Research Residual Delta
Tasks: 7 (T1 pre-reg → T2 lock topics → T3 poor topic → T4 rich topics → T5 aggregate+decide → T6 conditional remediation → T7 regression gate)
Transition: done (Phase 60 next)
Abort: (resolved — phase complete; verdict CUT delivered + committed)

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[cut-active-research-step-2-7]] CUT active web-research injection from dev-plan Step 2.7 — measured net-negative (poor −1.0 real harm, rich 0.0/−0.4 variance-dominated, not one n≥3 topic positive); reverses Phase 58 Fix 2; "retrieval over parametric knowledge" doesn't pay where parametric knowledge is already strong | high | 2026-05-28 |
| [[pre-registered-keep-trim-cut-measurement]] Pre-registered, machine-gated measurement; burden of proof on the feature; poor-topic VETO; variance + cost gates; injected_findings_count junk-vs-empty discriminator | high | 2026-05-28 |
| [[measurement-fan-out-as-workflow]] Run the ~21–28-run A/B/judge fan-out via the Workflow tool; poor topic first behind a checkpoint; findings gathered once/topic, reused across B-runs | high | 2026-05-28 |
| [[measure-residual-research-delta]] Measure residual research delta vs Phase-55 baseline, not the headline +1.75; negative result acceptable → keep/trim/cut | high | 2026-05-28 |

## Blockers and Open Questions
- ~~Phase 58 residual research delta is +0.5 composite at n=1 (at significance threshold, topic-favorable). Kept Step 2.7 (Checkpoint 2). Phase 59 resolves the keep/trim/cut call.~~ **RESOLVED 2026-05-28 → CUT.** Strengthened with 3 new topics (13 paired runs at n≥3): poor −1.0 real harm, rich 0.0/−0.4 variance-dominated; the +0.5 sits inside the noise band. Feature removed; dev-plan reverts to Phase-55 behavior. (resolved 2026-05-28)

- OPEN: Active research's value on genuinely novel / post-training-cutoff / proprietary topics (weak parametric knowledge — research's theoretical sweet spot) is UNTESTED. Only well-documented domains were measured. A deliberate keep-for-novel-topics-only is a separate user call. (raised 2026-05-28)

- Haiku/judge inter-run variance: mean ranges 2.97-4.85; recurred in Phase 59 (rich-topic spread 0.79–1.19, both variance-dominated at n=5). Cross-model judge / judge re-calibration remains a standing lever (deferred). (raised 2026-05-27, reconfirmed 2026-05-28)
- ~~Memory venv broken (recurring Phases 56-58): `make test` halted at `test_memory.sh`.~~ **RESOLVED 2026-05-28.** Root cause was twofold: (1) the optional `sqlite-vec` dep was absent from the (healthy, uv-built, Py3.13) venv — the `libpython3.11.dylib` symptom was stale from an older venv; (2) `test_memory.sh` forced `_vec_available=True` and hard-crashed instead of skipping when the *optional* dep was missing. Fixed both: installed `sqlite-vec==0.1.9` locally (full 11/11 run), AND guarded the 4 vec-requiring tests behind a one-time probe so they skip cleanly (FTS5-only 7/7) when sqlite-vec is absent — `make test` can no longer halt on a missing optional dep. (resolved 2026-05-28)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `eval/research-measurement/results.md` | Residual-delta measurement (Phase 58 + 59): functional test of Step 2.7. Phase 59 = pre-registration block + 3-topic results (poor −1.0, rich 0.0/−0.4) + mechanical **CUT** verdict + OUTCOME | 2026-05-28 |
| `templates/.claude/skills/dev-plan/SKILL.md` | dev-plan template; Step 2.7 + Step-6 research-citation bullet REMOVED (CUT); reverts to Phase-55 behavior; 321/350 lines | 2026-05-28 |
| `~~templates/.claude/skills/dev-plan/domain-research-spec.md~~` | DELETED in Phase 59 (CUT) — was the Step 2.7 companion | removed 2026-05-28 |
| `modules.json` | Single canonical scope-tagged `hooks` array (17 project + 1 global) — hook source of truth | 2026-05-28 |
| `scripts/register-settings.py` | Scope-aware hook filtering + `--regenerate` (deterministic template generation) | 2026-05-28 |
| `templates/.claude/settings.json` | GENERATED per-project template (`make template`); drift-tested | 2026-05-28 |
| `templates/.claude/enforce` | Shipped enforce opt-in marker — scaffolds self-enforce | 2026-05-28 |
| `tests/test_memory.sh` | Vec-requiring tests now probe sqlite-vec once + SKIP cleanly (FTS5-only) when absent — `make test` can no longer halt on a missing optional dep | 2026-05-28 |

## Session Journal (last 5)

- [2026-05-28] [[2026-05-28-phase-59-validate-research-delta-cut|Phase 59 → VERDICT CUT (active research removed from dev-plan Step 2.7)]] -- strengthened Phase 58's n=1 +0.5 with 3 new wiki-uncovered topics (13 paired within-round runs at n≥3, judge-v2, escalation + variance gate). Poor topic (commit-convention) delta=−1.0 **REAL harm** (findings anchored design to the generic answer + crowded out context reasoning); rich topics (retry/backoff 0.0, ledger-isolation −0.4) both variance-dominated at n=5; not one n≥3 topic positive; the +0.5 sits inside the noise band. Mechanical rule (rich no real positive + poor real-negative VETO) ⇒ **CUT**. Removed Step 2.7 + Step-6 citation bullet from SKILL.md (326→321), deleted domain-research-spec.md. test_templates 169/169, make test green, eval 54/54. Pre-registered measurement caught an already-SHIPPED n=1 false positive. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-memory-venv-fix-make-test-green|Maintenance: memory venv fix — make test green end-to-end]] -- post-Phase-58 follow-on (commit `74da87a`). `make test` was halting at `test_memory.sh`; root cause twofold (optional `sqlite-vec` absent from venv + test hard-failing instead of skipping). Fixed both: installed `sqlite-vec==0.1.9` locally + guarded vec tests to skip cleanly (FTS5-only). Verified 11/11 vec-present, 7/7 vec-absent (exit 0). Durable lesson: optional-dep tests must skip, not assume-and-halt. Review gate skipped (0 phase tasks, single proven change)
- [2026-05-28] [[2026-05-28-phase-58-active-domain-research-complete|Phase 58 complete (active domain research in dev-plan — Fix 2)]] -- gap-gated Step 2.7 companion (per-DRQ wiki-query gate, numeric caps, injection-safety, ~1200-char distill, provenance + contradiction-check persist, fail-open) wired via pointer (SKILL.md 326/350); residual-delta measurement +0.5 composite n=1 (reasoning 3→4) on research-favorable topic, non-theatrical, kept at Checkpoint 2; 9/9 non-memory suites green, 54/54 eval; delivery accepted, committed
- [2026-05-28] [[2026-05-28-phase-57-hook-consolidation-enforcement-activation-complete|Phase 57 complete (hook consolidation & enforcement activation — Fix 1)]] -- 3 disagreeing hook sources → 1 scope-tagged modules.json array (17 project + 1 global), template generated + drift-tested, enforce marker project-reachable, enforce-spec FIRES (exit 2) in fresh scaffold; py-init/ts-init marker gap caught by self-check + guarded; 23 block events confirm live enforcement; 10/10 scripts green (CI-equiv)
- [2026-05-28] [[2026-05-28-phase-56-cognitive-activation-memory-design-complete|Phase 56 complete (cognitive activation & memory design — 5-layer classification, actionable cognitive readiness, domain seed)]] -- memory architecture classified (mandatory/automatic/voluntary), cognitive readiness actionable, dev-plan wiki strengthened, 4 domain articles seeded, 54/54 eval

## Cross-References

- Phases 1-59: 59 completed; Phase 59 = CUT verdict (delivery accepted + committed) (see index.md)
- Maintenance (post-Phase-58, commit `74da87a`): memory venv fix — `make test` green end-to-end; [[guard-optional-dep-tests]] (optional-dep tests skip, never assume-and-halt). Closes the recurring Phases 56-58 "make test halts" blocker.
- Roadmap: Phase 57+ Harness Activation — Fix 1 (hook consolidation) DONE; **Fix 2 (domain research in dev-plan) shipped Phase 58 → measured net-negative Phase 59 → CUT** (the pre-registered measurement caught an n=1 false positive); Fixes 4/5 mostly closed by Phases 55/57; remaining: Fix 3 (AGENTS.md reshape) + Fix 5 residual (kit-uninitialized session-start nudge) + vector-search-default-on design call
- Spec: Phase 55 used USER OVERRIDE (experiment data replaced prescriptive spec)
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES + 4 domain pattern articles, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 51-55 clean (0 recurring blockers, 0 reversals, 1 documented user override)
