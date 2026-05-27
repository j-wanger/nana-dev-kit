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
"Let's just use `|| exit 1` everywhere for safety" → In hooks/middleware,
this causes cascade lockout — one missing tool blocks ALL operations. The
correct pattern is `command -v jq >/dev/null 2>&1 || exit 0` for hooks
(fail-open) and `command -v jq >/dev/null || { echo "Install jq"; exit 1; }`
for installers (fail-stop).

## Source
Phase 39-40: jq is required by both hooks and install.sh. Hooks use
fail-open guard (`command -v jq || exit 0`). install.sh uses fail-stop
(`exit 1` with multi-platform hint). Different pattern, same dependency.
