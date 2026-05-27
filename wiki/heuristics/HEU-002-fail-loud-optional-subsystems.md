---
id: HEU-002
trigger: "implementing error handling for an optional subsystem that could silently break"
domain: architecture
source_phase: 4
confidence: high
helpful: 0
harmful: 0
status: active
---

# Heuristic: Fail-Loud Over Fail-Silent for Optional Subsystems

## When this applies
An optional subsystem (plugin, extension, integration) can gracefully degrade
when unavailable, but its failure mode could mask deeper bugs.

## Always
- Emit a visible warning (stderr, structured log) when an optional subsystem fails
- Distinguish "not configured" from "configured but broken" in your status output
- Include diagnostic detail (what was expected vs what was found)
- Log the failure even when gracefully degrading

## Never
- Silently swallow errors from optional subsystems
- Use `2>/dev/null || true` on subsystems that have configuration state
- Assume "optional" means "failure doesn't matter"

## Why
Silent failures persist indefinitely because nothing signals a problem. When
a subsystem is configured but broken, the user intended for it to work —
failing silently violates that intent and defers the debugging cost to a
moment of higher urgency.

## Anti-pattern
"It's optional, so we should just skip it silently" → This hides bugs for
months. A memory server CWD bug persisted for 33 phases because the failure
was silently swallowed. A 3-state output (healthy/broken/not-configured)
would have surfaced it immediately.

## Source
Phase 4: MCP memory server CWD bug hid for 33 phases due to silent failure.
Phase 39: 3-layer health probe introduced (config → import → entry count)
with 3-state output, immediately surfacing broken configurations.
