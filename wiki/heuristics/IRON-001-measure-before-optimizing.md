---
id: IRON-001
trigger: "any performance optimization, efficiency improvement, or 'faster' initiative"
domain: architecture
source_phase: multi
confidence: absolute
helpful: 0
harmful: 0
status: iron
---

# IRON RULE: Measure Before Optimizing

## When this applies
Any decision involving performance optimization, efficiency improvement, latency reduction, or resource usage reduction. This includes code optimization, infrastructure scaling, caching decisions, and algorithm changes motivated by speed.

## Always
- Establish a quantitative baseline before changing anything
- Define what "better" means in measurable terms before starting
- Measure the actual bottleneck, not the suspected one
- Compare the measured improvement against the measured baseline

## Never
- Optimize based on intuition about what is slow
- Skip profiling because "it's obviously the database"
- Measure only the happy path when the bottleneck may be in error handling or edge cases
- Declare victory based on microbenchmarks that don't reflect production load

## Why
Human intuition about performance bottlenecks is wrong more often than right. The bottleneck you assume is rarely the actual bottleneck. Without measurement, you optimize the wrong thing — spending engineering time for zero user-visible improvement while the real bottleneck persists. Measurement also prevents premature optimization: if the baseline is already acceptable, the optimization has zero value regardless of its cleverness.

## Anti-pattern
"This function looks slow, let me rewrite it" → The function takes 2ms; the network call it precedes takes 800ms. The rewrite saves 1ms (invisible to users) while consuming a day of engineering time. Meanwhile, batching the network calls (the actual bottleneck) would save 600ms.

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Optimizing before establishing a baseline | Commit message contains "optimize" or "speed up" with no benchmark numbers in the PR description | No way to verify improvement — changes may be neutral or regressive and nobody would know |
| Microbenchmark-driven optimization | Benchmark file tests a single function in isolation with synthetic input (no I/O, no real data sizes) | Microbenchmarks miss the actual bottleneck — cache effects, I/O wait, and contention dominate production but are absent from micro tests |
| Premature caching | New cache layer added when no profiling data shows the cached operation is a bottleneck | Caches add invalidation complexity, memory pressure, and stale-data bugs. Net cost exceeds benefit when the cached operation was not the bottleneck |

## Source
nana-soul.md "Measurement before optimization" principle. Reinforced across 44 phases: eval design always establishes baselines before features (Phase 44), benchmark infrastructure before optimization (Phase 32-34).
