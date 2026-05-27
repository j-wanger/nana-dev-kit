---
title: "Sequential Baseline Verification"
aliases: [baseline-first, baseline-verification]
category: decisions
tags: [eval, ablation, baseline, methodology]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
status: accepted
---

# Sequential Baseline Verification

## Context

Ablation protocol requires a fresh no-heuristic baseline on 5 differentiating scenarios. Two ordering strategies: run baseline first and verify consistency with existing v2 baseline before proceeding, or parallelize baseline with ablation runs for speed.

## Decision

Run baseline first, verify consistency with existing v2 results, checkpoint before proceeding to ablation. Spec requires this checkpoint. If baseline drifts from v2, ablation results would be uninterpretable against prior conditions.

## Consequences

Adds latency (baseline must complete before ablation starts). Provides a data-integrity checkpoint that catches prompt drift, model version changes, or eval infrastructure regressions before committing to 90 additional runs.
