---
title: "CUT the MCP memory_search read-path into planning (D2)"
aliases: ["cut-mcp-memory-read-path-d2", "d2-cut", "memory-read-path-cut"]
category: decisions
tags: [memory, mcp-memory, retrieval, ab-testing, context-engineering, burden-of-proof]
parents: [phase-61-validate-memory-knowledge-integration]
created: 2026-05-29
updated: 2026-05-29
source: debrief
confidence: high
---

## Context

Phase 61 asked, by A/B evidence, whether wiring `memory_search` (the MCP memory engine) into the planning flow earns its place vs the always-loaded-markdown status quo. The MCP memory store owns a real retrieval engine the harness flow doesn't use; the hypothesis was that runtime re-retrieval surfaces valuable entries the planner doesn't already hold (e.g. a "pruned tail" the capped hot cache had to evict).

A cheapest-first store inventory falsified the hypothesis by inspection: `memory_stats` showed **20 active entries** (all `category=custom`, the bridge/harvest channel) vs `working-knowledge.md`'s **~90 always-loaded entries**. `memory_search` on three diverse planning queries returned top hits that were every one already verbatim in the always-loaded hot cache; the only 2 distinct entries were low-value (a verbose spec restatement + a resolved-bug list). The MCP store is a strict, smaller SUBSET of the hot cache (store ⊂ cache; |store|=20 < |cache|≈90), because the same bridge/harvest pipeline feeds both.

## Decision

**CUT D2.** A measured best-case A/B was run anyway (user asked for measurement, not prior — mirroring the T2/D1 decision): on memory's strongest domain (eval-methodology, which the store covers densely), B = baseline-with-hot-cache PLUS the `memory_search` slice, vs A = baseline-with-hot-cache. Result: **mean(A)=9.33, mean(B)=9.33, delta=0.00 composite** (decision_quality −0.33, reasoning_quality +0.33 — a wash netting exactly zero), variance-dominated (A spread 1, B spread 2). Per-fire cost = ≥1 `memory_search` round-trip + ~175 injected tokens. Non-zero cost for zero lift ⇒ net-negative. Burden-of-proof-on-the-feature ⇒ a null is a cut. Escalation to n=5 was not run: a flat-zero variance-dominated estimate cannot become a positive-lift keep by tightening.

This is the cleanest possible "redundant retrieval" signature: B = A + (a subset of A) ⇒ Δ→0. Alternatives considered and rejected: keep D2 anyway (fails burden of proof); escalate to n=5 (cannot rescue a flat null into a positive).

## Consequences

- No runtime `memory_search` wiring into planning in Phase 62 (see [[two-tier-curate-into-hot-cache]]).
- Reinforces the load-bearing meta-finding: [[hot-cache-is-the-effective-retrieval-layer]].
- **Re-test trigger (deferred, not a present feature):** if the MCP store ever grows past the hot-cache 100-entry cap with valuable DISTINCT entries, re-run the D2 A/B — `memory_search` as overflow recall for the evicted tail. Concrete numeric trigger, not a standing keep.
- The CUT is scoped to the store AS IT STANDS (20 entries, ⊂ cache); it is not a claim that memory retrieval can never pay.
