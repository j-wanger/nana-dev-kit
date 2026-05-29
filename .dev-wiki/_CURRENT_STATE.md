# Current State: nana-dev-kit

> Last updated: 2026-05-29 by /dev-debrief (Phase 61 complete 7/7 — all 5 retrieval directions CUT + step-renumber; READY FOR COMPLETION, delivery gate pending)

## Recommended Next Action

Phase 61 (experiment-first memory/knowledge integration A/B) is **COMPLETE at 7/7 — READY FOR COMPLETION; delivery gate pending.** Verdict: **all five runtime-retrieval directions CUT** (D1 wiki-search delta=−0.67, D2 MCP memory read-path delta=0.00, D3 3rd-tier, D4 absorb-prep, D5 firewall — net-zero-or-negative across the board). **Load-bearing positive meta-finding:** the always-loaded markdown hot cache (`working-knowledge.md` + `active-knowledge.md`) IS the effective retrieval layer — it made every clean baseline strong, which is WHY runtime external retrieval doesn't pay (the knowledge is already in context). D2 is a textbook redundant-retrieval null: the MCP store (20 entries) is a strict SUBSET of the ~90-entry hot cache (same bridge/harvest pipeline). **T6 step-renumber landed** (dev-plan 1..18, dev-debrief 1..26, spec 1..9; ~200 ref edits; new `tests/test_step_numbering.sh`, make test now 12 scripts). make eval 54/54 (100%). **NEXT:** accept the delivery gate → commit + push → mark phase complete. **Then Phase 62 candidate (the one direction with affirmative evidence): hot-cache curation quality** (dev-debrief→working-knowledge distillation, 100-entry-cap eviction policy, dedup). Full state in `eval/memory-integration/results.md` (pre-reg + T1–T5) + `.claude/rules/active-phase.md`.

## Active Phase

**[[phase-61-validate-memory-knowledge-integration|Phase 61: Validate Memory & Knowledge Integration]]** (status: active)

Entry criteria: MET (Phase 60 complete + committed; approved spec specs/phase-61-validate-memory-knowledge-integration.md, reviewer 8/10→revise w/ both MAJOR findings fixed; user chose experiment-first + all 5 directions incl. the retrieval-subagent firewall; direction gate approved "yes")
Exit criteria: results.md w/ pre-registration ordered first; wiki signal-quality gate + ≥2 weak-parametric+covered topics (or explicit Phase-59-redux stop); Stage-0 falsification delta; firewall direction + context-poisoning + cost ledger recorded; per-direction keep/cut keyed to numbers + a Phase-62 build list; step-renumber to whole numbers across the 3 SKILL templates w/ all cross-refs resolved + a numbering-continuity test; make test green + make eval 100%

Progress: 7/7 tasks (T1 signal-gate+pre-reg ✓; T2 Stage-0 ✓ → D1 CUT; T3 D2 A/B ✓ → CUT; T4 D3 2-tier ✓; T5 aggregate+P62 list ✓; T6 step-renumber ✓; T7 regression gate ✓). **READY FOR COMPLETION** — all exit criteria met. Delivery gate pending (do NOT auto-complete the phase article — ask-user rule).

## Active Phase Contract

Phase: 61 - Validate Memory & Knowledge Integration
Tasks: 7 (T1 signal-gate+pre-reg → T2 Stage-0 falsification CHECKPOINT → T3 Stage-1 source×mechanism [cond] → T4 Stage-2 conclusions [cond] → T5 aggregate+decide → T6 step-renumber [independent] → T7 regression gate)
Transition: continue (begin T1; A/B execution may use Workflow on user opt-in)
Abort: if a stage can't meet its pre-registered criterion after 3 attempts → mark [blocked:], report, ask. Phase-59-redux is a valid early-stop (declare + proceed with architecture + step-renumber).

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[hot-cache-is-the-effective-retrieval-layer]] The always-loaded markdown hot cache (working-knowledge.md + active-knowledge.md) IS the effective retrieval layer — it made every clean baseline strong, which is WHY all 5 runtime-retrieval directions measured net-zero-or-negative. "Retrieval over parametric knowledge" doesn't pay when the knowledge is already in the always-loaded context layer. (Phase 61 load-bearing meta-finding.) | high | 2026-05-29 |
| [[cut-mcp-memory-read-path-d2]] CUT wiring memory_search into planning (D2) — best-case A/B delta=0.00 composite, variance-dominated, net-negative after cost. Root cause: MCP store (20 entries) is a strict SUBSET of the ~90-entry hot cache (same bridge/harvest pipeline). Re-test trigger deferred: if store grows past the 100-entry cap with distinct entries. | high | 2026-05-29 |
| [[two-tier-curate-into-hot-cache]] 2-tier architecture (D3): curate-into-hot-cache; do NOT build a 3rd runtime-retrieved store tier. Derived from D1 (−0.67) + D2 (0.00) nulls. Marginal effort belongs in hot-cache curation quality, not a runtime retrieval engine. | high | 2026-05-29 |
| [[step-renumber-whole-number-invariant]] Whole-number gap-free Step headings across dev-plan(1..18)/dev-debrief(1..26)/spec(1..9) SKILL templates; ~200 ref edits; codified in tests/test_step_numbering.sh (12th make-test script). Full ref-integrity audit caught a partial-token corruption a heading-only check would have shipped. | high | 2026-05-29 |
| [[memory-knowledge-integration-diagnosis]] Both knowledge subsystems own a real retrieval engine the harness flow doesn't use (wiki knowledge.db FTS5/vector; MCP memory_search) — wiki Step 2 does naive frontmatter scoring, MCP memory write-mostly. A/B-gated (Phase-59 net-negative profile). | medium | 2026-05-29 |
| [[cut-active-research-step-2-7]] CUT active web-research injection from dev-plan Step 2.7 — measured net-negative; "retrieval over parametric knowledge" doesn't pay where parametric knowledge is already strong (D1 is this finding's redux, confirmed by measurement). | high | 2026-05-28 |

## Blockers and Open Questions
- ~~Phase 58 residual research delta is +0.5 composite at n=1 (at significance threshold, topic-favorable). Kept Step 2.7 (Checkpoint 2). Phase 59 resolves the keep/trim/cut call.~~ **RESOLVED 2026-05-28 → CUT.** Strengthened with 3 new topics (13 paired runs at n≥3): poor −1.0 real harm, rich 0.0/−0.4 variance-dominated; the +0.5 sits inside the noise band. Feature removed; dev-plan reverts to Phase-55 behavior. (resolved 2026-05-28)

- OPEN: Active research's value on genuinely novel / post-training-cutoff / proprietary topics (weak parametric knowledge — research's theoretical sweet spot) is UNTESTED. Only well-documented domains were measured. A deliberate keep-for-novel-topics-only is a separate user call. (raised 2026-05-28) — Phase 61 reconfirmed: the weak-parametric + properly-absorbed + covered sweet spot remains unmeasured (would need an absorb pipeline + a non-commodity corpus first).

- OPEN: D2 re-test trigger (deferred, concrete numeric trigger not a present feature): if the MCP memory store ever grows past the hot-cache 100-entry cap with valuable DISTINCT entries, re-run the D2 A/B (memory_search as overflow recall for the evicted tail). As it stands the store (20 entries) is a strict subset of the hot cache. (raised 2026-05-29)

- Haiku/judge inter-run variance: mean ranges 2.97-4.85; recurred in Phase 59 (rich-topic spread 0.79–1.19, both variance-dominated at n=5). Cross-model judge / judge re-calibration remains a standing lever (deferred). (raised 2026-05-27, reconfirmed 2026-05-28)
- ~~Memory venv broken (recurring Phases 56-58): `make test` halted at `test_memory.sh`.~~ **RESOLVED 2026-05-28.** Root cause was twofold: (1) the optional `sqlite-vec` dep was absent from the (healthy, uv-built, Py3.13) venv — the `libpython3.11.dylib` symptom was stale from an older venv; (2) `test_memory.sh` forced `_vec_available=True` and hard-crashed instead of skipping when the *optional* dep was missing. Fixed both: installed `sqlite-vec==0.1.9` locally (full 11/11 run), AND guarded the 4 vec-requiring tests behind a one-time probe so they skip cleanly (FTS5-only 7/7) when sqlite-vec is absent — `make test` can no longer halt on a missing optional dep. (resolved 2026-05-28)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `eval/memory-integration/results.md` | Phase 61 A/B record: pre-reg first, T1 signal gate, T2 D1 (−0.67), T3 D2 (0.00), T4 D3 2-tier, T5 aggregate per-direction keep/cut + Phase-62 build list. All 5 retrieval directions CUT; hot-cache meta-finding | 2026-05-29 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Steps renumbered whole-number gap-free 1..18 (T6) | 2026-05-29 |
| `templates/.claude/skills/dev-debrief/SKILL.md` | Steps renumbered 1..26 (T6; cross-file with debrief-finalization.md) | 2026-05-29 |
| `templates/.claude/skills/spec/SKILL.md` | Steps renumbered 1..9 (T6) | 2026-05-29 |
| `tests/test_step_numbering.sh` | NEW (Phase 61 T6) — 6 assertions (no-decimal + gap-free 1..N per template); 12th make-test script | 2026-05-29 |
| `templates/AGENTS.md` | Scaffolded-project conventions; Phase 60 trim — 82 lines, line-cap test-enforced | 2026-05-29 |
| `tests/test_cognitive_readiness.sh` | Phase 60 — bidirectional firing test for the kit-uninitialized /nana-init nudge | 2026-05-29 |
| `modules.json` | Single canonical scope-tagged `hooks` array (17 project + 1 global) — hook source of truth | 2026-05-28 |
| `tests/test_memory.sh` | Vec-requiring tests probe sqlite-vec once + SKIP cleanly (FTS5-only) when absent | 2026-05-28 |

## Session Journal (last 5)

- [2026-05-29] [[2026-05-29-phase-61-memory-knowledge-integration-ab-complete|Phase 61 complete — Memory & Knowledge Integration A/B (all 5 directions CUT) + step-renumber]] -- experiment-first A/B decided which memory/knowledge-retrieval integrations earn a harness place. **All 5 runtime-retrieval directions CUT** (D1 wiki-search Δ=−0.67, D2 MCP memory read-path Δ=0.00, D3 3rd-tier, D4 absorb-prep, D5 firewall). D2 is a textbook redundant-retrieval null: the 20-entry MCP store is a strict SUBSET of the ~90-entry always-loaded hot cache (same bridge/harvest pipeline) ⇒ zero lift at non-zero cost. **Load-bearing positive meta-finding:** the always-loaded markdown hot cache IS the effective retrieval layer (it made every baseline strong → runtime retrieval redundant). D3 → 2-tier (curate-into-hot-cache, no 3rd tier). T6 step-renumber landed (dev-plan 1..18, dev-debrief 1..26, spec 1..9; ~200 ref edits; new test_step_numbering.sh, make test → 12 scripts). make eval 54/54. Phase-62 candidate: hot-cache curation quality. 7/7 tasks ✓, **READY FOR COMPLETION**, delivery gate pending.
- [2026-05-29] [[2026-05-29-phase-60-harness-activation-residuals-complete|Phase 60 complete — Harness Activation Residuals (AGENTS.md trim + kit-uninitialized nudge)]] -- closed the Phase 57+ harness-activation roadmap (Fixes 1–5 all done). **Fix 3:** templates/AGENTS.md 86→82, deduped the lint/type/test triplet, Hard Rules moved to lead, line-cap (≤84) test-enforced. **Fix 5:** cognitive-readiness.sh nudges `run /nana-init` when .dev-wiki/ is missing; new bidirectional firing test (suite 10→11 scripts). Both DETERMINISTIC — no judge-eval. USER OVERRIDE (direction gate waived; autonomous run). Review gate 9/10 accept, make test 11 scripts green, eval 54/54. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-phase-59-validate-research-delta-cut|Phase 59 → VERDICT CUT (active research removed from dev-plan Step 2.7)]] -- strengthened Phase 58's n=1 +0.5 with 3 new wiki-uncovered topics (13 paired within-round runs at n≥3, judge-v2, escalation + variance gate). Poor topic (commit-convention) delta=−1.0 **REAL harm** (findings anchored design to the generic answer + crowded out context reasoning); rich topics (retry/backoff 0.0, ledger-isolation −0.4) both variance-dominated at n=5; not one n≥3 topic positive; the +0.5 sits inside the noise band. Mechanical rule (rich no real positive + poor real-negative VETO) ⇒ **CUT**. Removed Step 2.7 + Step-6 citation bullet from SKILL.md (326→321), deleted domain-research-spec.md. test_templates 169/169, make test green, eval 54/54. Pre-registered measurement caught an already-SHIPPED n=1 false positive. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-memory-venv-fix-make-test-green|Maintenance: memory venv fix — make test green end-to-end]] -- post-Phase-58 follow-on (commit `74da87a`). `make test` was halting at `test_memory.sh`; root cause twofold (optional `sqlite-vec` absent from venv + test hard-failing instead of skipping). Fixed both: installed `sqlite-vec==0.1.9` locally + guarded vec tests to skip cleanly (FTS5-only). Verified 11/11 vec-present, 7/7 vec-absent (exit 0). Durable lesson: optional-dep tests must skip, not assume-and-halt. Review gate skipped (0 phase tasks, single proven change)
- [2026-05-28] [[2026-05-28-phase-58-active-domain-research-complete|Phase 58 complete (active domain research in dev-plan — Fix 2)]] -- gap-gated Step 2.7 companion wired via pointer; residual-delta measurement +0.5 composite n=1 (reasoning 3→4) on research-favorable topic, kept at Checkpoint 2; 9/9 non-memory suites green, 54/54 eval; delivery accepted, committed (later CUT in Phase 59)

## Cross-References

- Phases 1-60: 60 completed; Phase 61 = READY FOR COMPLETION (delivery gate pending) (see index.md)
- **Phase 61 outcome:** experiment-first A/B → all 5 runtime-retrieval directions CUT; load-bearing positive = [[hot-cache-is-the-effective-retrieval-layer]]. Validates [[memory-architecture-classification]] (strengthen always-loaded `.claude/rules/` activation points) by measurement. Companion to Phase-59's [[cut-active-research-step-2-7]].
- **Roadmap: Phase 57+ Harness Activation — COMPLETE** (Fixes 1–5 all done across P55-60). No residual harness-activation items.
- Next substantive roadmap items: **Phase 62 candidate (affirmative-evidence direction): hot-cache curation quality** (dev-debrief→working-knowledge distillation, 100-entry-cap eviction, dedup) — `eval/memory-integration/results.md` Phase-62 build list. Also standing: vector-search-default-on design call; gap 4.1 language-agnostic core (factor py-* out); always-loaded-budget claim research (AGENTS.md:84).
- Maintenance (post-Phase-58, commit `74da87a`): memory venv fix — `make test` green end-to-end; [[guard-optional-dep-tests]] (optional-dep tests skip, never assume-and-halt).
- Spec: Phase 55 used USER OVERRIDE (experiment data replaced prescriptive spec)
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES + 4 domain pattern articles, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 51-55 clean (0 recurring blockers, 0 reversals, 1 documented user override)
