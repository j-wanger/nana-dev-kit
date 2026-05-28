---
title: "Three-Type Taxonomy Only"
aliases: [3-type-taxonomy, scenario-type-taxonomy-scope]
category: decisions
tags: [eval, classification, taxonomy, heuristic]
parents: [phase-49-conditional-heuristic-injection]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

Phase 48 selection criteria established 3 scenario types (risk-dominant, capacity-constraint, domain-nuance) based on the dominant property that determines IRON RULES effectiveness. A 4th "ceiling/undifferentiated" type was considered for the ~16 scenarios that score 5/5/5 regardless of injection condition.

## Decision

Use exactly 3 types. No 4th "ceiling" or "undifferentiated" type. Ceiling is an outcome property (how a scenario scores under current evaluation), not a scenario property (what makes it hard). A taxonomy based on outcome properties is not transferable to new scenarios — you can't classify a new scenario as "ceiling" without running the eval first.

Alternative considered: 4th "ceiling" type to explicitly mark undifferentiated scenarios. Rejected because taxonomy should be property-based and transferable to scenarios not yet evaluated.

## Consequences

- All 20 scenarios classified into exactly 3 types, including the ~16 at ceiling
- Taxonomy is property-based and can classify new scenarios without prior eval data
- The "ceiling" finding is documented as an evaluation limitation, not a scenario property
- Conditional injection logic has 3 branches (or effectively 2: risk-dominant vs everything else)
