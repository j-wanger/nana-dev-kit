---
id: HEU-008
trigger: "implementing logic in a latency-critical code path (hooks, middleware, hot loops)"
domain: architecture
source_phase: 17
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Pure Implementations for Latency-Critical Paths

## When this applies
Writing code that runs on every request, tool call, event, or iteration —
where each invocation has a strict latency budget (typically <50-100ms).

## Always
- Measure the subprocess/interpreter startup cost before choosing a language
- For <50ms budgets: use the runtime's native language (bash for shell hooks, JS for Node middleware)
- For <200ms budgets: subprocess is acceptable if the logic is complex enough to justify it
- Profile first, then decide — don't assume overhead

## Never
- Spawn a subprocess (Python, Node, etc.) in a <50ms path without measuring the startup cost
- Choose a language for "convenience" in a path that runs thousands of times per session
- Add network calls (HTTP, IPC) to per-event hooks

## Why
Subprocess spawning has a fixed overhead (~20ms for Python on macOS, ~10ms
for Node). In a <50ms budget, that's 40-100% of the total. The logic itself
may take microseconds — the overhead dominates. Pure implementations avoid
this entirely.

## Anti-pattern
"Python is easier to write, it'll be fast enough" → 20ms subprocess
overhead + 5ms logic = 25ms. For a PostToolUse hook that fires on every
tool call, this adds up to seconds per session. Pure bash at <1ms total
makes the hook invisible. Measure before deciding.

## Source
Phase 17: detect-loop.sh implemented as pure bash (PostToolUse <50ms budget).
Python subprocess would add ~20ms overhead per invocation. Phase 24: jq
replaced python3 -c for JSON parsing in 6 hooks for the same reason.
