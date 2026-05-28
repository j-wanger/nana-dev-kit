---
title: Spec Reform — Reasoning Over Compliance
created: 2026-05-28
confidence: medium
source: plan
tags: [spec, experiment, reasoning]
---

# Spec Reform: Reasoning Over Compliance

## Decision

Reform the spec template from implementation-prescriptive to goal+constraint-oriented. Rename Deliverables → Success Vision, add Domain Research Questions, strengthen anti-prescriptive guidance in Approach.

## Context

Effectiveness experiment: open-ended prompts ("think about what creates edge", "justify your choices") scored +1.75 higher than prescriptive specs dictating schemas, libraries, and file structure. The best implementation (bare Claude, open-ended prompt) produced academic citations and honest backtesting — domain reasoning activated by the prompt style, not spec compliance.

## Changes

- Rename "Deliverables" → "Success Vision" (outcomes, not artifacts)
- Add "Domain Research Questions" subsection (prompts for investigation before design)
- Strengthen anti-prescriptive guidance: do NOT prescribe libraries, schemas, or file structures
- Update Tier 0 lint + spec-reviewer dimensions

## Trade-offs

**For:** Captures experiment's strongest signal (+1.75). Aligns with "context shaping is the highest-leverage work."
**Against:** Less deterministic specs may reduce engineering consistency. Finding may not generalize.
**Mitigation:** Keep Constraints, Exit Criteria, Checkpoints (the engineering floor). Only reform sections that dictate implementation (the ceiling).
