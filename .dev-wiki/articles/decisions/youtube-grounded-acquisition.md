---
title: "YouTube→wiki grounded acquisition core — rung-B foundation, local apparatus"
aliases: [youtube-grounded-acquisition, youtube-ingest, pi-setups-research, rung-b-foundation, grounding-rail]
category: decisions
tags: [youtube, research-pipeline, grounding, provenance, rung-b, companion-apparatus, pi-setups, normalization, phase-116]
parents: [phase-116-youtube-grounded-acquisition]
created: 2026-06-30
updated: 2026-06-30
source: plan
confidence: high
---

## Context

The maintainer wants to learn established Pi / AI-coding-agent setup patterns from YouTube ("lots of good resource, don't build from scratch"). A pasted research doc proposed a full continuous YouTube→knowledge-base pipeline (yt-dlp + RSS + whisper + scheduler + lint + Telegram digest). The reframe: that doc fuses two separable things — a **goal** (learn Pi setups) and a **capability** (a standing pipeline). The project already designed this exact ladder in **Phase 97** (rung A = one-shot sweep, rung B = standing research pipeline, rung C = 24/7 workers, rung D = generalize), and Ph97 defines rung B as gitignored `companion/research/` apparatus, local-only, **never shipped to GitHub**. So the doc's "ship a `youtube-ingest` kit skill" and "nanaclaw scheduled job" each conflict with the established home, and the continuous-orchestration parts belong to the separate nanaclaw project.

Value case (clears the subtraction test where re-presentation wouldn't): Pi-specific community setups are genuinely post-cutoff/proprietary — the **one amplifier frontier** the project has repeatedly flagged as untested-for-headroom (the four amplifier-nulls Ph70/71/77/78 all terminated re-presentation of recoverable knowledge; the surviving avenue is retrieval of correctness a bare model cannot hold). The grounding control is the same verify-by-re-fetch discipline that caught a fabricated citation in the Ph97 deep-research workflow.

## Decision

Build the **acquisition + grounded-extraction core** of rung B as **local gitignored Python apparatus** under `companion/research/youtube/`, manual-trigger, feeding a Pi-setups wiki via the **existing** `wiki-add` → `wiki-absorb` skills. NOT a shipped kit skill (maintainer chose this home over the doc's framing). The continuous half (RSS discovery, scheduler, dedup-watermark, Telegram digest) is deferred to a later phase in **nanaclaw**.

The loop: **acquire** (yt-dlp / youtube-transcript-api, captioned-first; uncaptioned → dead-letter) → **chunk** (~1000-token windows, ~15% overlap, segment→time map retained) → **extract** (Claude structured output per chunk, **extraction-by-selection**: a verbatim `source_quote` + a ≤40-word minimal claim, interpretation deferred to wiki-synthesis) → **ground + consolidate** (deterministically verify each `source_quote` ∈ its chunk, drop the ungrounded, dedup/merge into a per-video concept set with immutable provenance).

The **load-bearing invariant** is the grounding rail: every concept's quote is mechanically verified present in its source chunk before it can enter a concept file; a planted/fabricated quote is rejected. Its correctness depends on a **two-stage normalization** (kept separate to avoid the symmetry trap): acquisition-time entity-decode + NFC + rolling-caption-dedup (longest suffix↔prefix overlap merge) producing canonical text ONCE; match-time whitespace-collapse + case-fold applied *identically* to the LLM quote and the canonical chunk at grounding. A **calibration probe** that aborts the run on broken normalization converts the silent-drop failure (reads as "thin video") into a loud one.

### Alternatives considered + rejected
- **(A) One-shot sweep now, defer all infra** — the agent's recommendation; the maintainer overrode it, committing to rung B as the target (durable retrieval infrastructure, not a one-time pull).
- **(B) Shipped `youtube-ingest` kit skill** (the doc's framing) — rejected: conflicts with the Ph97 "research apparatus stays local/gitignored, never shipped" precedent; would make it a consumer product feature, not personal research apparatus.
- **(C) Whole pipeline in nanaclaw** — deferred-not-rejected for the continuous half: nanaclaw owns scheduling/adapters; the acquisition+grounding core is built here, the orchestration half lands there later.
- **(D) Lite ceremony** — rejected by the maintainer at the assumption gate (A3); Standard ceremony chosen (formal spec + reviewer dispatch + full TDD).
- **AML-tier primary-source reconciliation** — out of scope: Pi setups are researcher-opinion, quote-grounding suffices (A1).

## Consequences

- New gitignored Python apparatus under `companion/research/youtube/` (`acquire`, `normalize`, `chunk`, `extract`, `schema`, `ground`, `consolidate`, `write`, `ingest` + a pytest suite + README). Zero shipped-kit change; dependencies (`youtube-transcript-api`/`yt-dlp` + Anthropic SDK) install into a companion-local gitignored venv, never `install.sh` (honors [[benchmark-only-hybrid-deps]]).
- Eight adversarial-review-caught constraints shape the build: **C1** normalization symmetry + calibration probe; **C2** immutable-quote merge re-verification (no hole at the last link); **C3** atomic-write + regression gate on grounded-quote count + completion marker; **C4** neutralize `[[`/leading-`---`/backticks in quotes at write (markdown injection into the wiki); **E1** empty-body-200 + sub-floor → dead-letter; **E2** segment→time map survives chunking; **S1** pinned tool version + pre-flight cost ceiling; **S2** structured immutable `verified` field + README instructs the hand-off to preserve provenance, not regenerate.
- **RESIDUALS (accepted):** grounding stops fabricated quotes, NOT a real quote misread into a wrong claim (A1 — routed to human wiki-review as the second gate; extraction-by-selection shrinks the surface); whisper.cpp deferred so uncaptioned videos dead-letter (A2 — dead-letter rate measured at the first live run); the live network/API multi-video first-run is manual-drive (residential IP, real tokens; deterministic tests use fixtures + a mocked client).
- **SECURITY/HOME (the constant):** the apparatus is gitignored — no transcript or derived content reaches GitHub (a `git check-ignore` exit criterion fails the phase before any commit if `.gitignore` regresses). ToS posture: personal, local, non-redistributed research use only.

## Source

Phase 116 plan (2026-06-30). Direction confirmed at the assumption gate (ledger Phase-116, all_accept:false — A1 accept, A2 accept, A3 reject→Standard ceremony; `--gate 116` exit 0). Standard ceremony: separate phase spec `specs/phase-116-youtube-grounded-acquisition.md` (nana:approved; adversarial constraints + Tier-1 8/10-revise incorporated). Foundation increment of the Ph97 rung-B ladder ([[decision:frontier-positioning-sweep]]); grounding control inherits the Ph97 verify-by-re-fetch lineage ([[decision:qa-verification-sweep]], [[HEU-012]] — orchestrator-only / independent-refetch evidence standard). Confidence high.
