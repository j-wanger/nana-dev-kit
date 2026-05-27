# IRON RULES — Apply these unconditionally to every decision

## IRON-001: Measure Before Optimizing
**Always:** Establish a quantitative baseline before changing anything. Define "better" measurably. Measure the actual bottleneck, not the suspected one.
**Never:** Optimize based on intuition. Skip profiling. Declare victory on microbenchmarks that don't reflect production.
**Anti-patterns to avoid:**
- Optimizing without a baseline (no benchmark numbers = no way to verify improvement)
- Microbenchmark-driven optimization (misses real bottlenecks like I/O, cache effects, contention)
- Premature caching (adds invalidation complexity when the cached operation wasn't the bottleneck)

## IRON-002: Check What Exists Before Building
**Always:** Search codebase for existing implementations. Check dependencies and standard libraries first. Ask "why doesn't this already exist?"
**Never:** Build new without checking if one exists. Assume absence. Justify new with "not quite right" without naming the specific gap.
**Anti-patterns to avoid:**
- Writing a custom parser when a stdlib exists (custom parsers miss edge cases the stdlib handles)
- Vendoring a library for one feature already in a dependency (adds supply chain surface and version conflicts)
- "Not quite right" without articulating the gap (gap is often cosmetic or fixable with a small patch)

## IRON-003: Validate at Boundaries, Trust Internally
**Always:** Validate external input at system boundary. Parse and validate once, pass typed data internally. Trust internal code past the boundary.
**Never:** Validate same data at every function call. Add defensive null checks deep inside validated code. Skip boundary validation because "the caller handles it."
**Anti-patterns to avoid:**
- Validation scattered across the call chain (obscures where the real boundary is)
- Missing boundary validation deferred to callers (callers forget — constraint in docs, not code)
- Over-validation of internal data with try/except and generic fallbacks (masks bugs with wrong default values)

## IRON-004: The Simpler System Wins Unless Proven Otherwise
**Always:** Default to simpler approach. Apply subtraction test. Count moving parts. Prefer easy to understand/debug/replace.
**Never:** Choose complex for hypothetical future needs. Add abstractions without current need. Justify with "we might need it later." Equate sophistication with quality. Confuse "less effort now" with "simpler system" — measure simplicity by total lifecycle complexity, not upfront cost. A cleanup that removes 80% of moving parts is the simpler path even if it costs more upfront.
**Anti-patterns to avoid:**
- Incremental cleanup of compounding debt ("clean up a few each sprint" — competes with features, loses every time, problem grows)
- Premature generalization via config (config file >500 lines = deferred complexity, every option is an invisible code branch)
- Avoiding a rewrite when old system complexity exceeds rewrite cost ("too risky" but every change triggers 3+ unrelated failures)

## IRON-005: Make Failure Visible, Not Silent
**Always:** Surface errors at detection point with context. Distinguish expected absence from unexpected failure. Include specific failed expectation, not generic messages. Log the failing input.
**Never:** Catch and silently continue with defaults. Suppress errors because "it works without that feature." Log without reproduction context. Treat all errors the same.
**Anti-patterns to avoid:**
- Bare `except: pass` or `catch {}` (swallows errors including unanticipated ones — turns bugs into silent data corruption)
- Generic error messages without context ("Error occurred" without input, operation, or state — makes debugging guesswork)
- Treating all failures as recoverable (retry-without-backoff or `on_error: continue` — retrying a partial write can duplicate data)
