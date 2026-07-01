---
title: "Phase 116: YouTube→wiki grounded acquisition core (rung-B foundation)"
aliases: [phase-116, youtube-grounded-acquisition, youtube-ingest, pi-setups-research, rung-b-foundation]
category: phases
tags: [youtube, research-pipeline, grounding, provenance, rung-b, companion-apparatus, pi-setups, normalization, phase-116]
parents: []
created: 2026-06-30
updated: 2026-06-30
source: plan
status: active  # BUILT 2026-06-30, 6/6 tasks [x], READY FOR COMPLETION, delivery gate PENDING (flips post-commit, D3); Standard ceremony; spec nana:approved; T6 2-round adversarial review (22 findings/5 HIGH, orchestrator-verified) fixed inline +16 regression tests; companion suite 53/53 green, gitignored; ledger Phase-116 all_accept:false (A1/A2 accept, A3 reject→Standard; revisit A1/A2/A3 held)
scope: ["companion/research/youtube/** (NEW, gitignored)", ".claude/rules/active-phase.md", ".dev-wiki/** (planning artifacts)"]
entry_criteria: "Maintainer wants to learn established Pi / AI-coding-agent setup patterns from YouTube ('lots of good resource, don't build from scratch'). Reframed against the Phase-97 rung ladder: this is the rung-B (standing research pipeline) FOUNDATION increment, specialized to YouTube, built as local gitignored apparatus per the Ph97 'research apparatus stays local, never shipped' precedent. Direction gate closed: A1 accept (grounding+selection+wiki-review sufficient, no AML-tier reconciliation), A2 accept (captioned-first, whisper deferred), A3 reject→Standard ceremony."
exit_criteria: "acquire normalizes a fixture VTT to canonical text + a segment→time sidecar and dead-letters an empty-200 + a sub-floor fixture (with an above-floor success control); chunk produces >1 overlapping ~1000-token window with the segment→time map and no dropped text; extract (mocked) yields a schema-valid concept with a verbatim source_quote + ≤40-word claim + timestamp, skips a malformed payload, and the pre-flight cost ceiling aborts above threshold; ground REJECTS a planted fabricated quote, PASSES a genuine one, the calibration probe ABORTS on broken normalization, and consolidate dedups overlapping-chunk duplicates into one concept with ≥1 immutable grounded quote + a re-verified merged set; end-to-end on fixtures writes a concept file with frontmatter provenance + a structured immutable verified field, neutralizes [[/leading---/backticks in quotes, the regression gate refuses a degraded clobber without --force (positive write control passes), and a full run drops a completion marker; README documents the manual trigger + the provenance-preserving wiki-absorb hand-off; full companion pytest suite exit 0 + git check-ignore confirms gitignored; the live multi-video first-run is manual-drive (deferred to the maintainer)."
---

# Phase 116: YouTube→wiki grounded acquisition core (rung-B foundation)

## Objective

Build the acquisition + grounded-extraction CORE of the Phase-97 rung-B standing research pipeline, specialized to YouTube, as a manual-trigger Python apparatus under gitignored `companion/research/youtube/`. It turns one Pi/agent-setup video into a grounded, provenance-carrying concept set — each concept tied to a verbatim, mechanically-verified transcript quote + timestamp — written as files ready to feed a Pi-setups wiki via the existing `wiki-add` → `wiki-absorb` skills. The value clears the subtraction test where re-presentation wouldn't: Pi-specific community setups are genuinely post-cutoff/proprietary — the one amplifier frontier the project has flagged as untested-for-headroom.

## Scope

Files and modules affected (all NEW, all under the gitignored `companion/`):
- `companion/research/youtube/acquire.py` + `normalize.py` (acquisition-norm + match-norm primitives) + `.gitignore`
- `companion/research/youtube/chunk.py`
- `companion/research/youtube/extract.py` + `schema.py`
- `companion/research/youtube/ground.py` + `consolidate.py` (the load-bearing grounding rail)
- `companion/research/youtube/ingest.py` (CLI) + `write.py` (atomic/guarded writer)
- `companion/research/youtube/README.md`, `companion/research/youtube/tests/**`
- `.claude/rules/active-phase.md`, `.dev-wiki/**` (planning artifacts)

Explicitly OUT of scope: any shipped-kit change (`app/`, `templates/`, `install.sh`, security/engine surface); whisper.cpp fallback; the continuous half (RSS/scheduler/dedup-watermark/Telegram digest → nanaclaw); multi-pass extraction; a QMD/BM25 search layer; AML-tier primary-source reconciliation.

## Approach

A staged pipeline (acquire → chunk → extract → ground+consolidate) where each stage carries provenance forward and **grounding is a deterministic gate, not an LLM judgment**. The LLM is used only for extraction, constrained to extraction-by-selection (a verbatim quote + a ≤40-word minimal claim; interpretation deferred to the human-reviewed wiki-synthesis step). The grounding rail's correctness lives in a two-stage normalization kept deliberately separate (acquisition-time entity-decode + NFC + rolling-caption dedup producing canonical text once; match-time whitespace-collapse + case-fold applied identically to the LLM quote and the canonical chunk), guarded by a calibration probe that aborts the run on broken normalization. Only grounded concepts are written; merge keeps quotes immutable and re-verifies the merged set; output is written atomically and guarded against a degraded re-run clobbering a richer prior. Full contract: `specs/phase-116-youtube-grounded-acquisition.md`. Decision: [[youtube-grounded-acquisition]].

## Constraints (adversarial-review-caught, 8 incorporated)

- **C1** normalization SYMMETRY + a calibration probe that aborts on broken normalization (a silent drop otherwise reads as "thin video").
- **C2** merge keeps `source_quote`/`timestamp` immutable + re-verifies the MERGED set (no hole at the last link).
- **C3** atomic temp+rename write + a regression gate on GROUNDED-QUOTE count (deterministic) + a per-video completion marker.
- **C4** neutralize `[[`/leading-`---`/backtick runs in quotes at write time (markdown injection into the wiki).
- **E1** HTTP-200 empty/near-empty body + a sub-200-word transcript → dead-letter, not a successful empty set.
- **E2** segment→time map survives chunking; the boundary-spanning policy is decided explicitly (overlap windows).
- **S1** pinned acquisition-tool version + a pre-flight chunk-count/token cost ceiling before the extraction loop.
- **S2** `verified` is a structured immutable field; the README instructs the wiki hand-off to preserve provenance, not regenerate it.

## Tasks

6 tasks (Standard ceremony, TDD). T4 is the load-bearing CHECKPOINT (STOP + report after the grounding rail proves the planted-fabricated-quote rejection + the calibration probe). See `tasks.md` for the full RED/GREEN/REFACTOR cycles.

## Review & Residuals (accepted)

**Adversarial review (BUILT 2026-06-30):** two rounds — a 5-lens finder workflow (grounding-symmetry, markdown-injection, atomic-clobber, test-hermeticity, provenance-immutability; 22 findings, 5 HIGH) then a focused re-attack on the fixes. Every finding orchestrator-verified by running the actual code (subagent prose = candidate-only). Fixed + regression-tested (16 new tests, `tests/test_review_fixes.py`): **HIGH** — casefold so the calibration probe survives non-ASCII (German ß aborted the whole video); tilde-fence-safe neutralization + a line-anchored, last-block, never-raises parser (a quote ending `~~~json` forged the fence → parse crash); refuse-to-clobber unparseable/hand-edited files (a blockless file was silently overwritten); per-quote timestamps from the segment→time map (was the chunk start, ~minutes off); the vacuous E2 boundary test (passed at zero overlap). **MED/LOW** — probe over-collapse negative arm; MIN_QUOTE_WORDS floor; markdown link/image neutralization; merge-claim cap; S2 verified-only write filter; temp-file cleanup. The re-attack caught that the first punctuation-strip fix *re-opened* the anti-fabrication invariant to cross-sentence splices ("ship it today. Cats are great" → grounded) — REVERTED to casefold + curly/dash-fold only (keeps HIGH#1; the splice can no longer ground; a manual-track quote that drops an INTERNAL comma is now a SAFE false-negative). Full suite 53/53.

Standing residuals (accepted):
- **A1** — grounding catches FABRICATED quotes, not a real quote MISREAD into a wrong claim, nor a faithful-looking sub-span TRUNCATION of a longer real sentence; routed to the human wiki-absorb review (extraction-by-selection + MIN_QUOTE_WORDS shrink the surface). No AML-tier reconciliation.
- **A2** — whisper.cpp deferred; uncaptioned videos dead-letter; rate measured at the first live run.
- Manual-track internal-comma-drop may not ground (safe false-negative); the calibration probe doesn't cover a decode/NFC-only normalizer regression (own unit coverage); the regression gate keys on grounded-quote count (equal-count lower-quality re-run can overwrite); a parseable-but-hand-edited file is treated as machine-managed.
- Live network/API multi-video first-run is manual-drive (residential IP, real tokens; deterministic tests use fixtures + a mocked client). Apparatus stays gitignored — no transcript/derived content reaches GitHub.

## Source

Phase 116 plan (2026-06-30). Standard ceremony: spec `specs/phase-116-youtube-grounded-acquisition.md` (nana:approved; adversarial constraints + Tier-1 8/10-revise incorporated) + a plan reviewer (8/10-revise: T5 split, gitignore build step, RED positive controls). Direction gate ledger Phase-116 all_accept:false (`--gate 116` exit 0). Foundation increment of the Ph97 rung-B ladder ([[decision:frontier-positioning-sweep]]); grounding inherits the Ph97 verify-by-re-fetch lineage ([[decision:qa-verification-sweep]], [[HEU-012]]).
