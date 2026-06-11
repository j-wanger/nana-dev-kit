---
parent: dev-wiki
referenced_at: "referenced (step unknown)"
---

# working-knowledge-spec.md

Specification for `.claude/rules/working-knowledge.md` — usage-tracked cross-phase knowledge.

**Location:** `.claude/rules/working-knowledge.md`
**Ownership:** `/wiki-query` (activate + increment) — the sole writer since the Phase 88 trim-trials (debrief carry-forward and dev-plan seeding removed; the session-start curator prunes; existing entries decay in place).

### Entry Format

Each entry is exactly 2 lines:
1. `- [uses: N] <distilled proposition>` — fact with usage counter
2. `  source: [[wiki:<slug>]] | activated: YYYY-MM-DD` — indented metadata

Optional: append `| last_decay: YYYY-MM-DD | tier: 3` for project-specific facts.

Order is insertion order — entries are NOT sorted (the whole file is loaded into context regardless of order).

### Curation (deterministic — single source of truth)

The session-start hook `wk-prune.sh` (`prune_working_knowledge`) is the one deterministic enforcement
point for this file's invariants. It is fail-safe: it validates structure, builds the result in a temp
file, and only then atomically renames over the original — aborting (file left byte-intact) on any
problem. Producers (`/wiki-query`, `/dev-debrief`, `/dev-plan`) just APPEND new `[uses: 1]` entries;
they do NOT hand-dedup, hand-sort, or hand-prune. Over-cap state is tolerated until the next
session-start, when the curator brings the file back within bounds.

- **Cap:** max 100 entries AND a 210-line hard cap (~800 tokens). Non-strict at the boundary — exactly
  100 entries is a no-op. When over cap, evict lowest `uses` first, ties broken by oldest `activated:`
  date. `[pinned]` entries are never evicted; if pins alone exceed the cap, the cap is exceeded and a
  warning is emitted (pins win).
- **Dedup keys on proposition text, NEVER the source slug.** Distinct facts legitimately share a source
  phase (one phase commonly yields several entries), so slug-equality is not duplicate-equality. The
  dedup key is the proposition text after stripping the `- [uses: N] ` prefix and any leading `[pinned]`
  marker, then trimming whitespace. Exact-duplicate propositions are collapsed to one entry keeping the
  higher `uses`; near-but-not-exact duplicates are left in place (no false-positive data loss).
- **Stale prune:** `[uses: 1]` non-pinned entries older than 30 days are pruned (max 5 per run) to
  `.dev-wiki/.stale-queue`. Usage counts otherwise persist — no automatic decay.

### When to Activate

After `/wiki-query` answers a substantive question (>3 sentences, 2+ articles), offer activation. Max 3-5 propositions per event. Each must be multi-turn useful OR non-obvious from a single file read.

### What Belongs Here

Cross-project reusable patterns about HOW to do work, and cross-phase non-obvious project facts (multi-module, not derivable from one file). If `_ARCHITECTURE.md` or a single file captures it, don't duplicate here.

**Cross-reference:** (active-knowledge-spec.md removed — Phase 88 trim-trial) phase-scoped knowledge with different lifecycle.
