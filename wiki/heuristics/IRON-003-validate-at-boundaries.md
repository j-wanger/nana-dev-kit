---
id: IRON-003
trigger: "designing input handling, API contracts, or system integration points"
domain: architecture
source_phase: multi
confidence: absolute
helpful: 0
harmful: 0
status: iron
---

# IRON RULE: Validate at Boundaries, Trust Internally

## When this applies
Any decision about where to place validation, error checking, or input sanitization. Applies to function signatures, API endpoints, configuration parsing, file I/O, and inter-service communication.

## Always
- Validate all external input at the system boundary (user input, API requests, file reads, environment variables)
- Parse and validate once at entry, then pass typed/validated data internally
- Trust internal code that has already passed boundary validation
- Define clear contracts at module boundaries

## Never
- Validate the same data at every function call in a chain
- Add defensive null checks deep inside code that only receives validated input
- Skip boundary validation because "the caller should handle it"
- Treat internal function calls with the same suspicion as external input

## Why
Redundant internal validation creates noise that obscures real boundary violations. If every function checks its inputs, bugs at the actual boundary (where untrusted data enters) are harder to find because they are buried in hundreds of identical checks. Conversely, missing boundary validation is a security and reliability risk because it is the one place where untrusted data becomes trusted. The rule creates a clear trust gradient: untrusted outside, validated at boundary, trusted inside.

## Anti-pattern
"Let's add a null check just to be safe" deep inside a function that only receives data from an internal constructor that guarantees non-null → The check never fires, adds visual noise, and gives a false sense of security. Meanwhile, the actual API endpoint that accepts user input has no validation because "the internal functions handle it."

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| Validation scattered across the call chain | Same field checked with `if x is None` or `isinstance(x, ...)` in 3+ functions in one call path | Redundant checks obscure where the real boundary is — when a boundary bug occurs, it is hidden in a forest of identical checks that all pass |
| Missing boundary validation deferred to callers | Public function docstring says "caller must ensure X" without enforcing it | Callers forget, especially new contributors. The constraint lives in documentation, not code — it will be violated |
| Over-validation of internal data | `try/except` wrapping every internal function call with generic fallback values | Masks bugs by silently replacing broken data with defaults — the system appears to work but produces wrong results |

## Source
OWASP input validation principles. Reinforced by hook architecture decisions (Phase 16-17): enforce-spec.sh validates at the hook boundary (stdin JSON), then trusts parsed fields internally. Working-knowledge: "Only validate at system boundaries (user input, external APIs)."
