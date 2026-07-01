---
title: "Phase 117: YouTube apparatus first-contact (derisk the mock-vs-real gap + harden for real tracks)"
aliases: [phase-117, youtube-liverun-derisk, youtube-first-contact, mock-vs-real-derisk, rung-b-smoke]
category: phases
tags: [youtube, research-pipeline, grounding, provenance, rung-b, companion-apparatus, pi-setups, live-run, telemetry, anti-retrofit, phase-117]
parents: []
created: 2026-06-30
updated: 2026-06-30
source: plan
status: completed  # DELIVERED 2026-06-30, 6/6 tasks [x]; Standard ceremony; smoke-first. BUILT the telemetry+hardening layer around the byte-frozen Ph116 rail (companion pytest 53→78); a T4-T6 4-lens adversarial review (orchestrator-verified per HEU-012) caught 2 HIGH + MED, all fixed inline. T5 RAN (Claude-as-extractor, residential IP, video 04EL2_Llenc): 95% grounding, 0 fabrication, ~$0.02-0.05/video. VERDICT: GO to Phase 118, but the punctuation-over-drop dominant risk was REFUTED (modern auto-captions are punctuated) → A1 re-oriented to ASR word-errors. ledger Phase-117 all_accept:false (A1 bit, A2-A6 held); direction+delivery gates both closed
scope: ["companion/research/youtube/** (telemetry + hardening + harness117.py + tests; verbatim quotes only under gitignored run117/; grounding rail byte-frozen)", ".dev-wiki/** + .dev-wiki/phase-117/ (aggregates only)", ".claude/rules/active-phase.md", "specs/phase-117-*.md"]
entry_criteria: "Phase 116 committed (1fa9de4); the maintainer asked to plan the live run. A design workflow reframed it: the 'live run' is NOT a quick point-it-at-videos — the apparatus discards msg.usage (cost unmeasurable), the T4 grounding rail has never met a real model (the mock grounds by construction; real Sonnet adds punctuation vs the strict normalization → genuine quotes may over-drop on auto-caption tracks and read as 'thin video'), and a tracked .dev-wiki/phase-117/ would leak verbatim transcript. Sequenced smoke-first (maintainer chose derisk-1-2-videos over building the full frozen rig sight-unseen). Direction gate closed: A1/A2/A3/A5/A6 accept, A4 reject→search-query frame; --gate 117 exit 0."
exit_criteria: "pytest ≥53 green + git diff --quiet on the 4 rail files (ground/normalize/consolidate/schema byte-unchanged); usage/cost/killswitch tests green; adversarial-fixture + drop-diagnosis green (reformatted → present-modulo-punctuation/ground, fabrication → absent-even-stripped); no-blind-retry + empty200 + taxonomy green; pacing + circuit + probe-abort-tripwire green; git check-ignore run117/ + a grep gate finds no verbatim source_quote under .dev-wiki/phase-117/; the manual-drive smoke run writes run117/telemetry.jsonl rows (usage/cost/chunks_n/outcome_class + reformatting-vs-fabrication drop histogram) with a STOP-after-first-video recorded; results.md records real per-video cost, the drop split, whether genuine concepts grounded, the go/no-go on the Phase-118 frozen measurement + hardening list, and the recommended Phase-118 pre-registration parameters. The live smoke drive is manual-drive (maintainer)."
---

# Phase 117: YouTube apparatus first-contact (derisk the mock-vs-real gap + harden for real tracks)

## Objective

Before committing to the full frozen live measurement (deferred to Phase 118), cheaply derisk the dominant risk that the Phase-116 apparatus — proven only on a mock that grounds *by construction* (`tests/test_pipeline.py` returns `words[:6]` verbatim from the chunk) — over-drops genuine quotes on real Sonnet-4.6 output and real (often unpunctuated auto-caption) tracks, since `normalize.py` deliberately keeps punctuation strict (the Ph116 anti-fabrication revert). Add the minimum telemetry to make a smoke run informative, harden the acquisition path the mock never exercised, keep verbatim transcript inside the gitignored boundary (ToS), run 1–2 real quarantined videos manual-drive, and **decide** whether the apparatus is sound enough on real data to warrant the Phase-118 measurement — and what must be hardened first. Feasibility gates the measurement; the measurement gates the headroom/value screen (a later rung, NOT this phase).

## Scope

All changes confined to the gitignored `companion/research/youtube/` apparatus + planning artifacts:
- `extract.py` (usage/cost capture + `$2/video` kill-switch), `ingest.py` (`drops_by_reason` + `chunks_n` on the return)
- `acquire.py` (`fetch_segments` no-blind-retry + 200-empty detection)
- NEW `harness117.py` (catch-and-classify wrapper + reformatting-vs-fabrication drop diagnosis + pacing/circuit-breaker + verbatim-quote sidecars under gitignored `run117/`), NEW test modules
- `.claude/rules/active-phase.md`, `.dev-wiki/**` + `.dev-wiki/phase-117/` (aggregates + SHA-256 only — never verbatim quotes), `specs/phase-117-*.md`

Explicitly OUT of scope: any shipped-kit change (`app/`, `templates/`, `install.sh`, security/engine surface); **the grounding rail is byte-frozen** (`ground.py`/`normalize.py`/`consolidate.py`/`schema.py` unchanged — `git diff --quiet` asserts); the full frozen measurement (frozen corpus / A1 human rubric / pre-committed thresholds + fail-actions / controls-first M1–M8 → Phase 118); whisper.cpp; the headroom/amplifier screen; a rail-normalization change (a fix chosen blind to real data is premature → a named Phase-118 task with its own freeze).

## Approach

A telemetry-and-hardening layer wrapped strictly *around* the frozen rail, then a small manual smoke drive whose only job is to make the two Ph116 residuals (A1 misread, A2 dead-letter) and cost interpretable on real data. Telemetry threads `msg.usage` + `stop_reason` out of `_complete` (discarded today) for per-video cost at pinned Sonnet-4.6 $3/$15 + a `$2/video` kill-switch. The load-bearing diagnostic: `harness117` re-tests every `quote-not-in-chunk` drop under a *diagnosis-only* punctuation-stripped normalization → `present-modulo-punctuation` (benign reformatting — the strict normalization is the culprit) vs `absent-even-stripped` (candidate fabrication — the rail is doing real work); without this split, an apparatus over-drop is indistinguishable from a genuine thin video (the C1/Ph80 "silent drop reads as thin video" failure). A real-model adversarial fixture pins the keep/drop expectation before any live fetch. Acquisition hardening fixes `fetch_segments`' blind retry (halves endpoint hits + surfaces the true first exception) and adds 200-empty soft-block detection + an exhaustive taxonomy. ToS containment confines verbatim quotes to gitignored `run117/`. IP protection: inter-fetch cooldown + a circuit-breaker halting on block / 2 consecutive endpoint-errors. Full contract: `specs/phase-117-youtube-liverun-derisk.md`. Decision: [[youtube-liverun-derisk]].

## Constraints (adversarial-pass-caught, folded in)

- **Rail byte-freeze (load-bearing):** `ground/normalize/consolidate/schema` byte-unchanged (`git diff --quiet` is an exit criterion); telemetry/diagnosis/hardening live only in `extract.py`/`ingest.py`/`acquire.py`/`harness117.py`.
- **ToS containment (load-bearing):** no committed file (esp. the tracked `.dev-wiki/phase-117/`) carries a verbatim `source_quote`; verbatim text only under gitignored `run117/` (grep + `git check-ignore` gate).
- **Drop signal interpretable (C1/Ph80):** a `quote-not-in-chunk` drop is sub-classified reformatting-vs-fabrication before any drop-rate is read; >1 probe-abort (`CalibrationError`) is a brittleness STOP, not a benign exclusion.
- **Cost + IP:** `$2/video` kill-switch from captured usage; preflight chunk-count printed before any paid call; inter-fetch cooldown + circuit-breaker; residential egress confirmed; smoke videos quarantined from any Phase-118 corpus (no freeze contamination).

## Checkpoints

- After T4 (ToS containment + rail-byte-freeze proof): STOP + report — before any live fetch touches transcript data.
- After the FIRST smoke video (before the second): STOP + report — a systematic apparatus bug must not burn both; a reformatting-dominated drop IS the go/no-go signal.

## Residuals (accepted)

The A1/A2 rates are FIRST-MEASURED here but only DIRECTIONALLY on 1–2 videos (the population estimate + pre-registered thresholds are Phase 118); whisper.cpp deferred (uncaptioned → dead-letter); the live smoke drive is manual-drive (residential IP, real tokens; deterministic tests use fixtures + a mocked client).
