---
title: "Stochastic Heuristic Interference (Negative Result)"
aliases: [stochastic-interference, loo-negative-result]
category: decisions
tags: [eval, ablation, iron-rules, reasoning, negative-result]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: debrief
confidence: high
status: accepted
---

# Stochastic Heuristic Interference (Negative Result)

## Context

Phase 48 LOO ablation aimed to identify which IRON RULES cause interference on scenarios 015/018/020 (observed in Phases 45-47). Prior hypothesis: IRON-004/005 are the specific culprits. LOO protocol: remove one rule at a time across 3 training scenarios x 3 runs, compare to full-set condition.

## Decision

Accepted negative result: scenario 015 interference is stochastic (~1/3 of runs), not attributable to any specific IRON RULE. Removing IRON-004 does NOT fix 015 — contradicts Phase 45-47 hypothesis. IRON-001 is load-bearing for scenario 020 (removal causes regression). The right framing is scenario-type classification (all-or-nothing injection) rather than per-rule exclusion.

## Consequences

Per-rule selection criteria are not viable — the LOO signal is too noisy for fine-grained rule filtering. Phase 49 should pursue scenario-type classification (risk-dominant, capacity-constraint, domain-nuance) to decide inject-all vs inject-none. Ceiling effect (4/5 scenarios at 5/5/5) severely limits differentiation power — harder scenarios needed before per-rule attribution becomes meaningful. Cross-round baseline divergence means prior phase deltas are not directly comparable.
