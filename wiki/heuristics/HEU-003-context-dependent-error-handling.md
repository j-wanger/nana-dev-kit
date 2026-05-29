---
id: HEU-003
trigger: "deciding between fail-stop and fail-open error handling"
domain: architecture
source_phase: 39
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Error Handling Strategy Depends on Execution Context

## When this applies
Choosing between fail-stop (crash, exit non-zero) and fail-open (warn and
continue) for a component that may encounter missing dependencies or errors.

## Always
- For one-time explicit operations (installers, migrations, deployments): fail-STOP with a clear error and remediation hint
- For continuous/recurring operations (hooks, middleware, event handlers): fail-OPEN with a visible warning
- For tests of an OPTIONAL dependency: probe for it once, then SKIP the dependent tests when absent (run the rest). A test suite is a recurring operation — a missing optional dep must not halt it.
- Document which strategy each component uses and why
- Include remediation guidance in the error message (e.g., "Install jq: brew install jq")

## Never
- Apply uniform error handling across all execution contexts
- Use fail-stop in event handlers that run on every tool call (causes cascade lockout)
- Use fail-open in installers (produces cryptic failures downstream)

## Why
The cost of failure differs by context. An installer that silently skips a
step produces a broken install with no signal. A hook that crashes on every
tool call locks out the entire workflow. Same dependency (e.g., jq), opposite
correct strategies.

## Anti-pattern

| Failure Mode | Detection Signal | Why It Fails |
|---|---|---|
| `\|\| exit 1` everywhere "for safety" | Used in a hook/event handler that runs on every tool call | Cascade lockout — one missing tool blocks ALL operations. Use `command -v jq \|\| exit 0` (fail-open) in hooks, `\|\| { echo "Install jq"; exit 1; }` (fail-stop) in installers |
| Optional-dep test assumes the dep is present | Test forces a feature flag on (e.g. `_vec_available=True`) then uses an artifact only created when the optional dep loaded | A missing OPTIONAL dependency hard-crashes that test and HALTS the whole suite, masking every downstream suite — looks like "the suite is broken" when it's one skippable test. Probe-and-skip instead (recurred Phases 56-58 before root-cause) |

## Source
Phase 39-40: jq is required by both hooks and install.sh. Hooks use
fail-open guard (`command -v jq || exit 0`). install.sh uses fail-stop
(`exit 1` with multi-platform hint). Different pattern, same dependency.
Phase 58 maintenance: `test_memory.sh` forced `_vec_available=True` and wrote
to `memories_vec`, hard-crashing `make test` when the OPTIONAL `sqlite-vec` was
absent — a test suite is a recurring operation, so the optional-dep tests must
probe-and-skip (FTS5-only), not assume-and-halt. See [[guard-optional-dep-tests]].
