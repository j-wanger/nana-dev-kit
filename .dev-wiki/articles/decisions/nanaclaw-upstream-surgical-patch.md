---
title: "Nanaclaw upstream surgical patch"
aliases: [upstream-sync-surgical, nanaclaw-sanitize-patch]
category: decisions
tags: [nanaclaw, upstream, vendoring, storage]
parents: [phase-34-upstream-sync-store-opt-ts-design]
created: 2026-05-24
updated: 2026-05-24
source: plan
confidence: high
---

## Context

`memory_server/storage.py` is vendored from nanaclaw (Phase 4) and has diverged significantly — 903 LOC in the kit vs ~170 in the upstream original. Phase 33 rewrote `_sanitize_fts_query` with char-level stripping to fix FTS5 special character handling. This fix benefits the upstream project. The question: how much to sync back.

## Decision

Sync only `_sanitize_fts_query` via a surgical single-function patch at `patches/nanaclaw-sanitize-fts.patch`. Do NOT attempt a full divergence merge. Document the complete divergence inventory in a separate decision article.

**Alternative deferred:** Declaring the fork permanent. This may be recommended in the divergence inventory, but making that call requires understanding the full scope of divergence first.

**Rationale:** The vendored copy has 903 LOC vs ~170 original — a full merge is impractical and risks carrying vendored-only code (search_hybrid, export/import) into the upstream or dropping it from the kit. A surgical patch for a specific bug fix is low-risk and high-value.

## Consequences

- A `patches/` directory is created at the repo root (new convention for upstream contributions).
- The divergence inventory documents which functions are kit-only vs shared, serving as a reference for future upstream decisions.
- Post-sync verification must confirm vendored-only functions (`search_hybrid`, `search_vec`, `_ensure_vec`, `export_memories`, `import_memories`) survive.
- If the nanaclaw repo is inaccessible or archived, the patch is skipped and the divergence inventory documents this.
