---
title: "Curator is fail-safe (atomic write + bail on malformed + pinned-immune)"
aliases: ["curator-fail-safe-atomic", "hot-cache-curator-fail-safe"]
category: decisions
tags: [memory, hot-cache, working-knowledge, curation, atomic-write, fail-safe, blast-radius]
parents: [phase-62-harden-hot-cache-curation]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The curator runs at session-start on `.claude/rules/working-knowledge.md` — a mandatory, always-loaded file that ships to every scaffolded project via the installer's `cp -r`. Blast radius is high: a curator bug that truncates, corrupts, or mis-deletes entries propagates everywhere and silently degrades the harness's effective retrieval layer. Deletion logic on a file you cannot afford to lose demands a conservative failure posture.

## Decision

The curator is **fail-safe** on three axes:

1. **Atomic write.** It builds the proposed new content in a temp file, structurally validates that content, and only then atomically renames over the original. On any validation failure it aborts leaving the original **byte-intact**. Never an in-place partial write — prevents shipping a truncated mandatory file.
2. **Bail on malformed.** Any 2-line pairing failure (a proposition line not followed by an indented `source:`/`activated:` line, or vice-versa) triggers a **whole-file no-op plus a warning**, file left byte-intact. No per-entry repair, quarantine, or deletion is attempted on a mandatory file — "leave it intact and warn" dominates "drop the bad entry" on the never-lose-knowledge axis and keeps the bash simple.
3. **Pinned-immune.** `[pinned]` entries are excluded from the eviction candidate set entirely; the curator asserts `(evicted ∩ pinned) = ∅` before writing. If pinned entries alone exceed the cap, **pins win**: the cap is exceeded and a warning is emitted (never evict a pin to meet the cap).

The cap is also NON-STRICT: at exactly 100 entries and ≤210 lines the curator is a no-op. Eviction "least valuable" ranking is `uses` ascending, ties broken by oldest `activated:` date ascending.

Alternative rejected: per-entry repair / in-place mutation — lower-effort but unsafe on a high-blast-radius mandatory file; one bug loses knowledge in every project.

## Consequences

The curator is provably safe before it ever evicts in production — the dogfood run on the live cache (already at exactly 100) must be a no-op. The regression test asserts each fail-safe path (all-pinned-over-cap → pins win + warning; malformed → whole-file no-op + warning; exactly-100 → no-op; idempotent second run). Worst case under the single-writer-at-session-start assumption is one lost append, never corruption. Concurrency locking across producers is out of scope (documented assumption).
