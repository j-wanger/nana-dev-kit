---
title: "Phase 117 — YouTube apparatus first-contact: BUILT + T5 ran, dominant-risk hypothesis flipped"
date: 2026-06-30
type: journal
phase: 117
tags: [youtube, rung-b, mock-vs-real, grounding-rail, asr-errors, adversarial-review, heu-012, phase-117]
---

# Phase 117 — first-contact (derisk mock-vs-real + harden)

## What happened

Planned + built + ran the first-contact smoke increment of the Ph116 YouTube apparatus in one session.
Smoke-first (maintainer chose derisk-1-2-videos over building the full frozen rig sight-unseen; the full
frozen measurement is Phase 118). Wrapped a telemetry + hardening layer AROUND the byte-frozen Ph116
grounding rail (`ground`/`normalize`/`consolidate`/`schema` git-diff-verified UNCHANGED across every task):
usage/cost capture + `$2/video` kill-switch (`extract.py` discarded `msg.usage` before); a
reformatting-vs-fabrication-vs-splice drop DIAGNOSIS (diagnosis-only punctuation-strip, never a grounding
path); acquisition hardening (`fetch_segments` removed the blind `api.fetch` retry so block/no-caption
propagate one-hit; class-name taxonomy); `harness117` smoke runner + circuit-breaker + CLI. ToS containment:
verbatim quotes ONLY under gitignored `run117/`. Companion pytest 53 → 78 green.

## The payoff — smoke-first flipped the central hypothesis

The phase existed to derisk the assumed dominant risk: *auto-captions are unpunctuated → the strict
punctuation normalization over-drops a real model's verbatim quotes*. **T5 refuted it.** Modern YouTube
auto-captions are **punctuated and capitalized**; a compliant model's verbatim quotes ground at 95% (21/22),
the `present-modulo-punctuation` bucket was **empty**, zero fabrication. The single drop was a deliberate
cross-sentence merge, correctly flagged by the new `present-spanning-sentence-boundary` bucket.

The REAL A1 surface that emerged: **ASR word-errors that ground faithfully** — the caption said "pie" (Pi),
"agent.d" (agents.md), "{slash}" (/). Grounding verifies presence-in-caption, not caption-correctness — which
is exactly why the Ph118 A1 rubric uses **audio** as ground truth. VERDICT (Claude-as-evaluator, per
maintainer instruction): **GO to Phase 118 (feasibility confirmed, n=1) with the A1 concern re-oriented from
punctuation to ASR errors; a rail-normalization change is NOT indicated (byte-freeze held for the right reason).**

## Escape hatches / deviations

- **USER OVERRIDE (T5):** maintainer directed "no API key needed, you be the evaluator" → Claude-as-extractor
  (session model did extraction-by-selection; the frozen pipeline ran unchanged). A deviation from the planned
  API-drive; representative (a real frontier model) but rail-aware, so 95% is an upper-ish estimate.
- **USER OVERRIDE (A4):** search-query corpus frame chosen over the agent's channel-seed recommendation.
- **DISCOVERY/SECURITY:** the T4-T6 adversarial review found defects → fixed inline (below).
- **Corrected a wrong claim:** the agent asserted "this env is IP-blocked cloud + keyless" without testing;
  a probe showed a residential Rogers IP (Jake's Mac) where the transcript fetch works — the claim was wrong,
  corrected empirically. Lesson: probe network/environment assumptions before asserting them as fact.

## Health Delta

- Companion pytest: **53 → 78** (18 build tests + 7 adversarial-review-fix tests). No network in the test path.
- Grounding rail: **byte-unchanged** (git diff --quiet on the 4 files, verified after every task + every fix).
- Shipped kit `make test`: **unchanged** (zero shipped-kit change; apparatus gitignored).

### Review Gate

A T4-T6 4-lens adversarial review (finder workflow, every finding ORCHESTRATOR-VERIFIED by running the code
per [[HEU-012]]) caught **2 HIGH + several MED**, all fixed inline + regression-tested:
- HIGH — `YouTubeRequestFailed` (the lib's class for ALL non-429 HTTP errors) mapped to `unclassified`, so a
  throttled IP would never trip the circuit-breaker → mapped to `endpoint-error` + a broadened endpoint-suspect
  streak (also catches alternating soft-block + version-drifted block classes).
- HIGH — `run_batch`/`run_one` were not exception-complete; a `consolidate`/write failure would kill the whole
  batch → guarded (recorded `error` row + spend preserved).
- MED — `usage_cost` crashed on a `None` token value; `budget_usd` silently failed open without a sink; a
  cross-sentence splice was mis-diagnosed as benign reformatting (→ the 3-way split); `PoTokenRequired`/
  `VideoUnplayable` unmapped; a skipped write mislabeled `success`.

### Gate Compliance

Direction gate: approved (ledger Phase-117 all_accept:false — A1/A2/A3/A5/A6 accept, A4 reject→search-query;
`--gate 117` exit 0). Delivery gate: accepted this debrief (maintainer "Yes"). Both boundary gates present.

## Soft Observations / Phase N+1 Candidates

- **Phase 118 = the frozen live measurement**, now with the A1 concern **re-oriented to ASR word-errors** (not
  punctuation). Recommended pre-reg params already recorded in `.dev-wiki/phase-117/results.md` (search-query
  frame, A2 threshold 30%, A1 solo + mandatory external inversion cross-check, cost stops, tamper-evident
  anchor = git ancestry + SHA-256 of fetched ids, PASS/FAIL truth table, min-success floor).
- **Add an API-path extraction run** (a rail-blind compliant model) to Phase 118, to complement the rail-aware
  Claude-as-extractor smoke and bound the grounding rate honestly.
- **Wiki hand-off normalization:** slash-commands come through the caption as "{slash} model" etc. — the
  `wiki-absorb` hand-off must normalize "{slash}" → "/" (and flag ASR word-errors) at synthesis.
- **Reusable insight (candidate /wiki-capture):** modern YouTube ASR auto-captions are punctuated + capitalized
  but carry word-level mishears — for any transcript-grounded pipeline, the risk is ASR word-errors, not
  punctuation. Grounding-verifies-presence-not-correctness.
