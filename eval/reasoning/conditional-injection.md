# Conditional IRON RULES Injection

This template implements scenario-type-gated heuristic injection for the reasoning eval. The eval subagent checks the scenario's `scenario_type` field and conditionally includes or suppresses the IRON RULES prefix.

## Gate Logic

Read the scenario JSON's `scenario_type` field before generating your response:

- **If `scenario_type` is `risk-dominant`:** Do NOT apply the IRON RULES below. Respond to the scenario using only your own reasoning. The IRON RULES can interfere with risk-dominant scenarios where the primary decision axis is risk management.

- **If `scenario_type` is `capacity-constraint` or `domain-nuance`:** Apply the following IRON RULES as a reasoning framework before answering.

## IRON RULES (inject when scenario_type is NOT risk-dominant)

The following rules are sourced from `iron-rules-injection-v2.md`. When injected, they serve as unconditional reasoning heuristics.

### IRON-001: Measure Before Optimizing
**Always:** Establish a quantitative baseline before changing anything. Define "better" measurably. Measure the actual bottleneck, not the suspected one.
**Never:** Optimize based on intuition. Skip profiling. Declare victory on microbenchmarks that don't reflect production.

### IRON-002: Check What Exists Before Building
**Always:** Search codebase for existing implementations. Check dependencies and standard libraries first. Ask "why doesn't this already exist?"
**Never:** Build new without checking if one exists. Assume absence. Justify new with "not quite right" without naming the specific gap.

### IRON-003: Validate at Boundaries, Trust Internally
**Always:** Validate external input at system boundary. Parse and validate once, pass typed data internally. Trust internal code past the boundary.
**Never:** Validate same data at every function call. Add defensive null checks deep inside validated code. Skip boundary validation because "the caller handles it."

### IRON-004: The Simpler System Wins Unless Proven Otherwise
**Always:** Default to simpler approach. Apply subtraction test. Count moving parts. Prefer easy to understand/debug/replace.
**Never:** Choose complex for hypothetical future needs. Add abstractions without current need. Confuse "less effort now" with "simpler system" — measure simplicity by total lifecycle complexity, not upfront cost.

### IRON-005: Make Failure Visible, Not Silent
**Always:** Surface errors at detection point with context. Distinguish expected absence from unexpected failure. Include specific failed expectation, not generic messages.
**Never:** Catch and silently continue with defaults. Suppress errors because "it works without that feature." Log without reproduction context.
