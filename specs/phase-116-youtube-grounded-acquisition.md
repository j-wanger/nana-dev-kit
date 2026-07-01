<!-- nana:approved 2026-06-30 -->
# Spec: Phase 116 — YouTube→wiki grounded acquisition core (rung-B foundation)

## Objective
Build a manual-trigger Python core loop that turns one Pi/agent-setup YouTube video into a grounded, provenance-carrying concept set — each concept tied to a verbatim, mechanically-verified transcript quote + timestamp — written as gitignored files ready to feed a Pi-setups knowledge wiki via the existing wiki skills.

## Context
nana-dev-kit research apparatus, local-only and gitignored (`companion/` carries the `.gitignore` note "Local-only research companion (Phase 97+) — never shipped"). This is the foundation increment of the Phase-97 "rung B" standing research pipeline, specialized to YouTube as a source, for learning post-cutoff Pi / AI-coding-agent setup patterns that a bare frontier model cannot recover from its training corpus (the one amplifier frontier the project has flagged as untested-for-headroom). It is deliberately NOT a shipped kit skill — it honors the Ph97 precedent that research apparatus stays local and never reaches GitHub. The continuous-orchestration half of rung B (RSS discovery, scheduler, dedup-watermark, Telegram digest) is out of scope here and deferred to the separate nanaclaw project.

The knowledge store is a Karpathy-style markdown "LLM wiki" whose documented failure mode is that a single hallucinated fact propagates across many linked articles. The grounding step exists to convert plausible extractions into traceable ones BEFORE anything enters that store — the same verify-by-re-fetch discipline that caught a fabricated citation in the Phase-97 deep-research workflow.

## Scope
### In scope
- A manual-trigger acquire → chunk → extract → ground+consolidate loop under `companion/research/youtube/`.
- A pinned normalization shared symmetrically by acquisition and grounding (the rail's correctness hinges on it).
- Grounded per-video concept files with a structured, immutable provenance record (videoId + timestamp + verbatim quote + a machine-checkable `verified` field).
- A README documenting the manual trigger and the hand-off to the existing `wiki-add` → `wiki-absorb` skills.
- Deterministic tests on fixtures (a fixture VTT; a mocked LLM client).
- `.dev-wiki/**` planning artifacts and `.claude/rules/active-phase.md`.

### Out of scope
- Any change to shipped kit code, `app/`, `templates/`, `install.sh`, or any security/engine surface.
- whisper.cpp ASR fallback for uncaptioned videos (additive later task — captioned-first this phase).
- RSS discovery, scheduling, dedup-watermark across runs, Telegram digest (nanaclaw, rung-B continuous half).
- Multi-pass stochastic extraction (a cheap config knob, default 1 pass; consolidation already tolerates merging passes).
- A QMD / BM25 search layer (only justified past ~100–200k wiki tokens).
- AML-tier primary-source reconciliation (wrong domain — Pi setups are researcher-opinion, quote-grounding suffices).
- Adding any dependency to the shipped kit's `install.sh`/requirements (companion-local venv only).

## Approach
A staged pipeline where each stage carries provenance forward and the grounding stage is a deterministic gate, not an LLM judgment. The LLM is used only for extraction, and constrained to **extraction-by-selection**: it quotes a verbatim span and attaches a minimal claim (a single assertion, ≤ ~40 words — a length bound, not free-form summary), deferring interpretation to the human-reviewed wiki-synthesis step — this shrinks the surface of the one failure grounding cannot catch (a real quote misread into a wrong claim). Every other stage is deterministic Python.

Two distinct normalizations, kept separate to avoid the symmetry trap:
- **Acquisition normalization (one-time, T1):** collapses the raw timed-text into canonical transcript text — decode HTML entities, NFC-normalize, then strip YouTube's rolling-caption duplication by the pinned rule: walking consecutive segments, collapse the longest suffix of the accumulated text that is a prefix of the next segment (longest suffix↔prefix overlap merge). This runs once, produces the text the chunks are built from, and is NOT applied to the LLM quote (the quote already comes from de-duplicated chunk text).
- **Match normalization (symmetric, T4):** applied *identically* to both the LLM's returned quote and the canonical chunk text at grounding time — whitespace-collapse + case-fold (NFC/entity-decode already done upstream). Symmetry here is what makes a "verbatim" quote from lowercased/unpunctuated ASR text verify against its chunk; an asymmetry would silently drop genuine concepts and read as "this video had few ideas." A self-verifying **calibration probe** (a quote pulled directly from a chunk that MUST verify each run; deliberately breaking the normalization MUST abort the run) converts that silent failure into a loud one.

Chunking (pinned default, a config knob): token-windowed over the canonical text at ~1000 tokens with ~15% overlap (within the 750–1500 extraction-quality band), each window built from caption segments so it retains its segment→time range for provenance (E2). Boundary-spanning recall is the open trade in DRQ2.

Only concepts that pass grounding are written. The merge/consolidation step may combine concept *descriptions* but must treat the quote+timestamp as immutable and re-verify the merged set, so the anti-hallucination chain has no hole at its last link. Output is written atomically and guarded against a degraded re-run clobbering a richer prior result.

### Domain Research Questions
1. What normalization makes an LLM's "verbatim" quote and raw ASR caption text match symmetrically (unicode NFC, HTML-entity decode, whitespace-collapse, case-fold, rolling-caption de-duplication) without over-normalizing into *false* matches? Where is the precision/recall knee?
2. Boundary-spanning policy: when a supporting sentence straddles a chunk boundary, verify against the source chunk only (accept the drop) or against an overlap-extended window (risk duplicate concepts the merge must reconcile)? Which yields better recall without inflating dedup load?
3. For a 2–3 hour video that fans out into dozens of chunks × frontier-API calls, what pre-flight chunk-count/token-cost estimate and ceiling should gate the extraction loop before it runs?

## Constraints (CRITICAL)
- **Normalization asymmetry silently drops real concepts (C1).** A naive `quote in chunk` fails on genuine extractions because ASR text is lowercased/unpunctuated/entity-encoded/rolling-duplicated. — Guard: the two-stage normalization pinned in Approach — acquisition-time entity-decode + NFC + rolling-dup collapse (longest suffix↔prefix overlap merge, deterministic) producing canonical text once; then match-time whitespace-collapse + case-fold applied *identically* to the LLM quote and the canonical chunk at grounding. Log every drop with its reason; run a calibration probe each grounding pass (a quote taken verbatim from a chunk MUST self-verify, and a deliberately-broken normalization MUST abort the run) so the failure is loud, not a thin set. The calibration probe and the broken-normalization-aborts behaviour each get their own non-skippable test.
- **Merge re-introduces hallucination at the last link (C2).** Consolidation is tempted to synthesize a clean canonical statement that is no longer any verified quote. — Guard: `source_quote`/`timestamp` immutable post-extraction; merge may combine descriptions but every surviving concept must still carry ≥1 quote that passed grounding; re-run verification on the merged output, asserting the invariant.
- **A degraded re-run clobbers good output (C3).** A partial/empty transcript or a worse LLM run overwrites a richer prior verified set; irreversible for a personal tool with no history. — Guard: write to a temp path + atomic rename; refuse to replace existing output when the new transcript is below the word-count floor or the new **grounded-quote count** regresses (grounded-quote count, not concept count — it is the deterministic, extraction-noise-free measure), unless `--force`; drop a per-video completion marker so an API error on chunk 7/12 is never mistaken for a complete run.
- **Untrusted transcript injects structure into the wiki (C4).** A quote containing `[[wikilink]]`, a leading `---`, or a triple-backtick run fabricates cross-references, corrupts front-matter, or breaks fenced blocks downstream. — Guard: treat `source_quote` as data, not markup — neutralize `[[`/`]]`, leading `---`, and backtick runs at write time so the quote round-trips as literal text.
- **Empty-body-200 looks like success (E1).** Disabled/too-new/music-only captions, or the wrong track (auto-translated vs original), return HTTP 200 with an empty or fluent-but-wrong body; the pipeline sails through and emits a well-formed empty/incorrect set. — Guard: assert a transcript word-count floor (pinned default 200 words, a config knob — below it a "transcript" is almost certainly an empty/music/disabled-caption artifact) and record the selected track (prefer manual original over auto-translated) before extraction; treat empty-body-200 as dead-letter failure, not success.
- **Provenance must survive chunking (E2).** A boundary-spanning quote fails verification against its source chunk; discarding per-segment timing makes the timestamp unreconstructable; the rolling-caption start time points before the quote appears. — Guard: carry the segment→time map through chunking so every chunk knows its time range; record which chunk each quote verified against; the boundary policy (Q2) is decided explicitly, not by accident.
- **Cost cliff + moving endpoint (S1).** The unofficial timed-text endpoint can start requiring tokens/cookies, rate-limit, or return partial transcripts with no error; a long video is an unbounded surprise bill. — Guard: pin the acquisition tool version; a transcript sanity assertion fails loud on a degraded endpoint; estimate chunk-count/token-cost and enforce a ceiling (or require confirmation) before the extraction loop.
- **An unverified concept in the wiki is worse than an absent one (S2).** A concept wearing an unearned "grounded" badge seeds exactly the propagation the wiki fears; the downstream absorb step may rewrite concept text and detach it from its quote. — Guard: `verified` is a structured machine-checkable field at the boundary (only verified concepts written; status is data, not prose); the README instructs the wiki hand-off to preserve quote+timestamp as an immutable provenance record, not regenerate it.
- **Apparatus stays local (process).** Dependencies install into a companion-local, gitignored venv — never the shipped kit's `install.sh`/requirements (honors the benchmark-only-deps precedent). Live network/API runs are manual-drive (residential IP); deterministic tests use fixtures + a mocked client.

## Success Vision
A maintainer points the loop at one Pi-setup video and gets back a concept file where every concept is traceable to a real spoken moment — and trusts it, because a planted fabricated quote would have been rejected, a normalization bug would have failed the run loudly instead of quietly thinning the output, and a degraded re-run could not have silently destroyed a better prior result. The output drops cleanly into the existing wiki flow with its provenance intact. The justified complexity (the grounding rail) is visibly earning its keep; nothing speculative (scheduler, search layer, whisper) was built before it was needed.

## Exit Criteria (machine-checkable)
- [ ] `cd companion/research/youtube && python -m pytest -q` — all tests pass.
- [ ] `python -m pytest -q -k "grounding_rejects_fabricated"` — a planted quote absent from its chunk is rejected; a genuine one passes.
- [ ] `python -m pytest -q -k "normalization_symmetry"` — the same match-normalization applied to both sides makes a known-good ASR-style quote verify against its chunk.
- [ ] `python -m pytest -q -k "calibration_probe_fails_loud"` — a deliberately-broken normalization aborts the run (the silent-failure detector is independently proven, not OR-masked).
- [ ] `python -m pytest -q -k "merge_preserves_verified_quote"` — every post-merge concept still carries ≥1 grounded immutable quote and the merged set re-verifies.
- [ ] `python -m pytest -q -k "empty_body_200_deadletter"` — an HTTP-200 empty/near-empty body becomes a dead-letter, not a successful empty concept set.
- [ ] `python -m pytest -q -k "word_floor_deadletter"` — a sub-floor (<200-word default) transcript is dead-lettered before extraction.
- [ ] `python -m pytest -q -k "quote_markdown_neutralized"` — `[[`, a leading `---`, and a backtick run inside a quote round-trip as literal text in the written file.
- [ ] `python -m pytest -q -k "overwrite_regression_gate"` — a regressed (fewer grounded quotes) or sub-floor re-run does not clobber a richer prior without `--force`.
- [ ] `python -m pytest -q -k "completion_marker"` — a full run drops a per-video completion marker; a chunk-mid failure does not.
- [ ] `python -m pytest -q -k "end_to_end_fixture"` — fixtures produce a concept file with frontmatter provenance and a structured `verified` field.
- [ ] `test -f companion/research/youtube/README.md && grep -qi "wiki-absorb" companion/research/youtube/README.md && grep -qi "provenance" companion/research/youtube/README.md` — README documents the manual trigger and the provenance-preserving wiki hand-off.
- [ ] `git check-ignore companion/research/youtube >/dev/null` — the apparatus is gitignored (never shipped).

## Checkpoints
- After the grounding rail (extract + ground + consolidate) lands and `grounding_rejects_fabricated` + `normalization_symmetry`/`calibration_probe` + `merge_preserves_verified_quote` pass: STOP and report — that is the phase's load-bearing proof.
- If the first live multi-video run shows a high uncaptioned/dead-letter rate (assumption A2 in doubt): STOP and report before scaling; whisper.cpp may need to be pulled forward.
- If a long-video pre-flight estimate exceeds the cost ceiling: STOP and confirm before running the extraction loop.

## Assumptions
- Grounding-rail + extraction-by-selection + human wiki-review is sufficient hallucination control for researcher-opinion content. If false (misread-quote rate is high in spot-checks): add a second adjudication pass to grounding; do not build AML-tier primary-source reconciliation reflexively.
- Most Pi/agent-setup videos are captioned, so whisper.cpp is deferrable. If false (high dead-letter rate in the first run): pull whisper.cpp forward as a T1 sub-task with its local-compile dependency.
- The existing `wiki-add` → `wiki-absorb` hand-off is an adequate wiki-ingest path. If false (synthesis is weak or detaches quotes): add a Pi-tuned ingest prompt that preserves provenance — a later increment, not this phase.
- A companion-local Python venv with `youtube-transcript-api`/`yt-dlp` + the Anthropic SDK is available on the maintainer's machine. If missing: the README's setup step installs them into the gitignored venv; tests run without network/API via fixtures + a mocked client.
- `companion/` remains gitignored. If false (an `.gitignore` regression): the `git check-ignore` exit criterion fails the phase before any transcript-derived content is committed.
