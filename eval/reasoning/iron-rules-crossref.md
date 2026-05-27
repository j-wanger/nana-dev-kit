# IRON RULES Cross-Reference Against Seed Heuristics

Cross-referencing 5 IRON RULES against 10 seed heuristics (HEU-001 through HEU-010) for semantic contradictions.

## Methodology

For each IRON RULE's Always/Never clause, check whether following it simultaneously with any HEU Always/Never clause creates an impossible situation.

## Results

### IRON-001 (Measure Before Optimizing) vs HEU-001 through HEU-010

- **vs HEU-005 (Prefilter Before Business Logic):** COMPATIBLE. HEU-005 says "write baseline tests BEFORE optimizing" — directly aligns with IRON-001's "establish a quantitative baseline." Both require measurement before action.
- **vs HEU-008 (Pure Implementations for Latency):** COMPATIBLE. HEU-008 says "profile first, then decide." IRON-001 reinforces this. No conflict.
- All other HEUs: no intersection with optimization decisions. **No conflicts.**

### IRON-002 (Check Existing Before Building) vs HEU-001 through HEU-010

- **vs HEU-010 (Extend via Extension Points):** COMPATIBLE. HEU-010 says "check for extension points first" — aligns with IRON-002's "search the codebase for existing implementations." Both push toward reuse before creation.
- **vs HEU-009 (Design Spec Cross-Domain):** COMPATIBLE. HEU-009 requires enumeration of existing assumptions before building. IRON-002 requires checking existing code before building. Both discourage building from scratch.
- All other HEUs: no intersection. **No conflicts.**

### IRON-003 (Validate at Boundaries) vs HEU-001 through HEU-010

- **vs HEU-002 (Fail Loud Optional Subsystems):** COMPATIBLE. HEU-002 says "distinguish not-configured from configured-but-broken" — this IS boundary validation (checking configuration state at the boundary). IRON-003 says "validate at boundaries, trust internally" — health checks on optional subsystems are boundary validation.
- **vs HEU-003 (Context-Dependent Error Handling):** COMPATIBLE. HEU-003 differentiates error handling by context (install vs hook). IRON-003 differentiates validation by position (boundary vs internal). Different axes, no conflict.
- **vs HEU-004 (Functional Smoke Tests):** POTENTIAL TENSION. HEU-004 says "pipe real input and check output" for every component. IRON-003 says "trust internal code." Resolution: smoke tests are a boundary validation mechanism (testing the component at its interface boundary), not deep internal validation. **No actual conflict** — HEU-004 tests at component boundaries, IRON-003 trusts within components.
- All other HEUs: no intersection. **No conflicts.**

### IRON-004 (Simpler System Wins) vs HEU-001 through HEU-010

- **vs HEU-006 (Two-Tier Review):** POTENTIAL TENSION. HEU-006 recommends two-tier review (structural + semantic) which adds process complexity. Resolution: HEU-006 is about review methodology, not system architecture. IRON-004 applies to system design complexity, not process design. Two-tier review reduces total effort (cheap structural checks save expensive semantic review time). **No actual conflict** — IRON-004 targets unnecessary complexity, HEU-006 targets efficient complexity.
- **vs HEU-007 (Dual Condition False Positives):** POTENTIAL TENSION. HEU-007 says "require conjunction of two independent signals" which is more complex than a single signal. Resolution: IRON-004 says "simpler UNLESS proven otherwise" — HEU-007 provides the proof (single signals have unacceptable false positive rates). **No actual conflict** — the dual condition is justified complexity.
- All other HEUs: no intersection. **No conflicts.**

### IRON-005 (Make Failure Visible) vs HEU-001 through HEU-010

- **vs HEU-003 (Context-Dependent Error Handling):** POTENTIAL TENSION. HEU-003 says hooks should "fail-open" (exit 0), which could be interpreted as hiding failure. Resolution: HEU-003's fail-open means "don't BLOCK the operation" but still requires "visible warning" (stderr). IRON-005 says "make failure visible" — a fail-open hook that emits a warning IS making failure visible without blocking. **No conflict** — fail-open ≠ silent failure. HEU-003 already specifies "visible warning" alongside fail-open.
- **vs HEU-002 (Fail Loud Optional Subsystems):** COMPATIBLE. IRON-005 is a generalization of HEU-002. Both require surfacing failures. HEU-002 is the specific case (optional subsystems); IRON-005 is the general principle.
- All other HEUs: no intersection. **No conflicts.**

## Summary

**0 actual conflicts found** across 50 cross-reference pairs (5 IRON × 10 HEU). 4 potential tensions identified and resolved — in each case, the IRON RULE and heuristic operate on different axes or the heuristic provides justified complexity that IRON RULE explicitly permits ("unless proven otherwise"). No precedence clauses needed.
