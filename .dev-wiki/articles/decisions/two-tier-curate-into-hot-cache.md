---
title: "2-tier architecture: curate-into-hot-cache, no 3rd runtime-retrieved store tier (D3)"
aliases: ["two-tier-curate-into-hot-cache", "d3-2-tier", "no-third-runtime-tier"]
category: decisions
tags: [memory, knowledge-wiki, retrieval, architecture, context-engineering, hot-cache]
parents: [phase-61-validate-memory-knowledge-integration]
created: 2026-05-29
updated: 2026-05-29
source: debrief
confidence: high
---

## Context

Phase 61's D3 question: should the harness add a 3rd, runtime-retrieved store tier on top of (1) the always-loaded markdown hot cache (`working-knowledge.md` / `active-knowledge.md`) and (2) the dev-wiki / knowledge-wiki corpora? This was framed as derived-from-evidence — answer it from the D1 (wiki-search) and D2 (memory read-path) measurements rather than measuring it directly.

## Decision

**2-tier: curate-into-hot-cache; do NOT build a 3rd runtime-retrieved write-store tier.** Both retrieval arms measured no lift for the same structural reason: the always-loaded hot cache IS the effective retrieval layer, and it makes the clean baseline strong enough that runtime external retrieval is redundant-at-best / diluting-at-worst. Keyed to the measured deltas: **D1 = −0.67** (wiki-search, [[cut-active-research-step-2-7]] redux confirmed by measurement) and **D2 = 0.00** ([[cut-mcp-memory-read-path-d2]]).

Marginal engineering effort therefore belongs in **hot-cache curation quality** — what gets distilled into `working-knowledge.md` / `active-knowledge.md`, the eviction policy at the 100-entry cap, and dedup against existing entries — not in wiring a runtime retrieval engine into the planning flow.

Alternatives rejected: build a 3rd runtime-retrieved tier (D1+D2 nulls show no lift); measure D3 directly (subsumed — both feeder arms already measured net-zero-or-negative).

## Consequences

- Phase-62 build candidate is hot-cache curation quality (the one direction with affirmative evidence — the baseline's strength IS the evidence). Runtime wiki-search (D1), runtime memory_search (D2), and a 3rd runtime tier (D3) are all NOT-building.
- Derives directly from [[hot-cache-is-the-effective-retrieval-layer]].
- Leaves the genuinely weak-parametric + properly-absorbed + covered sweet spot unmeasured — a separate future call requiring an absorb pipeline + a non-commodity corpus first.
