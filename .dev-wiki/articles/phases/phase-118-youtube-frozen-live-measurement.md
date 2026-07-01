---
title: "Phase 118: YouTube grounded-acquisition frozen live measurement"
aliases: [phase-118, youtube-frozen-measurement, youtube-liverun-measurement, rung-b-measurement]
category: phases
tags: [youtube, research-pipeline, grounding, provenance, rung-b, companion-apparatus, pi-setups, live-run, anti-retrofit, pre-registration, frozen-instrument, phase-118]
parents: []
created: 2026-06-30
updated: 2026-07-01
source: plan
status: completed
scope: ["companion/research/youtube/** (frozen apparatus; grounding rail BYTE-FROZEN; NEW run118/ + a frozen pre-registration instrument + SHA-256 seal; verbatim quotes only under gitignored run118/)", ".dev-wiki/** + .dev-wiki/phase-118/ (aggregates + hashes ONLY — never verbatim quotes)", ".claude/rules/active-phase.md", "specs/phase-118-*.md"]
entry_criteria: "Phase 117 DELIVERED (6/6 tasks [x], both gates closed, committed pending). Smoke first-contact cleared the go/no-go to GO on n=1: real captioned video → 95% grounding (21/22), 0 fabrication, ~$0.02-0.05/video; the punctuation-over-drop dominant risk was REFUTED (modern auto-captions are punctuated) and the A1 concern re-oriented to ASR word-errors; a rail-normalization change is NOT indicated. The recommended Phase-118 pre-registration parameters are recorded in .dev-wiki/phase-117/results.md."
exit_criteria: "TBD by /dev-plan. Anticipated: a FROZEN pre-registration instrument (corpus frame + all thresholds + PASS/FAIL truth table + minimum-success floor) committed BEFORE any fetch, SHA-256-sealed; a tamper-evident anchor (git ancestry of the committed prereg + SHA-256 of the fetched ids matching telemetry); the grounding rail byte-unchanged (asserted robustly, not by the vacuous git-diff on a gitignored tree); ToS containment (verbatim quotes only under gitignored run118/; .dev-wiki/phase-118/ aggregates + hashes only); the measurement RUN over the frozen corpus with the A1 audio-grounded rubric + MANDATORY external clean-context inversion cross-check, A2 uncaptioned dead-letter rate vs the 30% whisper-pull-forward threshold, real per-video + per-batch cost under the $2/video + $10/batch + 60-call stops; a verdict read MECHANICALLY against the frozen truth table; companion pytest green."
---

# Phase 118: YouTube grounded-acquisition frozen live measurement

> PLANNED 2026-06-30 by /dev-plan (Standard ceremony). 9 tasks (T1-T8 build + T9 the manual-drive RUN); decision [[youtube-frozen-live-measurement]] (high). Two adversarial reviews folded at plan (C1-C5 + a prereg self-seal). Ledger Phase-118 all_accept:false (A1/A2/A3-strengthened/A4 accept).
>
> **BUILT + twice-adversarially-reviewed 2026-07-01 (/dev-debrief, status stays active).** 8/9 tasks [x]; T9 = the live manual-drive RUN — scaffold built + green, awaiting the maintainer at the PREREG-commit checkpoint (residential IP + ANTHROPIC_API_KEY + manual audio/novelty judging). The phase is NOT complete and the delivery gate does NOT flip until the live run lands. NEW apparatus (gitignored `companion/research/youtube/`): seal118/select118/verify118/harness118/score118/recovery118/verdict118/run118 + 9 test modules; companion pytest 78→169. Tracked artifacts `.dev-wiki/phase-118/{pre-registration.md,prereg.sha256,rail.sha256}` (hashes/aggregates only). Rail byte-frozen (SHA-256 seal verifies — the vacuous git-diff is replaced). Two ultracode adversarial-review Workflows (18+20 agents, ~2.05M tokens) caught 22 confirmed findings (3 HIGH each) — all genuine anti-retrofit holes (corpus.sha256 written-but-never-read-back; keystone bypassable by omitting a sidecar; is_terminal omitted 4 outcomes so a resume would VOID the anchor) — ALL fixed inline + regression-tested; is_terminal made drift-proof. Review gate SATISFIED by the two workflows (no third reviewer). ToS containment CLEAN; run118/ gitignored. See [[2026-07-01-phase-118-frozen-measurement-built]].

## Objective

Run the full pre-registered, frozen live measurement of the Ph116/117 YouTube grounded-acquisition apparatus on a real quarantined corpus (search-query frame). Measure feasibility as a population estimate (not the Ph117 n=1 directional peek): grounding/drop rates, the A1 ASR-misread rate (audio-grounded, with a MANDATORY external clean-context inversion cross-check run OUTSIDE the kit), the A2 uncaptioned dead-letter rate against the 30% whisper-pull-forward threshold, and real per-video + per-batch cost. Anti-retrofit is the point: pre-register ALL parameters + a tamper-evident anchor (git ancestry + SHA-256 of the fetched ids) BEFORE any fetch; commit a PASS/FAIL truth table + a minimum-success floor before any result is seen. Feasibility gates the downstream headroom/value screen (a later rung, NOT this phase).

## Scope

All changes confined to the gitignored `companion/research/youtube/` apparatus + planning artifacts (see frontmatter `scope`). The apparatus and rail are frozen; the phase ADDS a pre-registration instrument + a `run118/` execution home, not new rail behavior. If the Ph117 result had indicated a rail-normalization fix it would be a named task here with its own freeze — but Ph117 concluded a rail change is NOT indicated.

## Exit Criteria

- [ ] Companion pytest green; the `rail.sha256` seal recomputes-and-MATCHES the 4 rail files (a mutated-rail scratch copy MISMATCHES — the control that proves the seal is not vacuous) and the `prereg.sha256` self-seal is recorded + asserted unchanged.
- [ ] The deterministic selection function is order-stable, N=12, and its predicate NEVER filters caption-status (no-caption/blocked videos stay); the corpus-freeze writes the frozen id list + SHA-256 before any fetch.
- [ ] The anchor verifier (`verify118`) passes: git ancestry PREREG ⟶ CORPUS-FREEZE ⟶ RESULTS (fails-on-reorder), frozen-id-set == telemetry-id-set (every id accounted, incl not-run), and a keystone `ground()` re-derivation on the gitignored sidecar whose committed hash matches (fails on a tampered sidecar).
- [ ] harness118 runs a rail-BLIND API-path Sonnet-4.6 extractor (pinned forbidden-token list), a $10/batch cap (`BatchBudgetExceeded`), per-id accounting, and a non-optional-stopping resume over the FIXED frozen N.
- [ ] The 3 controls-first instrument gates (splice / audio-vs-caption misread / classifier) each CATCH a seeded defect AND are clean unseeded (clean-on-seed = instrument-dead, HEU-012).
- [ ] The mechanical truth-table evaluator returns PASS/FAIL/INCONCLUSIVE/VOID over {grounding-rate, cost, A2-count, instrument-controls} ONLY (A1 + novelty kept OUT); the min-success floor (<4 successes OR <20 concepts → INCONCLUSIVE) applies.
- [ ] The containment gate is CLEAN: `git grep source_quote` (whole repo, tracked) finds nothing AND `git check-ignore run118` returns the path.
- [ ] The manual-drive RUN writes `run118/telemetry.jsonl` (a row per frozen id) and `results.md` records the mechanical verdict vs the frozen truth table + the A1/A2/novelty layers + the go/no-go on the Ph119 value screen; PREREG-commit-before-search + STOP-after-first are recorded.

## Constraints (confirmed at plan)

- RAIL BYTE-FROZEN (`ground.py`/`normalize.py`/`consolidate.py`/`schema.py`) — asserted via a committed `rail.sha256` seal re-verified before the verdict, NOT the vacuous `git diff --quiet` (the whole tree is gitignored — `git ls-files companion/` empty).
- PREREG BYTE-FROZEN via a `prereg.sha256` self-seal — NO in-phase amend (a post-unblinding amendment VOIDs the verdict; Ph87 three-tier authority).
- Two-stage tamper-evident anchor + keystone `ground()` re-derivation on the gitignored sidecar (git ancestry can only bind the TRACKED `.dev-wiki/phase-118/`; verbatim telemetry stays gitignored under `run118/`).
- ToS containment — verbatim quotes only under gitignored `run118/`; `.dev-wiki/phase-118/` carries aggregates + hashes ONLY (`git grep source_quote` whole-repo + `git check-ignore run118` gate).
- Feasibility GO/NO-GO frame — A2 DIRECTIONAL (not a mechanical whisper-trip); non-optional-stopping resume over the FIXED frozen N; novelty admissible only scoped-to-post-cutoff, NEVER in the verdict (feeds Ph119).
- PRIMARY extractor = rail-BLIND API-path Sonnet-4.6 (the Ph117 rate used a rail-AWARE session model — an upper-ish estimate).
- The Ph117 smoke video (`04EL2_Llenc`) is QUARANTINED — it MUST NOT enter the frozen corpus (seeing its output would break the freeze).
- Cost stops $2/video + $10/batch + 60-call ceiling; manual-drive live fetch on a residential IP with `ANTHROPIC_API_KEY`; deterministic tests on fixtures + a mocked client.

## Notes

Rides the Ph116 acquire→chunk→extract→ground+consolidate apparatus and the Ph117 telemetry/hardening layer (`harness117.py`, telemetry in `extract.py`/`ingest.py`, hardening in `acquire.py`). The Ph117 `results.md` records the recommended pre-registration parameters (search-query frame; A2 threshold 30%; A1 solo + mandatory external inversion; cost stops $2/video + $10/batch + 60-call ceiling; anchor = git ancestry + SHA-256 of fetched ids; a PASS/FAIL truth table; a minimum-success floor of <4 above-floor successes OR <20 pooled grounded concepts → INCONCLUSIVE). First-full-measurement rung of [[youtube-grounded-acquisition]] (Ph116) / [[youtube-liverun-derisk]] (Ph117) on the Ph97 rung-B ladder ([[frontier-positioning-sweep]]); grounding inherits the verify-by-re-fetch lineage ([[qa-verification-sweep]], [[HEU-012]]).
