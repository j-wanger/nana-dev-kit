---
title: "Replace full table scans in _find_near_duplicate with indexed lookups"
aliases: [store-optimization, indexed-dedup, near-duplicate-optimization]
category: decisions
tags: [memory-server, storage, performance, sqlite-vec, fts5]
parents: [phase-34-upstream-sync-store-opt-ts-design]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: high
---

## Context

`_find_near_duplicate()` in `memory_server/storage.py` performs two full table scans on every `store()` call: the cosine path fetches ALL active memories with embeddings (`SELECT * FROM memories WHERE active = 1 AND embedding IS NOT NULL`), and the word-overlap path fetches ALL active memories (`SELECT * FROM memories WHERE active = 1`). During LongMemEval-S benchmarking with ~1,000 entries per database, this became a measurable O(n^2) bottleneck.

## Decision

Replace full table scans with indexed lookups:
- **Cosine path:** Use sqlite-vec KNN query (`SELECT ... FROM memories_vec WHERE embedding MATCH ? ORDER BY distance LIMIT 50`) to get top-k candidates, then apply `_cosine_similarity()` on candidates only. Preserves exact threshold semantics (>0.90 reinforce, >0.85 warn).
- **Word-overlap path:** Use FTS5 MATCH query with tokenized input content to get candidates (`LIMIT 50`), then compute word overlap on candidates only. Preserves exact threshold semantics (>0.90 warn).

Both paths preserve exact threshold semantics. FTS5-only mode works when `_vec_available=False` (cosine path skipped entirely, as before).

**Alternative rejected:** Removing the word-overlap path entirely and making cosine-only canonical. Rejected because word-overlap is the production fallback when embeddings are unavailable — most users don't have fastembed installed.

**Rationale:** The optimization changes query strategy (narrowing candidates) but not decision logic (thresholds, actions). Pre-filtering with indexed lookups is a standard database optimization pattern.

## Consequences

- store() performance improves from O(n) full scan per call to O(1) indexed lookup + O(k) threshold check.
- Threshold equivalence tests required before and after to ensure no behavioral change at boundary values (cosine 0.84, 0.86, 0.91; word overlap 0.89, 0.91).
- FTS5 pre-filtering may miss candidates whose content doesn't overlap in tokenized form — acceptable because word-overlap scoring on such candidates would be low anyway.
- The `LIMIT 50` cap means extremely large databases (>50 near-duplicates) could theoretically miss the best match — acceptable tradeoff for performance.
