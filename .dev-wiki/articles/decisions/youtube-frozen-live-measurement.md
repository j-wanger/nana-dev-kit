---
title: "YouTube grounded-acquisition frozen live measurement — feasibility GO/NO-GO + controlled novelty recovery (Ph118)"
aliases: [youtube-frozen-live-measurement, youtube-frozen-measurement, youtube-liverun-measurement, rung-b-measurement, phase-118]
category: decisions
tags: [youtube, research-pipeline, grounding, provenance, rung-b, anti-retrofit, pre-registration, frozen-instrument, amplifier-null, feasibility, phase-118]
parents: [phase-118-youtube-frozen-live-measurement]
created: 2026-06-30
updated: 2026-07-01
source: plan
confidence: high
---

## Context

Phase 117 ran a smoke first-contact of the gitignored Ph116 acquire→chunk→extract→ground+consolidate apparatus (companion/research/youtube/) on one real quarantined video (04EL2_Llenc): 95% grounding (21/22), 0 fabrication, ~$0.02–0.05/video. The dominant risk (unpunctuated auto-captions → strict normalization over-drops genuine quotes → reads as "thin video") was largely REFUTED (modern auto-captions are punctuated); the real A1 surface re-oriented to ASR word-errors that ground faithfully ("pie"=Pi, "agent.d"=agents.md). The verdict was GO to the full frozen measurement — but on n=1, and with the extractor being a rail-AWARE session model (a plausibly upper-ish estimate). This phase runs that full pre-registered measurement.

Five Phase-118 planning questions were left open at the Ph117 debrief and this plan resolves each: (Q1) the Ph117 "rail byte-unchanged, git-diff-verified" claim is VACUOUS — `git ls-files companion/` is empty (the whole tree is gitignored, no tracked baseline to diff), so a rail edit would not be caught; (Q2) the anchor "git ancestry + SHA-256 of fetched ids" can only bind a TRACKED file, yet the corpus is search-query-selected (ids discovered at fetch, not knowable at prereg) — a selection-determinism vs anchor-binding tension; (Q3) A1 must use AUDIO as ground truth (grounding proves a quote is in the caption, not that the caption heard the word right) and the inversion cross-check must run OUTSIDE the kit (Ph80 leak); (Q4) the A2 denominator + corpus size N vs the 30% threshold + the min-success floor; (Q5) which extractor produces the headline number (rail-blind API Sonnet-4.6 vs rail-aware Claude-as-extractor).

Two adversarial reviews stress-tested the design and forced five constraints (C1–C5). A late upgrade at the Step-13 gate promoted the Ph116 option-B novelty signal from a bare inadmissible tag to a CONTROLLED per-concept bare-model recovery screen — because a novelty tag without a bare-model control is the un-controlled version of the project's own signature method (Ph58/59/78 research-injection nulls) and would be confounded by a corpus that is post-cutoff BY CONSTRUCTION.

## Decision

Run a FROZEN, pre-registered feasibility measurement — a GO/NO-GO at n≈12, NOT a population rate estimate — of the gitignored apparatus, with anti-retrofit discipline (Ph87 three-tier authority; Ph97 `.frozen` lineage) plus a controlled per-concept bare-model recovery screen kept OUT of the mechanical verdict.

Components:
1. **A frozen `pre-registration.md`** — a deterministic selection function (templated queries over a pinned tool list + fixed sort/locale/date-window + dedupe + a predicate that CANNOT drop no-caption/blocked videos + N=12); cost stops; the A1 audio rubric; A2 directional classification; the novelty recovery protocol; a mechanical PASS/FAIL truth table stated as mechanical ONLY over {grounding-rate, cost, A2-count, instrument-controls}; a min-success floor (<4 above-floor successes OR <20 pooled concepts → INCONCLUSIVE) — plus `rail.sha256` and a `prereg.sha256` self-seal (no in-phase amend).
2. **A two-stage tamper-evident anchor** — PREREG commit pushed before search ⟶ CORPUS-FREEZE commit = SHA-256 of the SELECTED ids before any fetch ⟶ RESULTS commit; verify = git ancestry + frozen-id-set == telemetry-id-set (every id accounted, incl. not-run) + a keystone `ground()` re-derivation on the gitignored sidecar whose committed hash matches; any mismatch = VOID.
3. **harness118** — a batch runner with a rail-BLIND API-path Sonnet-4.6 extractor (no grounding hint, pinned forbidden-token list), a $10/batch cap, per-id accounting (every frozen id incl not-run), non-optional-stopping resume over the FIXED frozen N (not until-4-successes), retaining Ph117 pacing/circuit-breaker/probe-abort.
4. **Controls-first instrument gates** — splice / audio-vs-caption misread / classifier, each catching a seeded defect (clean-on-seed = instrument-dead, HEU-012).
5. **Judgment-layer scorers** — A1 audio rubric + external-inversion two-key VOID + full audit log; A2 directional + soft-block re-probe; novelty bare-model recovery OUTSIDE the kit (pinned judge/cutoff/prompt).
6. **A mechanical truth-table evaluator** keeping A1 + novelty OUT of the verdict.
7. **ToS containment** — verbatim only under gitignored `run118/`; `.dev-wiki/phase-118/` carries aggregates + hashes only (gate = `git grep source_quote` whole-repo + `git check-ignore run118`).

The live fetch is manual-drive on a residential IP; deterministic tests run on fixtures + a mocked client.

### Alternatives considered + rejected
- **(A) A cheap value pre-screen FIRST** on the 21 Ph117 concepts — rejected: the maintainer chose feasibility-first ordering (feasibility gates the value screen, not the reverse).
- **(B firewall) Novelty as an inadmissible tag** — rejected in favor of the controlled recovery upgrade (an uncontrolled tag repeats the Ph58/59 commodity-recall confound on a post-cutoff-by-construction corpus).
- **(C) Pure feasibility, no novelty** — rejected: it would tee up nothing for the Ph119 value screen (the Ph58/59 commodity trap in reverse).
- **(D) A population RATE estimate at n≈30+** — rejected: breaks the cost/IP budget; this is a GO/NO-GO, not a rate.

## Consequences

- The anti-retrofit anchor + the rail and prereg SHA-256 seals + ToS containment are LOAD-BEARING invariants; the rail git-diff is vacuous (gitignored tree) so the SHA-256 seal REPLACES it, and the prereg self-seal forbids in-phase amendment (a post-unblinding amendment VOIDs the verdict — Ph87 three-tier).
- The novelty recovery is admissible only scoped-to-post-cutoff and NEVER enters the mechanical verdict — it feeds the Ph119 value screen's admissible-scoped novelty distribution, nothing here.
- The full downstream VALUE screen (does grounded retrieval beat a bare model in a real decision) is Phase 119, NOT this phase.
- The measurement is a feasibility GO/NO-GO at n≈12 with A2 DIRECTIONAL (not a mechanical whisper-trip) — the population rate remains unmeasured; INCONCLUSIVE is a valid, honest outcome under the floor.
- The Ph117 smoke video (04EL2_Llenc) stays QUARANTINED from the frozen corpus (seeing its output would break the freeze).

## Outcome (BUILT + twice-adversarially-reviewed 2026-07-01; live T9 run PENDING)

Implementation complete — 8/9 tasks [x]; T9 (the live manual-drive RUN) is the orchestration scaffold only (built + green), awaiting the maintainer at the PREREG-commit checkpoint. The phase stays **active** (NOT completed; the delivery gate does NOT flip). The design survived construction largely intact, with two anti-retrofit sharpenings the reviews forced:

- **The rail seal is not vacuous** — `rail.sha256` recomputes-and-MATCHES the 4 byte-frozen rail files (verified at debrief; a mutated-rail scratch copy mismatches). The gitignored-tree git-diff Ph117 relied on is confirmed to pass trivially, so the SHA-256 seal genuinely replaces it.
- **Two sequential ultracode adversarial-review Workflows** (18 + 20 agents, ~2.05M subagent tokens, 6 dimensions × find→adversarial-verify each) caught **22 confirmed findings (3 HIGH each pass)** that green TDD missed — the tests asserted intended behavior; the reviews found what a caller/operator could OMIT or DRIFT. All fixed inline + regression-tested. The load-bearing HIGHs were genuine anti-retrofit holes: (R1) `corpus.sha256` was written but never read back; (R1) the keystone re-derivation was bypassable by omitting a sidecar; (R2) `is_terminal` enumerated a terminal-outcome set that omitted 4 real outcomes, so a legitimate resume would double-count a row and VOID the anchor. Fix pattern that recurred: **bind every decision input to a verified source** — read frozen ids/aggregates back from the git-tracked commit (`git show`), derive terminal-ness from the emitted vocabulary (every outcome terminal except the provisional `not-run`), drive controls from the DATA (telemetry) not caller args, derive verdict scalars from keystone-verified aggregates not hand-typed ints.
- **Reallocations (DISCOVERY):** the audio-vs-caption misread control moved T5→T6 (its checker IS the A1 rubric); `check_idset` made resume-supersession-aware (append-only telemetry + resume = legit multiple rows/id, only the latest terminal); the ToS gate uses a quote-agnostic `source_quote`-VALUE pattern (a bare-word grep false-positives on tracked prose). `pre-registration.md` was amended pre-freeze for internal consistency then re-sealed — construction-phase edits BEFORE the load-bearing T9 freeze, per the file's own contract (the T9 PREREG checkpoint is the sanctioned amendment point).

Health: companion pytest **78 → 169** (+91); rail byte-frozen (SHA-256 seal verifies); ToS containment CLEAN; `run118/` gitignored. The four Phase-118 assumptions (A1 value-signal, A2 rail-blind grounds, A3 non-gameable selection, A4 novelty-recovery affordability) are genuinely open — they resolve at the live run.

## Source

Phase 118 plan (2026-06-30). Build + two adversarial reviews (2026-07-01). Direction confirmed at the assumption gate (ledger Phase-118 all_accept:false — A1/A2/A3-strengthened/A4 accept; two adversarial reviews folded: C1 deterministic selection, C2 freeze-the-selected-corpus-pre-fetch + account-for-every-id, C3 SHA-256 seal + keystone re-derivation, C4 feasibility frame + non-optional-stopping resume, C5 novelty-as-controlled-recovery-out-of-verdict, + a prereg self-seal). Standard ceremony; spec `specs/phase-118-youtube-frozen-live-measurement.md` (nana:approved). First-full-measurement rung of [[youtube-grounded-acquisition]] (Ph116) / [[youtube-liverun-derisk]] (Ph117) on the Ph97 rung-B ladder ([[frontier-positioning-sweep]]); anti-retrofit authority from [[stage2-episode-execution-design]] (Ph87 three-tier); clean-context discipline from [[assumption-surfacer-completeness-screen]] (Ph80); grounding + orchestrator-only verification from [[qa-verification-sweep]] / [[HEU-012]]. Confidence high.
