---
title: "Phase 62 complete — Harden Hot-Cache Curation (deterministic curator + invariant test)"
aliases: ["2026-05-29-phase-62", "phase-62-complete", "harden-hot-cache-curation-complete"]
category: journal
tags: [memory, hot-cache, working-knowledge, curation, eviction, dedup, deterministic, bash-portability, context-engineering]
parents: [phase-62-harden-hot-cache-curation]
created: 2026-05-29
updated: 2026-05-29
source: debrief
duration: ~2h (post-compaction estimate — may undercount)
---

# Phase 62 complete — Harden Hot-Cache Curation

## What Happened

Hardened the always-loaded hot cache (`.claude/rules/working-knowledge.md`) — the one memory/knowledge direction with affirmative evidence (Phase 61 proved the hot cache IS the effective retrieval layer). The cache previously relied on LLM-executed prose to enforce its own integrity; this phase replaced that with a **deterministic, test-covered curator** — sidestepping the Phase-59 unmeasurability trap by making the invariant test the validation rather than a reasoning-eval.

- **T1 (Curator core):** extended the existing `wk-prune.sh` session-start prune into the single deterministic curator: cap-enforce (>100 entries / >210 lines → evict lowest-`uses`, ties → oldest `activated:`, NON-STRICT) + exact-proposition dedup (keep max `uses`) + well-formedness whole-file bail + atomic validate-temp→rename write. Wrote `tests/test_working_knowledge_curation.sh` (11 invariant tests, RED→GREEN).
- **T2:** wired the new test into `make test` (13th script); confirmed no regression (`make test` green, `make eval` 54/54).
- **T3:** fixed the wrong dedup KEY (slug→proposition-text) across all 4 touchpoints and consolidated the cap/dedup/eviction policy into `working-knowledge-spec.md` as the single source of truth (the other 3 touchpoints now reference it). Did NOT renumber dev-plan steps (protects `test_step_numbering.sh`).
- **T4 (dogfood):** ran the curator on the live cache (at exactly 100 entries) — byte-identical no-op, all 6 distinct `phase-45` entries intact. The fixed point holds.

Build note: the curator is a bash-3.2-safe wrapper delegating heavy logic to inline python3 (macOS bash floor + `cp -r`-to-every-project blast radius); this is the bash-portability rule for all kit hooks going forward.

### Review Gate
Unified reviewer: **7/10 → revise**. Found 1 HIGH + 1 MEDIUM, both **fixed inline + re-verified** (no re-review needed; fixes are test-covered):
- **[HIGH]** Stage-2 dedup could silently drop a `[pinned]` entry: `norm()` strips the `[pinned]` marker before comparing, so an unpinned exact-text twin ordered first would win and the pin be dropped — violating the CRITICAL "never evict a pin" constraint, with the mandated `(evicted ∩ pinned)=∅` assertion implemented nowhere. Fix: pinned-aware survivor selection (a pin always survives; only unpinned copies are dropped; two pinned twins both kept) + an explicit `(evicted ∩ pinned)=∅` guard before write. Added 2 regression tests (pin-survives-earlier-unpinned-twin; both-pinned-kept).
- **[MEDIUM]** `over_cap()` let the 210-line bound trigger eviction even at ≤100 entries, contradicting the spec's cap-precedence (lines-over-while-entries-under routes to the no-op/well-formedness path, not eviction). Unreachable in production (live file 203 lines at 100 entries; entry-count always binds first). Fix: eviction triggers on entry-count only; line-over-cap routes to no-op. Code aligned to spec (spec already correct).
- Reviewer confirmed the never-lose-knowledge axis is solid: malformed-bail, atomic-write, CRLF/no-trailing-newline/absent-empty paths all preserve bytes; dogfood no-op on the live 100-entry cache (6 distinct phase-45 entries intact) verified.

Post-fix: working-knowledge-curation 13/13, full suite green (13 scripts), `make eval` 54/54, dogfood still byte-identical.

## Decisions Made

No new decisions surfaced during implementation. The 4 governing decisions were captured at plan time and are unchanged:
- [[harden-hot-cache-curation-deterministic|Harden the hot cache via a deterministic curator + invariant test (distillation-quality OUT)]]
- [[dedup-key-proposition-not-slug|Dedup keys on normalized proposition text, never source slug]]
- [[curator-fail-safe-atomic|Curator is fail-safe: validate-temp→atomic-rename; whole-file no-op on malformed; never evicts pinned]]
- [[extend-wk-prune-not-new-hook|Curator extends the existing wk-prune.sh rather than adding an unwireable hook]]

## Problems Solved

- **macOS bash 3.2 floor** (DISCOVERY) — `mapfile`/associative arrays unavailable, `set -u` + empty-array expansion a footgun. Delegated curator logic to inline python3 (already required by this hook).
- **Wrong dedup KEY, not broken dedup** — 12 duplicate `source:` slugs looked like a bug, but distinct facts legitimately share a source phase (`phase-45` × 6). The defect was a too-coarse key; fixed by keying exact-match dedup on proposition text.

## Open Questions

- Is recency-among-floor-`uses` the honest eviction signal? The usage counter is empirically inert (87/100 at `[uses:1]`, increments only on exact source re-cite) ⇒ cap-eviction degenerates to recency. A genuine value signal vs. accepting recency explicitly is unmeasured (Phase-63). Eviction is deterministic-and-safe regardless. (Detailed under Soft Observations.)

## Artifacts Changed

- `templates/.claude/hooks/session-start.d/wk-prune.sh` (extended age-pruner → single deterministic curator; bash wrapper + inline python3)
- `tests/test_working_knowledge_curation.sh` (NEW — 11 invariant tests) + `Makefile` (wired; suite 12→13 scripts)
- `templates/.claude/skills/dev-wiki/working-knowledge-spec.md` (single source of truth; dedup key fixed slug→proposition-text); 3 touchpoints now reference it — `dev-debrief/active-knowledge-transition.md`, `dev-plan/SKILL.md` (Step 16f-ter, no renumber), `dev-plan/compaction-anchors-spec.md`
- `README.md` (test-script count 12→13 — referential invariant; DISCOVERY)
- `.claude/rules/working-knowledge.md` (dogfood target — read-only verify, byte-identical no-op)

## Related

- [[phase-62-harden-hot-cache-curation|Phase 62: Harden Hot-Cache Curation]] — parent phase
- [[phase-61-validate-memory-knowledge-integration|Phase 61]] — established the hot cache as the effective retrieval layer (the affirmative evidence for this phase)

## Soft Observations / Phase N+1 Candidates

- **Eviction value-signal is inert** | Phase-63 candidate: a real value signal for cap-eviction vs. an explicit decision to accept recency | evidence: 87/100 at `[uses:1]`; cap-tie test exercises only the date tiebreak.
- **Distillation QUALITY unaddressed** | cut from P62 as unmeasurable by the binary runner — what gets *written into* the cache, not its integrity | needs a non-binary eval method first.
- **Sparse file-articles** | `wk-prune.sh` + `session-start.d/` sub-modules lack `.dev-wiki/articles/files/` articles (legacy 8-article set) — pre-existing gap.
- **`.memory/memory.db`(+`-wal`) tracked in git** | repo-hygiene candidate: gitignore them — runtime memory churn pollutes phase diffs (this session's spec bridge dirtied `memory.db-wal`).

### Activation Quality

`.claude/rules/active-knowledge.md` carried 5 distinct decision-slug references across 3 distilled blocks (Why curation is the lever / Live-file facts / Build discipline): `hot-cache-is-the-effective-retrieval-layer`, `two-tier-curate-into-hot-cache`, `dedup-key-proposition-not-slug`, `harden-hot-cache-curation-deterministic`, `curator-fail-safe-atomic`. All 5 were load-bearing in implementation — the dedup-key and fail-safe/atomic propositions directly shaped T1/T3, and the inert-usage-counter live-file fact framed the deferred eviction-signal open question. **Hit rate: 5/5 (100%).** Active knowledge was on-target for this phase.
