---
title: "YouTube apparatus first-contact — derisk the mock-vs-real gap + harden for real tracks (smoke-first)"
aliases: [youtube-liverun-derisk, youtube-first-contact, mock-vs-real-derisk, rung-b-smoke, phase-117]
category: decisions
tags: [youtube, research-pipeline, grounding, provenance, rung-b, companion-apparatus, pi-setups, live-run, telemetry, anti-retrofit, phase-117]
parents: [phase-117-youtube-liverun-derisk]
created: 2026-06-30
updated: 2026-06-30
source: plan
confidence: high
---

## Context

Phase 116 built the acquire→chunk→extract→ground+consolidate core (local gitignored apparatus, 53/53 pytest green, committed `1fa9de4`), proven entirely against fixtures + a mocked Anthropic client. The maintainer asked to "commit and plan the live run." Committing was already done (`1fa9de4`); the live run is this planning target.

The frame did not survive contact. A design workflow (a 3-stance judge panel + 3 adversarial lenses, 43 holes) surfaced that the "live run" is not a quick "point it at videos":
- **The apparatus cannot measure its own cost** — `_complete` (extract.py) discards `msg`, so `msg.usage` is lost; cost feasibility is unmeasurable without a telemetry patch. Model is hardwired to `claude-sonnet-4-6` ($3/$15 per 1M).
- **The T4 grounding rail has never met a real model** — the test mock returns `words[:6]` verbatim from the chunk, so every fixture quote grounds BY CONSTRUCTION. Real Sonnet adds punctuation + expands contractions, while `normalize.py` deliberately keeps punctuation strict (the Ph116 anti-fabrication revert). On unpunctuated auto-caption tracks (the majority track), genuine quotes may over-drop as `quote-not-in-chunk` — which the pipeline reads as "thin video." This is the dominant risk, invisible in the green suite.
- **A hard ToS leak** — the (adversarially-designed) A1 sample would carry verbatim transcript into the TRACKED `.dev-wiki/phase-117/` (`git check-ignore` confirmed it is not ignored), redistributing YouTube transcript excerpts into the shippable repo — breaking the exact non-redistribution posture that justifies the apparatus being gitignored.

## Decision

Sequence the live run as a **smoke-first derisk + harden** increment (Phase 117), deferring the full frozen live measurement to **Phase 118**. Rationale (maintainer chose this over building the full frozen rig sight-unseen): the mock-vs-real gap is cheap (~$1, an hour) to derisk on 1–2 real videos, and if the apparatus over-drops genuine quotes on real tracks, building the elaborate frozen measurement first would only run a garbage-drop apparatus through an expensive ritual. Feasibility gates the measurement; the measurement gates the value/headroom screen (a later rung, explicitly NOT this phase).

Phase 117 wraps a telemetry + hardening layer strictly AROUND the byte-frozen Ph116 rail, then runs a small manual smoke drive:
- **Telemetry** — thread `msg.usage` + `stop_reason` out of `_complete`; per-video cost at $3/$15; a `$2/video` mid-loop kill-switch; surface `ground()`'s per-reason drop counts; print the preflight chunk count.
- **The load-bearing diagnostic** — `harness117` re-tests every `quote-not-in-chunk` drop under a diagnosis-only punctuation-STRIPPED normalization (never used for grounding): `present-modulo-punctuation` (benign reformatting — the strict normalization is the culprit) vs `absent-even-stripped` (candidate fabrication — the rail is doing real work). Without this split, an apparatus over-drop is indistinguishable from a genuine thin video (the C1/Ph80 "silent drop reads as thin video" failure).
- **A real-model adversarial fixture** — a mock returning quotes with real-model transformations (added punctuation / expanded contraction / ellipsis / curly quotes) + one true fabrication, pinning the keep/drop expectation BEFORE the live run so the live drop-rate is interpretable.
- **Acquisition hardening** — `fetch_segments` re-raises block/no-caption classes WITHOUT the blind `api.fetch()` retry (one endpoint hit; the classifier sees the true first exception); 200-empty soft-block detection (raw HTTP status + byte-size); exhaustive exception taxonomy (`AgeRestricted`; `except → unclassified`).
- **ToS containment** — all verbatim-quote-bearing artifacts only under gitignored `run117/`; `.dev-wiki/phase-117/` carries aggregates + SHA-256 only (grep + `git check-ignore` gate).
- **IP protection** — inter-fetch cooldown + a circuit-breaker halting on `IpBlocked`/2-consecutive-endpoint-errors; residential-egress confirmed before fetching; smoke videos QUARANTINED from any Phase-118 corpus.

Then a manual-drive 1–2-video smoke run (STOP after the first), a decision on go/no-go for Phase 118, and a `results.md` recording real cost, the reformatting-vs-fabrication drop split, whether genuine concepts grounded, and the recommended Phase-118 pre-registration parameters.

### Direction-gate forks (ledger Phase-117, all_accept:false)
- **A4 corpus frame (maintainer REJECTED channel-seed → SEARCH-QUERY):** a topical-search selection stresses the uncaptioned/auto-caption long-tail (smaller creators) harder — the regime where both A2 and the punctuation gap bite — so the smoke video is a stronger stress test than a curated channel. (For Phase 118, search-query is the recommended frame; it is a weaker proxy for the eventual RSS feed, a named validity limit.)
- **A6 A1 rigor (maintainer chose solo + MANDATORY clean-context LLM inversion cross-check):** run OUTSIDE nana-dev-kit so the always-loaded working-knowledge cannot leak (Ph80). Single-rater self-judgment is the deepest A1 residual; the mandatory external inversion pass is the cheapest available second opinion, over solo-planted-control-only and over recruiting a second human rater.
- **Scope (maintainer chose smoke-first)** over building the full frozen rig now (max anti-retrofit integrity, but commits the full build before seeing one real video) and over a minimal directional peek (no anti-retrofit guarantees).

### Alternatives considered + rejected
- **(A) Build the full pre-registered measurement rig now** — maximum anti-retrofit integrity (no peek to contaminate the freeze), but commits the full harness + corpus freeze + A1 rubric before a single real video; if the mock-vs-real gap is bad, that build measures an apparatus bug. Deferred to Phase 118 (after the smoke go/no-go).
- **(B) Minimal directional peek** (run 2–3 videos, cost + dead-letter only, eyeball, no frozen thresholds) — rejected: fast/cheap but no anti-retrofit guarantees, and no drop-diagnosis so it can't distinguish over-drop from thin video.
- **(C) Edit the rail's punctuation normalization now** to fix suspected over-dropping — rejected as a byte-freeze violation this phase; diagnosis is in scope, a rail change is a named Phase-118 task with its own freeze (a real-model fix chosen blind to real data is premature).
- **(D) Fold the headroom/amplifier screen ("does it beat a bare Opus") into this phase** — rejected: feasibility gates value; you cannot test whether the retrieved content beats a bare model until you know the apparatus produces usable output on real video at acceptable cost.

## Consequences

- New telemetry + hardening confined to `extract.py` closures, `ingest.py`'s return, `acquire.py`, and a NEW `harness117.py` + tests; the grounding rail (`ground.py`/`normalize.py`/`consolidate.py`/`schema.py`) is **byte-frozen** (a `git diff --quiet` on the four files is an exit criterion). Zero shipped-kit change; deps stay in the companion-local gitignored venv.
- Verbatim transcript text is confined to gitignored `run117/`; `.dev-wiki/phase-117/` carries aggregates + SHA-256 only (ToS containment, grep-gated) — closes the leak the adversarial pass found.
- The two Ph116 residuals (A1 misread, A2 dead-letter) are FIRST-MEASURED here, but only DIRECTIONALLY on 1–2 videos — the population estimate + pre-registered thresholds + fail-actions are Phase 118.
- The recommended Phase-118 pre-registration parameters are recorded now (search-query frame; A2 threshold 30%; A1 solo + mandatory external inversion cross-check; cost stops $2/video + $10/batch + 60-call ceiling; tamper-evident anchor = git ancestry + SHA-256 of fetched IDs; an overall PASS/FAIL truth table) — so the freeze is fast and the anti-retrofit discipline (Ph87 three-tier) is honored when 118 runs.
- **RESIDUALS (accepted):** the smoke rates are directional not estimates (Phase 118); whisper.cpp still deferred (uncaptioned → dead-letter); the live smoke drive is manual-drive (residential IP, real tokens; deterministic tests use fixtures + a mocked client).

## Source

Phase 117 plan (2026-06-30). Direction confirmed at the assumption gate (ledger Phase-117, all_accept:false — A1/A2/A3/A5/A6 accept, A4 reject→search-query frame; `--gate 117` exit 0). Standard ceremony: spec `specs/phase-117-youtube-liverun-derisk.md` (nana:approved; adversarial pre-registration design workflow — 3-stance judge panel + 3 adversarial lenses, 43 holes — incorporated). First-contact increment of [[youtube-grounded-acquisition]] (Ph116) on the Ph97 rung-B ladder ([[frontier-positioning-sweep]]); grounding control inherits the Ph97 verify-by-re-fetch lineage ([[qa-verification-sweep]], [[HEU-012]] — orchestrator-only / independent-refetch evidence standard). Confidence high.
