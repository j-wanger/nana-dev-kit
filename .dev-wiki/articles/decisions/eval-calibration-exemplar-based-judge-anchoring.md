---
title: "Eval Calibration — Exemplar-Based Judge Anchoring"
aliases: [exemplar-anchoring, judge-calibration-v2]
category: decisions
tags: [eval, reasoning, calibration, judge]
parents: [phase-45-eval-calibration-iron-rules]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

Phase 44's reasoning eval produced 5/5 scores across all 10 scenarios with 0 variance — the judge cannot differentiate reasoning quality levels. The descriptive rubric alone allows score inflation because the judge has no concrete examples of what a 3/5 vs 5/5 response looks like. This breaks the eval's ability to measure the impact of future reasoning features (IRON RULES, anti-pattern tables, etc.).

## Decision

Use exemplar-based anchoring in the v2 judge prompt: include concrete response examples at score levels 3 and 5 for each dimension (decision quality, reasoning quality, anti-pattern avoidance). The same judge prompt must be used for both baselines (calibration and IRON RULES measurement) to ensure comparability. Alternatives considered: cross-model judging (deferred — try calibration alone first; if it fails, cross-model becomes Phase 46), preference-based pairwise comparison (requires architecture change to run-eval.py, deferred).

## Consequences

Judge prompt v2 will be longer and more specific. Scores should spread across the 1-5 range instead of saturating at 5. The same-model grading bias remains (constant across conditions), but relative comparisons between conditions become valid. If exemplar anchoring alone fails to break the ceiling, the next lever is cross-model judging (different model family as judge).
