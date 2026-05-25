---
title: "Char-level sanitizer for FTS5"
aliases: [char-level-sanitizer, fts5-sanitizer-rewrite]
category: decisions
tags: [memory-server, fts5, sanitizer, storage]
parents: [phase-33-hybrid-retrieval-benchmark-memory-server-fixes]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: high
---

## Context

Phase 32 revealed that `_sanitize_fts_query` in `memory_server/storage.py` only strips `( ) " * :`, missing FTS5-significant characters like `? - + ^ ~ { } [ ] | \` and bare keywords `AND NOT NEAR`. The benchmark worked around this with a local `sanitize_query()` function. The question: how to fix the upstream function without hurting recall.

## Decision

Switch `_sanitize_fts_query` from token-level filtering (drops entire tokens containing special chars) to char-level stripping via `re.sub(r'[^\w\s]', ' ', query)`, normalize whitespace, and strip FTS5 keywords (AND/NOT/NEAR as standalone tokens). Preserve existing OR-join semantics.

**Alternative rejected:** FTS5 quote-wrapping (wrapping tokens in double quotes) creates phrase queries that hurt recall for hyphenated and compound terms.

**Rationale:** FTS5's tokenizer strips the same special characters during indexing, so removing them at query time causes no content loss at the matching level. Known acceptable limitation: `C++` becomes `C` (single-char token, low recall impact).

## Consequences

- The benchmark's local `sanitize_query()` becomes redundant and should be removed (Task 2).
- FTS5 recall should remain >= 91% (the baseline) since the fix aligns query preprocessing with index-time tokenization.
- Edge cases: `user's` becomes `user s` (two tokens), standalone `AND` stripped but `android` preserved.
- Future: if more complex query syntax is needed (phrase search), a different approach would be required.
