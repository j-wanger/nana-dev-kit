---
title: Pure bash for detect-loop.sh
status: accepted
confidence: high
date: 2026-05-22
source: plan
tags: [hooks, bash, performance, loop-detection]
parents: [phase-17-harden]
---

# Pure bash for detect-loop.sh

## Context

detect-loop.sh is a PostToolUse hook that must track consecutive identical failed Bash commands and emit advisory warnings. The hook runs on every tool use, so performance is critical. The existing convention from Phase 16 ([[python-json-parsing-hooks]]) is to use inline python3 for JSON parsing in hooks.

## Decision

Use pure bash (grep/sed) for detect-loop.sh, creating an exception to the python-json-parsing-hooks convention. The JSON structure parsed (command + exit code from PostToolUse input) is simple flat fields that grep handles reliably.

## Rationale

- **Performance:** <50ms budget for PostToolUse hooks. Python subprocess adds ~20ms startup overhead that consumes nearly half the budget. Pure bash avoids this entirely.
- **Simplicity:** PostToolUse JSON is simpler than PreToolUse (no nested input.file_path). grep/sed can extract command and exit_code without full JSON parsing.
- **Exception scope:** This is a narrow exception — enforcement hooks (enforce-spec.sh, enforce-loop.sh) still use Python for their more complex JSON structures. The exception is justified by the performance constraint, not a general preference.
- **Alternative rejected:** Python JSON parsing (consistent but too slow for the per-tool-call budget).

## Consequences

- detect-loop.sh does not require python3 (could run in python-less environments)
- JSON parsing is fragile for edge cases (commands containing quotes/special chars in JSON values) — acceptable because loop detection only needs approximate matching, not exact command parsing
- Sets precedent that simple-JSON hooks may use pure bash with documented justification

## Related

- [[python-json-parsing-hooks]] — the convention this creates an exception to
