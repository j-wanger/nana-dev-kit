---
title: "The always-loaded markdown hot cache IS the effective retrieval layer"
aliases: ["hot-cache-is-the-effective-retrieval-layer", "hot-cache-meta-finding", "phase-61-meta-finding"]
category: decisions
tags: [memory, knowledge-wiki, retrieval, context-engineering, hot-cache, meta-finding, nana-soul]
parents: [phase-61-validate-memory-knowledge-integration]
created: 2026-05-29
updated: 2026-05-29
source: debrief
confidence: high
---

## Context

Phase 61 ran five runtime-retrieval directions through pre-registered A/B measurement: D1 wiki-search-into-planning, D2 MCP memory read-path, D3 a 3rd runtime-retrieved tier, D4 absorb-prep, D5 the retrieval-subagent firewall. Every one measured net-zero-or-negative (D1 = −0.67, D2 = 0.00, D3/D4/D5 derived or moot). The interesting result is not any single null — it is WHY they all null out together.

## Decision

**Recognize the load-bearing positive result: the always-loaded markdown hot cache (`working-knowledge.md` + `active-knowledge.md`, in `.claude/rules/`, loaded into every session) IS the effective retrieval layer.** It made every clean baseline strong — baseline answers cited the project's own memory specifics unprompted (`cosine >0.90 reinforce`, hybrid RRF `+27.6%`, supersession chains, pre-registration / variance-gate methodology) — which is precisely WHY all five runtime-retrieval directions showed no lift: the relevant knowledge was already in context before any retrieval engine fired.

This refines the nana-soul tenet "retrieval and context injection over parametric knowledge": **retrieval over parametric knowledge does NOT pay when the relevant knowledge is already in the always-loaded context layer.** The win is in curating that layer, not in bolting runtime retrieval engines onto the planning flow. (Companion to the Phase-59 finding that retrieval doesn't pay when *parametric* knowledge is strong — Phase 61 adds: it also doesn't pay when the *hot-cache* knowledge is strong, which subsumes the in-context case.)

## Consequences

- Directly produces the 2-tier architecture decision ([[two-tier-curate-into-hot-cache]]) and the D1/D2 cuts ([[cut-mcp-memory-read-path-d2]], [[cut-active-research-step-2-7]]).
- Phase-62 value concentrates in hot-cache curation quality (distillation, eviction policy, dedup) — the only memory/knowledge direction with affirmative evidence.
- Honest scope: a genuinely weak-parametric + properly-absorbed + covered topic (retrieval's theoretical sweet spot) was never found/built, so retrieval's best case remains unmeasured. The finding is "the hot cache dominates for the content we actually have," not "retrieval is universally worthless."
- Validates the [[memory-architecture-classification]] insight (strengthen always-loaded `.claude/rules/` activation points) with measured evidence.
