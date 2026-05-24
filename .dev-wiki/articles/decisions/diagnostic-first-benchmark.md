---
title: "Diagnostic-first benchmark"
aliases: [longmemeval-diagnostic-first, benchmark-diagnostic-threshold]
category: decisions
tags: [benchmark, memory, evaluation]
parents: [phase-32-longmemeval-s-benchmark]
created: 2026-05-24
updated: 2026-05-24
source: debrief
confidence: high
status: active
---

## Context

LongMemEval-S benchmark will measure memory_server retrieval quality. Results may or may not be suitable for external communication (README inclusion). Need to decide whether to commit to publishing results before knowing what they look like.

## Decision

Diagnostic-first: run the benchmark to inform quality improvements. README inclusion is conditional on FTS5 recall@5 exceeding 50%. If below threshold, results remain internal (benchmark/results.json) and guide future retrieval improvements rather than being presented as a feature claim.

## Consequences

- No premature claims about retrieval quality in README.
- Benchmark infrastructure exists regardless of result quality, enabling iterative improvement.
- Clear threshold (50% recall@5 FTS5) gates external communication.
- If results are poor, they still provide value as a diagnostic baseline for future work.

## Validation (Phase 32 results)

FTS5 recall@5 = 91.0% (well above 50% threshold). README inclusion approved. Multi-session (83.7%) and temporal-reasoning (86.9%) weakest categories, suggesting multi-hop retrieval as future improvement area. Hybrid mode untested.
