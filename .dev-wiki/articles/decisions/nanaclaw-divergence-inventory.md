---
title: "Nanaclaw Divergence Inventory"
aliases: [nanaclaw-divergence, upstream-divergence]
category: decisions
tags: [memory-server, upstream, vendor]
parents: [phase-34-upstream-sync-store-opt-ts-design]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: high
---

## Context

memory_server/storage.py was vendored from nanaclaw in Phase 4. Working knowledge stated the divergence was massive (903 LOC vs ~170 original), suggesting many kit-only functions. A full inventory was needed to understand the sync burden and decide whether to maintain the vendor relationship or declare a fork.

## Decision

**Inventory result: near-zero divergence.** All 25 functions are shared between upstream (https://github.com/j-wanger/nanaclaw) and the kit. The upstream has grown independently to 900 lines, matching the kit's 903 lines. The ONLY difference is:

1. `import re` added (line 5)
2. `_sanitize_fts_query` implementation: kit uses char-level stripping (`re.sub(r'[^\w\s]', ' ', query)` + FTS5 keyword removal) vs upstream's token-level filtering (`not any(c in t for c in '()"*:')`)

**Shared functions (all 25):** init_db, _ensure_fts, _ensure_vec, _embedding_to_blob, _now_iso, _row_to_entry, store, _find_exact_duplicate, _cosine_similarity, _find_near_duplicate, get_by_id, forget, tag, mark_contradiction, reinforce, prune, stats, search_fts, search_vec, search_hybrid, search_all, export_memories, import_memories, _parse_export_markdown, _sanitize_fts_query.

**Patch created:** `patches/nanaclaw-sanitize-fts.patch` (23 lines, applies cleanly to upstream HEAD).

## Consequences

- The vendor relationship is healthy — upstream tracks kit changes or vice versa. Future syncs will be trivial diffs.
- Working-knowledge entry about "903 vs ~170 LOC" divergence is stale and should be corrected.
- The _sanitize_fts_query fix is the only upstream contribution needed. The patch is surgical and safe to apply.
- store() optimization (Phase 34 Tasks 3-4) will create the first real divergence — _find_near_duplicate will differ after optimization.
