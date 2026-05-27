---
id: IRON-005
trigger: "designing error handling, logging, or failure recovery"
domain: debugging
source_phase: multi
confidence: absolute
helpful: 0
harmful: 0
status: iron
---

# IRON RULE: Make Failure Visible, Not Silent

## When this applies
Any decision about how to handle errors, exceptions, missing data, configuration problems, or unexpected states. Applies to error handling strategy, logging decisions, monitoring design, and health check implementation.

## Always
- Surface errors at the point they are detected with enough context to diagnose
- Distinguish between expected absence (user choice) and unexpected failure (broken state)
- Include the specific failed expectation in error messages, not generic "something went wrong"
- Log the input that caused the failure, not just the failure type

## Never
- Catch exceptions and silently continue with default values
- Suppress errors because "it works fine without that feature"
- Log errors without the context needed to reproduce them
- Treat all errors the same regardless of severity or recoverability

## Why
Silent failures are the most expensive class of bugs because they compound over time. A silent failure today becomes a mysterious symptom weeks later, investigated by someone with no context on the original cause. The debugging cost of a silent failure is orders of magnitude higher than the cost of a loud failure at the point of origin. Every `except: pass`, every swallowed error, every missing error context is a time bomb with a random fuse length.

## Anti-pattern
"The optional subsystem failed, but the tool still works without it, so we'll just skip it silently" → 33 development iterations later, someone discovers the subsystem has been broken the entire time. The bug was trivial to fix but invisible because the error was suppressed. The cost was not the fix but the 33 iterations of degraded functionality that no one knew about.

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Bare `except: pass` or `catch {}` blocks | `grep -rn 'except.*pass\|catch.*{}'` finds matches outside of intentional cleanup code | Swallows every error including ones the developer never anticipated — turns bugs into silent data corruption |
| Generic error messages without context | Error log entries that contain "Error occurred" or "Failed" without the input, operation, or state that caused it | Debugging requires reproducing the exact conditions — without context in the error, reproduction is guesswork |
| Treating all failures as recoverable | `on_error: continue` or retry-without-backoff patterns in config for operations that can produce corrupt state | Retrying a write that partially succeeded can duplicate data; continuing after a constraint violation can cascade to downstream consumers |

## Source
Phase 4 (MCP CWD bug — 33 phases of silent failure), Phase 7 (optional subsystem health reporting), HEU-002 (fail-loud for optional subsystems). The 33-phase silent failure is the canonical example — a wrong working directory was never surfaced because "server not responding" was treated as "not configured."
