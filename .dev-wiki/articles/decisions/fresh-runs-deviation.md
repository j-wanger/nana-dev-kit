---
title: "Fresh Runs Deviation"
aliases: [fresh-runs, baseline-divergence-fresh-runs]
category: decisions
tags: [eval, baseline, comparison, methodology]
parents: [phase-49-conditional-heuristic-injection]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
---

## Context

Phase 48 ablation revealed baseline divergence: scenario 015 scored 5/5/5 in the prior `with-iron-rules/` round but ~3.67 in LOO traces run in a separate round. Cross-round comparison of absolute scores is invalid. Phase 49 needs 3-condition comparison (always-inject, conditional, no-inject), and reusing existing result files from prior phases would mix rounds.

## Decision

All 3 conditions must run fresh in the same evaluation round. No reuse of existing `with-iron-rules/results.json` or `baseline/results.json` from prior phases. Within-round deltas remain valid; cross-round absolute comparisons are not. This costs ~180 additional agent+judge invocations (3 conditions x 20 scenarios x 3 runs) but produces valid within-round deltas for all condition pairs.

Alternative considered: reuse existing condition data to save invocations. Rejected because baseline divergence evidence makes cross-round deltas unreliable.

## Consequences

- All 3 condition result files are produced in Phase 49 under consistent conditions
- Prior `with-iron-rules/` and `baseline/` results remain as historical data but are not used for Phase 49 comparisons
- Higher invocation cost (~180 vs ~60 if reusing 2 existing conditions)
- Analysis can use within-round deltas directly without caveats about cross-round validity
