# Current State: nana-dev-kit

> Last updated: 2026-05-29 by /dev-debrief (Phase 62 ready for completion — deterministic hot-cache curator landed; delivery gate pending)

## Recommended Next Action

**Accept the Phase 62 delivery gate**, then commit + push and flip the phase status active→completed. Phase 62 is functionally done (4/4 tasks [x], all exit criteria met): the always-loaded hot cache (`working-knowledge.md`) now enforces its own integrity **deterministically** — `wk-prune.sh` extended into a single curator (cap-enforce + exact-proposition dedup + well-formedness whole-file bail + atomic validate-temp→rename), with a new 11-test invariant suite (`tests/test_working_knowledge_curation.sh`) wired into `make test` (now 13 scripts, green). The wrong slug-dedup key was fixed across all 4 touchpoints and the cap/dedup/eviction policy consolidated into ONE source of truth (`working-knowledge-spec.md`). Dogfood on the live cache (at exactly 100 entries) was a byte-identical no-op — all 6 distinct `phase-45` entries intact, fixed point holds. `make eval` unchanged at 54/54; `test_step_numbering.sh` still passes. Implementation note: the curator is a bash-3.2-safe wrapper delegating heavy logic to inline python3 (macOS bash floor + `cp -r`-to-every-project blast radius). After the gate, the Phase-63 candidate is hot-cache eviction value-signal (the usage counter is empirically inert → cap-eviction is de-facto recency; decide a real value signal vs. accepting recency explicitly).

## Active Phase

**[[phase-62-harden-hot-cache-curation|Phase 62: Harden Hot-Cache Curation]]** (status: active)

Entry criteria: MET (Phase 61 complete + delivery accepted + committed; approved spec `specs/harden-hot-cache-curation.md` nana:approved 2026-05-29; direction confirmed 2026-05-29)
Exit criteria: `tests/test_working_knowledge_curation.sh` passes (over-cap cull / pinned-immune incl. all-pinned-over-cap / exact-dup keeps max uses / distinct-facts-same-slug NOT collapsed / malformed whole-file no-op / exactly-100 no-op / idempotent / >30d prune still works); `grep -rEn "increment .?uses.? instead" templates/` empty + `grep -q "proposition text" working-knowledge-spec.md`; `make test` ≥13 scripts green; `make eval` at baseline (54 per P61); `test_step_numbering.sh` still passes; dogfood curator on live cache = 0 evictions / 0 dup-removals / phase-45 entries intact

Progress: ~0% (planned, 4 tasks; T1 not started)

## Active Phase Contract

Phase: 62 - Harden Hot-Cache Curation
Tasks: 4 (T1 curator core [L] → T2 wire test into make test [S] → T3 fix dedup key + consolidate policy [M] → T4 dogfood no-op on live cache [S])
Transition: continue (begin T1)
Abort: if blocked >3 attempts, mark [blocked:], report, ask. If the live file violates the 2-line invariant at dogfood (T4): STOP and report — do not auto-fix a mandatory file.

## Recent Decisions

| Decision | Confidence | Date |
|----------|------------|------|
| [[harden-hot-cache-curation-deterministic]] Phase 62 hardens the hot cache via a deterministic curator + invariant test; distillation-quality is OUT (unmeasurable by the binary runner + no headroom — cache at quality-ceiling). Full-suite (incl. judge-eval) and declare-done both rejected (subtraction test / concrete latent defects). | high | 2026-05-29 |
| [[dedup-key-proposition-not-slug]] Dedup MUST key on normalized proposition text, never source slug — slug-dedup is wrong-when-followed (phase-45 ×6 distinct entries share one slug). Exact-dup merge keeps the higher `uses`; fuzzy near-dups flagged to stale-queue, not removed. | high | 2026-05-29 |
| [[curator-fail-safe-atomic]] Curator is fail-safe: validate-temp→atomic-rename (abort byte-intact on failure); any 2-line pairing failure → whole-file no-op + warn (never per-entry repair on a mandatory file); never evicts `[pinned]` (pins win even over cap, with warning). High blast radius (cp -r to every project). | high | 2026-05-29 |
| [[extend-wk-prune-not-new-hook]] Curator extends the existing `wk-prune.sh` rather than adding a hook/script — strengthen existing activation points, don't add unwireable hooks ([[memory-architecture-classification]]; cascade-failure anti-pattern bitten 3×). | high | 2026-05-29 |
| [[hot-cache-is-the-effective-retrieval-layer]] The always-loaded markdown hot cache IS the effective retrieval layer — it made every clean baseline strong, which is WHY all 5 runtime-retrieval directions measured net-zero-or-negative (Phase 61 load-bearing meta-finding; the affirmative evidence for Phase 62). | high | 2026-05-29 |
| [[two-tier-curate-into-hot-cache]] 2-tier architecture (D3): curate-into-hot-cache; do NOT build a 3rd runtime-retrieved store tier. Marginal effort belongs in hot-cache curation quality — Phase 62 is that effort. | high | 2026-05-29 |

## Blockers and Open Questions
- [planning] Phase 62: is recency-among-floor-`uses` the honest eviction signal, or just recency in disguise? The usage counter is empirically inert (87/100 entries at `[uses:1]` — it only increments on exact source re-cite), so "lowest-uses, ties→oldest-date" degenerates to "evict the oldest among 87." Eviction is deterministic-and-safe regardless; the open question is whether a better value signal exists (deferred — not blocking the cap-enforce work). (raised 2026-05-29)
- [planning] Phase 62: how to normalize "exact duplicate proposition" (leading `- [uses: N] ` prefix, surrounding whitespace, trailing punctuation) so it catches genuine duplicates without false-positiving distinct same-topic facts (the 6 `phase-45` entries that all mention "heuristic"). Resolved by [[dedup-key-proposition-not-slug]] for the exact-match path; fuzzy near-dups are advisory-only (stale-queue) precisely because this normalization is hard to get right without false positives. (raised 2026-05-29)

- ~~Phase 58 residual research delta is +0.5 composite at n=1 (at significance threshold, topic-favorable). Kept Step 2.7 (Checkpoint 2). Phase 59 resolves the keep/trim/cut call.~~ **RESOLVED 2026-05-28 → CUT.** Strengthened with 3 new topics (13 paired runs at n≥3): poor −1.0 real harm, rich 0.0/−0.4 variance-dominated; the +0.5 sits inside the noise band. Feature removed; dev-plan reverts to Phase-55 behavior. (resolved 2026-05-28)

- OPEN: Active research's value on genuinely novel / post-training-cutoff / proprietary topics (weak parametric knowledge — research's theoretical sweet spot) is UNTESTED. Only well-documented domains were measured. A deliberate keep-for-novel-topics-only is a separate user call. (raised 2026-05-28) — Phase 61 reconfirmed: the weak-parametric + properly-absorbed + covered sweet spot remains unmeasured (would need an absorb pipeline + a non-commodity corpus first).

- OPEN: D2 re-test trigger (deferred, concrete numeric trigger not a present feature): if the MCP memory store ever grows past the hot-cache 100-entry cap with valuable DISTINCT entries, re-run the D2 A/B (memory_search as overflow recall for the evicted tail). As it stands the store (20 entries) is a strict subset of the hot cache. (raised 2026-05-29)

- Haiku/judge inter-run variance: mean ranges 2.97-4.85; recurred in Phase 59 (rich-topic spread 0.79–1.19, both variance-dominated at n=5). Cross-model judge / judge re-calibration remains a standing lever (deferred). (raised 2026-05-27, reconfirmed 2026-05-28)
- ~~Memory venv broken (recurring Phases 56-58): `make test` halted at `test_memory.sh`.~~ **RESOLVED 2026-05-28.** Root cause was twofold: (1) the optional `sqlite-vec` dep was absent from the (healthy, uv-built, Py3.13) venv — the `libpython3.11.dylib` symptom was stale from an older venv; (2) `test_memory.sh` forced `_vec_available=True` and hard-crashed instead of skipping when the *optional* dep was missing. Fixed both: installed `sqlite-vec==0.1.9` locally (full 11/11 run), AND guarded the 4 vec-requiring tests behind a one-time probe so they skip cleanly (FTS5-only 7/7) when sqlite-vec is absent — `make test` can no longer halt on a missing optional dep. (resolved 2026-05-28)

## Key Artifacts

| Path | Purpose | Last Modified |
|------|---------|---------------|
| `templates/.claude/hooks/session-start.d/wk-prune.sh` | Phase 62 — extended into the single deterministic hot-cache curator: cap-enforce + exact-proposition dedup + well-formedness whole-file bail + atomic validate-temp→rename (bash-3.2 wrapper + inline python3) | 2026-05-29 |
| `tests/test_working_knowledge_curation.sh` | NEW (Phase 62 T1) — 11 invariant tests (over-cap cull / pinned-immune / exact-dup keeps max uses / distinct-same-slug NOT collapsed / malformed no-op / exactly-100 no-op / idempotent / >30d prune); 13th make-test script | 2026-05-29 |
| `templates/.claude/skills/dev-wiki/working-knowledge-spec.md` | Phase 62 — single source of truth for the cap/dedup/eviction policy; dedup key fixed slug→proposition-text; 3 other touchpoints now reference it | 2026-05-29 |
| `eval/memory-integration/results.md` | Phase 61 A/B record: all 5 runtime-retrieval directions CUT; hot-cache meta-finding + Phase-62 build list | 2026-05-29 |
| `templates/.claude/skills/dev-plan/SKILL.md` | Steps renumbered whole-number gap-free 1..18 (P61 T6); Step 16f-ter now references working-knowledge-spec.md (P62) | 2026-05-29 |
| `tests/test_step_numbering.sh` | Phase 61 T6 — 6 assertions (no-decimal + gap-free 1..N per template); still green after P62 (no renumber) | 2026-05-29 |
| `templates/AGENTS.md` | Scaffolded-project conventions; Phase 60 trim — 82 lines, line-cap test-enforced | 2026-05-29 |
| `modules.json` | Single canonical scope-tagged `hooks` array (17 project + 1 global) — hook source of truth | 2026-05-28 |
| `tests/test_memory.sh` | Vec-requiring tests probe sqlite-vec once + SKIP cleanly (FTS5-only) when absent | 2026-05-28 |

## Session Journal (last 5)

- [2026-05-29] [[2026-05-29-phase-62-harden-hot-cache-curation-complete|Phase 62 complete — Harden Hot-Cache Curation (deterministic curator + invariant test)]] -- replaced the LLM-executed prose that maintains the always-loaded hot cache (`working-knowledge.md`) with a **deterministic, test-covered curator**, sidestepping the Phase-59 unmeasurability trap (the invariant test IS the validation — no judge-eval). Extended `wk-prune.sh` into the single curator: cap-enforce + exact-proposition dedup (keep max `uses`) + well-formedness whole-file bail + atomic validate-temp→rename. Fixed the wrong dedup KEY (slug→proposition-text — slug-dedup was wrong-when-followed, `phase-45` ×6 distinct entries one slug) across all 4 touchpoints and consolidated the policy into ONE source of truth (`working-knowledge-spec.md`). New 11-test invariant suite → `make test` 12→13 scripts green; `make eval` 54/54; `test_step_numbering.sh` intact. Dogfood on the live cache (at exactly 100) = byte-identical no-op. Build note: bash-3.2-safe wrapper + inline python3 (macOS floor + `cp -r` blast radius). 4/4 tasks ✓, **READY FOR COMPLETION**, delivery gate pending. Phase-63 candidate: eviction value-signal (usage counter empirically inert ⇒ cap-eviction is de-facto recency).
- [2026-05-29] [[2026-05-29-phase-61-memory-knowledge-integration-ab-complete|Phase 61 complete — Memory & Knowledge Integration A/B (all 5 directions CUT) + step-renumber]] -- experiment-first A/B decided which memory/knowledge-retrieval integrations earn a harness place. **All 5 runtime-retrieval directions CUT** (D1 wiki-search Δ=−0.67, D2 MCP memory read-path Δ=0.00, D3 3rd-tier, D4 absorb-prep, D5 firewall). D2 is a textbook redundant-retrieval null: the 20-entry MCP store is a strict SUBSET of the ~90-entry always-loaded hot cache (same bridge/harvest pipeline) ⇒ zero lift at non-zero cost. **Load-bearing positive meta-finding:** the always-loaded markdown hot cache IS the effective retrieval layer (it made every baseline strong → runtime retrieval redundant). D3 → 2-tier (curate-into-hot-cache, no 3rd tier). T6 step-renumber landed (dev-plan 1..18, dev-debrief 1..26, spec 1..9; ~200 ref edits; new test_step_numbering.sh, make test → 12 scripts). make eval 54/54. Phase-62 candidate: hot-cache curation quality. 7/7 tasks ✓, delivery accepted + committed.
- [2026-05-29] [[2026-05-29-phase-60-harness-activation-residuals-complete|Phase 60 complete — Harness Activation Residuals (AGENTS.md trim + kit-uninitialized nudge)]] -- closed the Phase 57+ harness-activation roadmap (Fixes 1–5 all done). **Fix 3:** templates/AGENTS.md 86→82, deduped the lint/type/test triplet, Hard Rules moved to lead, line-cap (≤84) test-enforced. **Fix 5:** cognitive-readiness.sh nudges `run /nana-init` when .dev-wiki/ is missing; new bidirectional firing test (suite 10→11 scripts). Both DETERMINISTIC — no judge-eval. USER OVERRIDE (direction gate waived; autonomous run). Review gate 9/10 accept, make test 11 scripts green, eval 54/54. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-phase-59-validate-research-delta-cut|Phase 59 → VERDICT CUT (active research removed from dev-plan Step 2.7)]] -- strengthened Phase 58's n=1 +0.5 with 3 new wiki-uncovered topics (13 paired within-round runs at n≥3, judge-v2, escalation + variance gate). Poor topic (commit-convention) delta=−1.0 **REAL harm** (findings anchored design to the generic answer + crowded out context reasoning); rich topics (retry/backoff 0.0, ledger-isolation −0.4) both variance-dominated at n=5; not one n≥3 topic positive; the +0.5 sits inside the noise band. Mechanical rule (rich no real positive + poor real-negative VETO) ⇒ **CUT**. Removed Step 2.7 + Step-6 citation bullet from SKILL.md (326→321), deleted domain-research-spec.md. test_templates 169/169, make test green, eval 54/54. Pre-registered measurement caught an already-SHIPPED n=1 false positive. **Delivered + committed.**
- [2026-05-28] [[2026-05-28-memory-venv-fix-make-test-green|Maintenance: memory venv fix — make test green end-to-end]] -- post-Phase-58 follow-on (commit `74da87a`). `make test` was halting at `test_memory.sh`; root cause twofold (optional `sqlite-vec` absent from venv + test hard-failing instead of skipping). Fixed both: installed `sqlite-vec==0.1.9` locally + guarded vec tests to skip cleanly (FTS5-only). Verified 11/11 vec-present, 7/7 vec-absent (exit 0). Durable lesson: optional-dep tests must skip, not assume-and-halt. Review gate skipped (0 phase tasks, single proven change)

## Cross-References

- Phases 1-61: 61 completed; Phase 62 = READY FOR COMPLETION (delivery gate pending) (see index.md)
- **Phase 62 outcome:** the hot cache now enforces its own integrity invariants deterministically (cap/dedup/well-formedness/atomic-write), replacing fuzzy LLM-executed prose; dedup key corrected slug→proposition-text; policy consolidated to one source of truth. The one affirmative-evidence direction from Phase 61 ([[hot-cache-is-the-effective-retrieval-layer]], [[two-tier-curate-into-hot-cache]]) shipped. Governed by [[harden-hot-cache-curation-deterministic]], [[dedup-key-proposition-not-slug]], [[curator-fail-safe-atomic]], [[extend-wk-prune-not-new-hook]].
- **Phase 61 outcome:** experiment-first A/B → all 5 runtime-retrieval directions CUT; load-bearing positive = [[hot-cache-is-the-effective-retrieval-layer]]. Validates [[memory-architecture-classification]] (strengthen always-loaded `.claude/rules/` activation points) by measurement. Companion to Phase-59's [[cut-active-research-step-2-7]].
- **Roadmap: Phase 57+ Harness Activation — COMPLETE** (Fixes 1–5 all done across P55-60). No residual harness-activation items.
- Next substantive roadmap items: **Phase 63 candidate: hot-cache eviction value-signal** (usage counter empirically inert ⇒ cap-eviction is de-facto recency; decide a real value signal vs. accepting recency explicitly) + distillation QUALITY (what gets written into the cache — needs a non-binary eval method first). Also standing: vector-search-default-on design call; gap 4.1 language-agnostic core (factor py-* out); always-loaded-budget claim research (AGENTS.md:84); repo-hygiene: gitignore `.memory/*.db*` (runtime churn pollutes phase diffs).
- Maintenance (post-Phase-58, commit `74da87a`): memory venv fix — `make test` green end-to-end; [[guard-optional-dep-tests]] (optional-dep tests skip, never assume-and-halt).
- Spec: Phase 55 used USER OVERRIDE (experiment data replaced prescriptive spec)
- Roadmap: [[roadmap-gap-analysis|Engineering Gap Analysis]] -- 1 OPEN gap remains (4.1 language-agnostic core)
- Roadmap: [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]] -- 7/7 phases done (all complete)
- Release: v0.5.0 tagged and pushed
- Benchmark: FTS5 recall@5 91.0%, hybrid/turn ~95% estimated (LongMemEval-S)
- Knowledge wiki: wiki/ (cognitive-patterns) -- 11 heuristics + 5 IRON RULES + 4 domain pattern articles, heuristic judge + matcher wired at Step 6.5, counter + lifecycle evolution loop
- Retro: Phases 51-55 clean (0 recurring blockers, 0 reversals, 1 documented user override)
