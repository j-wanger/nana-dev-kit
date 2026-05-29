# Current State: nana-dev-kit

> Last updated: 2026-05-29 by /dev-debrief (Phase 60 complete — Fix 3 + Fix 5; delivery accepted + committed; harness-activation roadmap CLOSED)

## Recommended Next Action

Phase 60 delivered: the two remaining harness-activation residuals, both DETERMINISTIC (no judge-eval). **Fix 3** — `templates/AGENTS.md` 86→82 lines (deduped the lint/type/test triplet, Hard Rules moved to lead, line-cap codified as a `test_templates.sh` assertion). **Fix 5** — `cognitive-readiness.sh` nudges `run /nana-init` when `.dev-wiki/` is missing (and short-circuits the moot per-component noise — a net reduction), verified by a bidirectional firing test. 3/3 tasks, exit criteria MET, self-check clean, review gate 9/10 accept, `make test` 11 scripts green, `make eval` 54/54. **The Phase 57+ harness-activation roadmap (Fixes 1–5) is now CLOSED.** Next: `/dev-plan` for Phase 61 — the two remaining substantive roadmap items are **vector-search-default-on** (does 91%→~95% recall justify the sqlite-vec dep that broke make test in P56–58?) and **gap 4.1 language-agnostic core** (factor py-* out; AGENTS.md is hard-Python). Plus a possible research phase on the unverified always-loaded-budget claim (AGENTS.md:84).

## Active Phase

**[[phase-60-harness-activation-residuals|Phase 60: Harness Activation Residuals]]** (status: completed)

Entry criteria: MET (Phase 59 complete + committed (CUT); approved spec specs/phase-60-harness-activation-residuals.md, reviewer 9/10; user combined Fix 3 + Fix 5 and waived the direction gate — closes the Phase 57+ harness-activation roadmap)
Exit criteria: ALL MET — templates/AGENTS.md 82 lines (<86) with ruff + pytest lines each 1×, Hard Rules before Conventions, line-cap assertion (≤84) added, placeholders + 'Pre-commit sequence' preserved; cognitive-readiness.sh nudges /nana-init when .dev-wiki/ absent + silent when present (bidirectional firing test wired into make test); make test green + make eval 54/54 (100%)

Progress: 100% (3/3 tasks). COMPLETED — delivery accepted, committed.

## Active Phase Contract

Phase: 60 - Harness Activation Residuals
Tasks: 3 (T1 Fix 5 nudge → T2 Fix 3 AGENTS.md trim → T3 integration regression gate)
Transition: done (Phase 61 next)
Abort: (resolved — phase complete; both fixes met deterministic success criteria, delivered + committed)

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[deterministic-success-over-eval-ceremony]] For a deterministic/mechanical harness change (dedup, reorder, conditional advisory line), the rigorous validator is structural assertions + bidirectional firing tests — NOT a judge A/B eval. A judge adds variance to launder, not signal, where output is byte-identical for identical inputs. Subtraction test applies to validation ceremony too. | high | 2026-05-29 |
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
| `templates/AGENTS.md` | Scaffolded-project conventions; Phase 60 trim — 82 lines, deduped command triplet, Hard Rules lead, line-cap test-enforced | 2026-05-29 |
| `templates/.claude/hooks/session-start.d/cognitive-readiness.sh` | Harness-readiness diagnostic; Phase 60 — nudges /nana-init when .dev-wiki/ absent (short-circuits moot probes), shared `_nana_kit_summary` helper | 2026-05-29 |
| `tests/test_cognitive_readiness.sh` | NEW (Phase 60) — bidirectional firing test for the kit-uninitialized nudge (fires when uninitialized, silent when initialized); wired into make test (11th script) | 2026-05-29 |
| `tests/test_templates.sh` | +4 AGENTS.md asserts (Phase 60): dedup ×2, line-cap ≤84, salience ordering | 2026-05-29 |
| `eval/research-measurement/results.md` | Residual-delta measurement (Phase 58 + 59): functional test of (now-removed) Step 2.7; mechanical **CUT** verdict | 2026-05-28 |
| `templates/.claude/skills/dev-plan/SKILL.md` | dev-plan template; Step 2.7 REMOVED (CUT); reverts to Phase-55 behavior; 321/350 lines | 2026-05-28 |
| `modules.json` | Single canonical scope-tagged `hooks` array (17 project + 1 global) — hook source of truth | 2026-05-28 |
| `tests/test_memory.sh` | Vec-requiring tests probe sqlite-vec once + SKIP cleanly (FTS5-only) when absent | 2026-05-28 |

## Session Journal (last 5)

- [2026-05-29] [[2026-05-29-phase-60-harness-activation-residuals-complete|Phase 60 complete — Harness Activation Residuals (AGENTS.md trim + kit-uninitialized nudge)]] -- closed the Phase 57+ harness-activation roadmap (Fixes 1–5 all done). **Fix 3:** templates/AGENTS.md 86→82, deduped the lint/type/test triplet (was 2×), Hard Rules moved to lead, line-cap (≤84) codified as a test assertion. **Fix 5:** cognitive-readiness.sh nudges `run /nana-init` when .dev-wiki/ is missing, short-circuiting the moot per-component probes (bare-dir output = net noise *reduction*); new bidirectional firing test (tests/test_cognitive_readiness.sh, suite 10→11 scripts). Both DETERMINISTIC — explicitly NO judge-eval ([[deterministic-success-over-eval-ceremony]]: a judge launders variance, not signal, on byte-identical-output changes). USER OVERRIDE (direction gate waived; autonomous run). Self-check clean, review gate 9/10 accept, make test 11 scripts green, eval 54/54. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-phase-59-validate-research-delta-cut|Phase 59 → VERDICT CUT (active research removed from dev-plan Step 2.7)]] -- strengthened Phase 58's n=1 +0.5 with 3 new wiki-uncovered topics (13 paired within-round runs at n≥3, judge-v2, escalation + variance gate). Poor topic (commit-convention) delta=−1.0 **REAL harm** (findings anchored design to the generic answer + crowded out context reasoning); rich topics (retry/backoff 0.0, ledger-isolation −0.4) both variance-dominated at n=5; not one n≥3 topic positive; the +0.5 sits inside the noise band. Mechanical rule (rich no real positive + poor real-negative VETO) ⇒ **CUT**. Removed Step 2.7 + Step-6 citation bullet from SKILL.md (326→321), deleted domain-research-spec.md. test_templates 169/169, make test green, eval 54/54. Pre-registered measurement caught an already-SHIPPED n=1 false positive. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-memory-venv-fix-make-test-green|Maintenance: memory venv fix — make test green end-to-end]] -- post-Phase-58 follow-on (commit `74da87a`). `make test` was halting at `test_memory.sh`; root cause twofold (optional `sqlite-vec` absent from venv + test hard-failing instead of skipping). Fixed both: installed `sqlite-vec==0.1.9` locally + guarded vec tests to skip cleanly (FTS5-only). Verified 11/11 vec-present, 7/7 vec-absent (exit 0). Durable lesson: optional-dep tests must skip, not assume-and-halt. Review gate skipped (0 phase tasks, single proven change)
- [2026-05-28] [[2026-05-28-phase-58-active-domain-research-complete|Phase 58 complete (active domain research in dev-plan — Fix 2)]] -- gap-gated Step 2.7 companion (per-DRQ wiki-query gate, numeric caps, injection-safety, ~1200-char distill, provenance + contradiction-check persist, fail-open) wired via pointer (SKILL.md 326/350); residual-delta measurement +0.5 composite n=1 (reasoning 3→4) on research-favorable topic, non-theatrical, kept at Checkpoint 2; 9/9 non-memory suites green, 54/54 eval; delivery accepted, committed
- [2026-05-28] [[2026-05-28-phase-57-hook-consolidation-enforcement-activation-complete|Phase 57 complete (hook consolidation & enforcement activation — Fix 1)]] -- 3 disagreeing hook sources → 1 scope-tagged modules.json array (17 project + 1 global), template generated + drift-tested, enforce marker project-reachable, enforce-spec FIRES (exit 2) in fresh scaffold; py-init/ts-init marker gap caught by self-check + guarded; 23 block events confirm live enforcement; 10/10 scripts green (CI-equiv)

## Cross-References

- Phases 1-60: 60 completed; Phase 60 = harness-activation roadmap CLOSED (delivery accepted + committed) (see index.md)
- **Roadmap: Phase 57+ Harness Activation — COMPLETE.** Fix 1 (hook consolidation, P57) DONE; Fix 2 (domain research, P58) shipped → CUT P59 (pre-registered measurement caught an n=1 false positive); Fix 4 closed P55/56; **Fix 3 (AGENTS.md budget+salience trim) + Fix 5 (kit-uninitialized /nana-init nudge) DONE P60.** No residual harness-activation items.
- Next substantive roadmap items (Phase 61 candidates): vector-search-default-on design call (91%→~95% recall vs sqlite-vec fragility); gap 4.1 language-agnostic core (factor py-* out — AGENTS.md is hard-Python); research phase on the unverified always-loaded-budget claim (AGENTS.md:84).
- Maintenance (post-Phase-58, commit `74da87a`): memory venv fix — `make test` green end-to-end; [[guard-optional-dep-tests]] (optional-dep tests skip, never assume-and-halt).
- Spec: Phase 55 used USER OVERRIDE (experiment data replaced prescriptive spec)
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES + 4 domain pattern articles, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 51-55 clean (0 recurring blockers, 0 reversals, 1 documented user override)
