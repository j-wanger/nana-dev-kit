---
title: "Batch self-dialogue removal with the heuristic cut (one renumber pass)"
aliases: ["batch-self-dialogue-with-heuristic-renumber", "batched-renumber-pass"]
category: decisions
tags: [self-dialogue, renumber, batching, step-numbering, double-renumber, phase-47]
parents: [phase-64-cut-heuristic-scoring-machinery-self-dialogue, phase-63-remediation-roadmap]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Self-dialogue (dev-plan Step 11, Phase 47) is net-neutral — the subagent variant added clean-context isolation but no measurable reasoning lift, and its injection source `iron-rules-injection-v2.md` was never shipped (dangling reference). On its own it warrants removal. Independently, the heuristic-scoring cut ([[cut-heuristic-scoring-keep-articles]]) removes dev-plan Step 13 sub-items 6-7. Both removals force a dev-plan top-level step renumber on the SAME surface: Self-Dialogue is Step 11, so removing it renumbers Steps 12-18 → 11-17, and that range contains Step 13 (where the heuristic sub-items live). Doing the two cuts in separate phases means renumbering the same step range twice — a wasteful, error-prone double-renumber.

## Decision

Batch the self-dialogue removal into the same phase and the same renumber pass as the heuristic cut. One pass: remove Step 11 (self-dialogue) and Step 13 sub-items 6-7, then renumber dev-plan 12-18 → 11-17 once. The gate is `test_step_numbering.sh` (gap-free, headings-only) — green after the combined removal. CRITICAL caveat carried from the spec: `test_step_numbering.sh` validates HEADINGS only and IGNORES postfixed/sub-lettered steps, so the sub-lettered cross-references that ride the renumber (13x→12x, 15x→14x, **16a-16i→15a-15i incl. `16f-ter`→`15f-ter`**, 17x→16x) and inline `Step N` prose in companions / `.dev-wiki/` / `wiki/` / `active-phase.md` / MEMORY.md must be swept MANUALLY. Alternative rejected: two separate phases — a clean separation of concerns, but it pays the renumber cost twice on the same lines with no compensating benefit.

## Consequences

One coordinated renumber, one verification gate run, one sweep of the cross-reference graph. The risk concentrates in the manual sub-letter sweep (the deterministic test can't catch those), which is why the phase front-loads a pre-flight enumeration of every `Step N`/`Step Nx` reference before any edit. Batching coupled-surface cuts is the general lesson: when two subtractions touch the same numbered/ordered surface, do them together. dev-debrief renumbers separately (8-26 → 7-25, driven by the heuristic-capture Step 7 removal) but on its own surface — same one-pass principle.
