---
title: "Counter Attribution — Uniform Global Verdict"
aliases: [counter-attribution-uniform-global-verdict, uniform-verdict-attribution]
category: decisions
tags: [heuristic, evolution, counter, attribution, judge]
parents: [phase-52-heuristic-evolution]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: medium (confirmed by implementation)
---

## Context

Phase 52 introduces helpful/harmful counter updates on heuristic articles after Step 6.5 judge verdicts. The judge produces a single global Score N/10 + Verdict for up to 3 matched heuristics. The question: should each matched heuristic get its own attribution score, or should the single global verdict apply uniformly to all matched heuristics?

## Decision

Single judge verdict applies uniformly to all matched heuristics. When judge scores >= 6, all matched heuristics get `helpful += 1`. When judge scores <= 4 AND approach reviewer scores >= 6, all get `harmful += 1`. No per-heuristic scoring.

Alternatives considered:
- (a) Per-heuristic scoring from judge: requires judge prompt changes, scope creep into Phase 51 deliverable. Rejected.
- (b) Append-only evolution log with derived counters: doesn't earn its complexity for 15 heuristics. Rejected.

## Consequences

Known approximation — a heuristic that was irrelevant to a verdict still gets credited/penalized. With max 3 matched heuristics per invocation, noise is bounded. Over many invocations, genuinely helpful heuristics will accumulate higher helpful counts. If attribution precision becomes important (e.g., for automated deprecation at scale), a future phase can modify the judge prompt to produce per-heuristic scores. Documented as a known limitation in heuristic-counter-update.md.
