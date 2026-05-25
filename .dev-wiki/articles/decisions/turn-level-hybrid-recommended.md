---
title: "Turn-level hybrid RRF is the winning search strategy"
aliases: [turn-level-hybrid, hybrid-rrf-turn-level, session-vs-turn-hybrid]
category: decisions
tags: [benchmark, hybrid, retrieval, embedding, rrf, memory-server]
parents: [phase-33-hybrid-retrieval-benchmark-memory-server-fixes]
created: 2026-05-24
updated: 2026-05-24
source: debrief
confidence: high
---

## Context

Phase 33 benchmarked three retrieval strategies against LongMemEval-S: FTS5-only (baseline from Phase 32), session-level hybrid (embedding full session transcripts), and turn-level hybrid (embedding individual memory entries). The question: which hybrid strategy best complements FTS5?

## Decision

Turn-level hybrid RRF is the recommended search strategy. Key evidence:

- +27.6% recall lift on FTS5-failure questions (questions where FTS5 alone scored 0)
- 100% recall on easy questions (no degradation from FTS5 baseline)
- Session-level hybrid with truncated embeddings actively hurts easy questions (100% -> 80%)

**Root cause of session-level failure:** Short memory entries produce high-quality, focused embeddings. Long session transcripts produce diluted embeddings that mislead the nearest-neighbor search. This aligns with production `memory_store` behavior where entries are individual facts, not session dumps.

**Alternative rejected:** Session-level hybrid with full-length embeddings -- truncation artifacts hurt recall. Adaptive fusion (BM25 score-gated hybrid) analyzed but not implemented; promising for future work.

## Consequences

- Production memory_server already defaults to hybrid search when embeddings are available (`server.py:128`), which is correct for turn-level entries.
- Full 500-question turn-level hybrid benchmark not yet run (tuning samples only); definitive numbers are a Phase 34 candidate.
- store() near-duplicate detection is O(n^2) and became a bottleneck with ~1,000 entries per DB in turn-level benchmark.
- Adaptive fusion (use BM25 confidence to gate hybrid) remains a future optimization opportunity.
