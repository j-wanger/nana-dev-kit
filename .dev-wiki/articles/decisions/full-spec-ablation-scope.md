---
title: "Full-Spec Ablation Scope (105 runs)"
aliases: [comprehensive-ablation, ablation-scope]
category: decisions
tags: [eval, ablation, iron-rules, reasoning, trace]
parents: [phase-48-trace-collection-pattern-analysis]
created: 2026-05-27
updated: 2026-05-27
source: plan
confidence: high
status: accepted
---

# Full-Spec Ablation Scope (105 runs)

## Context

Phase 48 needs to determine which IRON RULES help or hurt on which scenarios. Three ablation scope options were considered: focused (36 runs, only top 2 suspect rules), comprehensive (105 runs, all 5 rules x 5 scenarios x leave-one-out), or skip (defer to Phase 49). Existing data shows IRON-004/005 interference on scenarios 015/018/020, but behavior of IRON-001/002/003 on differentiating scenarios is unknown.

## Decision

Chose comprehensive ablation (105 runs: 15 baseline + 15 full-set + 75 leave-one-out) over focused (36 runs) or skipping. The full matrix provides the attribution foundation for Phase 49 selection criteria. Completeness catches unexpected effects on scenarios 014/015/020 where partial data might miss interactions.

## Consequences

Higher compute cost (~105 subagent invocations). Provides a complete 5x5x3 attribution matrix. Selection criteria in Phase 49 can be derived from complete data rather than interpolated from partial observations. If variance is high (>= 0.5 on any condition), the stop rule triggers early.
