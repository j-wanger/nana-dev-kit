---
title: "Phase 116 — YouTube→wiki grounded acquisition core (rung-B foundation): BUILT"
aliases: []
category: journal
tags: [youtube, research-pipeline, grounding, provenance, rung-b, companion-apparatus, pi-setups, normalization, phase-116]
parents: [phase-116-youtube-grounded-acquisition]
created: 2026-06-30
updated: 2026-06-30
source: debrief
duration: long
---

# Phase 116 — YouTube→wiki grounded acquisition core (rung-B foundation): BUILT (6/6 tasks)

## What Happened
- Built the acquisition + grounded-extraction CORE of the Phase-97 rung-B standing research pipeline, specialized to YouTube, as a manual-trigger Python apparatus under gitignored `companion/research/youtube/`. Turns one Pi/agent-setup video into a grounded, provenance-carrying concept set — each concept tied to a verbatim, mechanically-verified transcript quote + timestamp — written to feed a Pi-setups wiki via the EXISTING `wiki-add`→`wiki-absorb` skills. NOT a shipped kit skill (the Ph97 "research apparatus stays local, never shipped" precedent); the continuous half (RSS / scheduler / dedup-watermark / Telegram digest) is deferred to nanaclaw.
- Loop, TDD across 6 tasks: **T1** acquire (captioned-first, VTT parse, WORD_FLOOR=200 dead-letter, above-floor success control) + canonical/match normalization (entity-decode×2 + NFC + rolling-caption-dup collapse; match-norm = casefold + curly/dash-fold) + nested `.gitignore`; **T2** chunking (~1000-word / 15% overlap windows carrying the segment→time map, no-gap/cover-to-end invariant); **T3** extraction (mocked Claude via a `complete_fn` DI seam, extraction-by-selection = verbatim `source_quote` + ≤40-word claim + timestamp, frozen immutable `Concept`, tolerant JSON parse) + a pre-flight cost ceiling (`CostCeilingError` on calls/tokens unless `--confirm`); **T4 [CHECKPOINT]** the load-bearing grounding rail (symmetric `match_normalize` substring verify, drop+log ungrounded) + the calibration probe (perturbs a verbatim span, `CalibrationError` loud-abort on broken normalization) + consolidation (dedup by normalized quote, IMMUTABLE quote+timestamp, re-verifies the MERGED set) — the planted-fabricated-quote rejection PASSED, reported, maintainer pre-authorized the full run; **T5** end-to-end wiring (`ingest.py` CLI) + atomic temp+`os.replace` write + regression gate on grounded-quote count (refuses degraded clobber without `--force`, positive write control) + markdown-neutralization (`[[`/leading-`---`/backtick runs) + an authoritative `~~~json` round-trip block + completion marker; **T6** README (manual trigger + companion-venv setup + provenance-preserving `wiki-absorb` hand-off) + full gate + 2-round adversarial review + BUILT.
- Deps installed to a companion-local gitignored venv only (uv; youtube-transcript-api 1.2.4 / yt-dlp 2026.6.9 / anthropic 0.115.0) — never `install.sh`. Tests are hermetic (lazy/injected deps, no network); live multi-video first-run is manual-drive (residential IP), deferred to the maintainer.

## Decisions Made
- [[youtube-grounded-acquisition|YouTube→wiki grounded acquisition core (rung-B foundation)]] (high) — authored during planning; not recreated at debrief (dedup).
- Within-phase engineering decision (captured in the phase article's Review & Residuals, not a separate article): REVERTED the punctuation-strip in `match_normalize` after a re-attack showed it re-opened the anti-fabrication invariant to cross-sentence splices ("ship it today. Cats are great" → grounded); kept casefold + curly/dash-fold only. A manual-track quote that drops an INTERNAL comma is now a SAFE false-negative.

## Problems Solved
- **The adversarial review (2 rounds, orchestrator-verified — subagent prose = candidate-only per [[HEU-012]]):** a 5-lens finder workflow (grounding-symmetry / markdown-injection / atomic-clobber / test-hermeticity / provenance-immutability) raised 22 findings (5 HIGH), then a focused re-attack on the fixes. 5 HIGH + meaningful MED/LOW fixed inline with 16 regression tests (`tests/test_review_fixes.py`) under the DISCOVERY/SECURITY escape hatch — casefold so the calibration probe survives non-ASCII (German ß was aborting the whole video); tilde-fence-safe neutralization + a line-anchored, last-block, never-raises parser (a quote ending `~~~json` forged the fence → parse crash); refuse-to-clobber unparseable/hand-edited files; per-quote timestamps from the segment→time map (was the chunk start, ~minutes off); the vacuous E2 boundary test (passed at zero overlap).
- **Live-path provenance bug (found in T5):** the CLI collapsed a fetched transcript to one pseudo-segment → split `fetch_segments` out of `acquire` so the segment→time map survives into `run_pipeline`.

## Open Questions
- None unresolved. Direction gate closed (ledger Phase-116 all_accept:false — A1/A2 accept, A3 reject→Standard); residuals documented and accepted.

## Artifacts Changed
- `companion/research/youtube/{acquire,normalize,chunk,extract,schema,ground,consolidate,ingest,write}.py` + `README.md` + `requirements` + `.gitignore` + `tests/{test_acquire,test_chunk,test_extract,test_ground,test_pipeline,test_review_fixes}.py` (all NEW, all gitignored) — full companion suite 53/53 pytest green; `git check-ignore companion/research/youtube` confirms nothing shippable.
- `.dev-wiki/articles/phases/phase-116-youtube-grounded-acquisition.md` (status comment → BUILT, 6/6, delivery pending) + `.dev-wiki/{_CURRENT_STATE,index,log,tasks}.md` + `.dev-wiki/assumption-ledger.md` (Phase-116 revisit filled A1/A2/A3 held).
- NO shipped-kit change (`app/`, `templates/`, `install.sh`, `make test` all untouched); companion/ stays gitignored — the shipped-architecture inventory is unchanged.

## Related
- [[phase-116-youtube-grounded-acquisition|Phase 116: YouTube→wiki grounded acquisition core]] -- parent phase.
- Foundation increment of the Ph97 rung-B ladder ([[frontier-positioning-sweep]]); grounding inherits the verify-by-re-fetch lineage ([[qa-verification-sweep]], [[HEU-012]]).

## Soft Observations / Phase N+1 Candidates
- LIVE multi-video first-run (the deferred manual-drive step): run the apparatus on ~10-15 real Pi/agent-setup videos to measure the captioned/dead-letter rate (validates A2), per-video token cost (validates the cost model), and whether grounding catches real hallucinations on real content. | Phase-117 candidate (maintainer-driven). | Evidence: `companion/research/youtube/`, ledger A2.
- Rung-B CONTINUOUS half (RSS discovery + scheduler + dedup-watermark + Telegram digest). | a future phase in the nanaclaw project, NOT nana-dev-kit. | Evidence: decision [[youtube-grounded-acquisition]] "continuous half deferred to nanaclaw".
- whisper.cpp ASR fallback for uncaptioned videos. | pull forward IF the live dead-letter rate is high (A2 revisit). | Evidence: ledger A2.
- A deterministic wiki-absorb provenance-preservation check (currently instruction-only in the README, rides the human gate). | tighten if provenance drifts in practice. | Evidence: S2 residual, phase article.
- Pre-pivot GUI-harness candidates still open (deferred by this pivot): renderer-trust hardening / blocking out-of-workspace READ (Ph112 residual) / multi-workspace localStorage LRU. | a future GUI-harness phase. | Evidence: Ph115 Cross-References.
