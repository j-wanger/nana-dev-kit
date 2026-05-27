---
title: "Scenario-Type Selection Criteria"
aliases: [scenario-type-criteria, selection-criteria-granularity]
category: decisions
tags: [eval, heuristics, selection, scenario-types, reasoning]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
status: accepted
---

# Scenario-Type Selection Criteria

## Context

Attribution matrix is per-dimension (heuristic x scenario x dimension = 75 classifications). Selection criteria could operate at the same granularity (per-scenario lookup) or at scenario-type level (risk-dominant, capacity-constraint, domain-nuance). Per-scenario is precise but doesn't generalize to new scenarios.

## Decision

Matrix stays per-dimension (3D) for data completeness. Selection criteria operate at scenario-type level (risk-dominant, capacity-constraint, domain-nuance features). More generalizable than per-scenario lookup — new scenarios can be classified by type without rerunning ablation.

## Consequences

Requires a scenario-type taxonomy derived from the 5 differentiating scenarios. Held-out validation (012, 014) tests whether type-based criteria predict rule behavior on unseen scenarios. If type-level granularity is insufficient, per-scenario fallback is available from the matrix data.
