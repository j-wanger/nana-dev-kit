---
title: "Memory-Layer Prune Round — admissibility-gated dispositions"
aliases: [memory-layer-prune-round, phase-92-approach]
category: decisions
tags: [memory, prune-on-value, subtraction, admissibility, assumption-ledger, mcp]
parents: [phase-92-memory-layer-prune]
created: 2026-06-12
updated: 2026-06-12
source: plan
confidence: low
---

## Context

Phase 88's direction gate rejected the dogfood zero as demand evidence (A4) and deferred the bridge/harvest writer trims with it (A6); Phase 83 left the kit-side layer-value question open (A5, the only `revisit-status: open` memory row) and enforce-memory as keep-with-revisit. Phase 89 ran a pre-registered evidence round exactly to arm this disposition: a three-way-clean demand zero on a liveness-probed live layer, the continuity case served entirely by the file substrate, kit-side writer liveness (informational), and one post-restoration block→COMPLY datapoint. The spec (`specs/phase-92-memory-layer-prune.md`, nana:approved 2026-06-12) pins the closed verdict-row set, the admissibility-first ordering, and 10 exit criteria.

## Decision

Six serialized stages, admissibility-first, evidence-before-verdicts, Phase-83 prune discipline throughout:

- **T1 — apparatus + admissibility ruling FIRST.** `eval/memory-prune/` scaffold; the standalone admissibility ruling answers the pinned A4-reject rationale strand-by-strand (demand zero / continuity case / writer-unreached / kit-side-informational), committed in its OWN commit (strict-ancestry anti-retrofit: same-commit add fails the runner). The direction note's convergence predicate is pre-registered here too (which verdict tokens count as "pointing the same way" — decided before the table exists, anti-retrofit). Window-events `## Phase 92` section opened; per-session attestations begin. Checkpoint 1: ruling reported to maintainer; `inadmissible` → the round degrades to evidence-gap filings, by design.
- **T2 — evidence assembly (read-only).** Surface enumeration (≥2 naming conventions, repo + installed trees, positive control, 3-way `mcp-layer|auto-memory|unrelated` classification); full post-restoration enforce-memory firing-distribution extraction (DRQ-2 — must precede table fill: it can flip the enforce-memory row AND bears on the layer row); DRQ-1 MCP-absence sandbox probe (deleted module + deregistered cases, observed not assumed, outcomes classified per HEU-002's healthy/broken/not-configured 3-state model); DRQ-3 residual-class analysis (which file-lifecycle.md memory_store routings lack a file-substrate equivalent — feeds the memory-mcp-layer row's keep case directly, not an orphan artifact); per-discovered-root store counts via direct `sqlite3` count queries (memory_stats only answers for the kit's own CWD-resolved store).
- **T3 — verdict table + checkers.** 4 rows filled with zero-class (sandbox-armed couldnt-fire vs didnt-fire), removal-set-first liveness greps, expected deltas, unreachable-installs lines, and the per-reachable-root archive plan (maintainer decision 2026-06-12: every reachable root with a non-empty store gets the count-verified export before deregistration touches it). `run-exit-criteria.sh` with seeded-failure selftests (Phase-88/89 runner pattern).
- **T4 — HARD maintainer checkpoint.** Full table + the named user-action item for the user-owned rules files if any verdict dangles them. No execution on direction-gate authority.
- **T5 — checkpoint-approved execution.** Serialized per-candidate commits (`Phase 92 cut: <name>`), store backups incl. per-root archives (mechanism pinned: non-kit roots use WAL-checkpointed `sqlite3 .backup` with a per-root direct count assertion — memory_export is CWD-resolved and only reaches the kit's store), enforce-memory-before-or-atomic-with-layer ordering (self-lockout pin), sandbox-rehearsed deregistration, survivor smoke, revert-on-failure. Zero approved cuts → T5 is a no-op, valid.
- **T6 — close-out.** Ledger A5 flip (`open` → `closed (Phase 92, <pointer>)`); the validator is verified FIRST against the flip and its doc-vocab comment extended only if needed (spec assumption 4 — verify-first, never an unconditional edit). Blockers A4/A6 deferral filings closed IF their rows reached dispositions, OR replaced by the paired evidence-gap filing naming what the next round must produce (the deferred-inadmissible path — the likeliest writer-row outcome). Runner ALL-PASS; state refresh.

Alternative considered and not adopted: a single substrate-replacement architectural decision (file substrate IS the memory architecture; component verdicts as corollaries) — rejected because the A4 reject explicitly demanded per-component evidence; recorded as a direction note the checkpoint may invoke if 3+ rows point the same way.

## Consequences

The four memory ledger obligations (Phase-83 A5, Phase-88 A4/A6, enforce-memory revisit) each reach a verdict or an explicit `deferred-inadmissible` + evidence-gap filing — the writer rows are the likeliest deferral (their consuming-project evidence is zero-by-unreached, and kit-side liveness is Ph80-leak informational). Accepted trade-offs: another possible deferral round for A6 rather than stretching evidence; per-root archive cost (small, ~1-2 roots) for symmetry with the Phases-19-48 loss lesson; the trim-trial windows and Phase-93 authority remain untouched, so even a layer cut leaves d43950f/df3e623/75b48af/b8bd416 unreverted.
