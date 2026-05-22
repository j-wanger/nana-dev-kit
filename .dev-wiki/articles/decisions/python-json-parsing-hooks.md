---
title: Python JSON parsing in hooks
status: accepted
confidence: high
date: 2026-05-22
source: plan
tags: [hooks, json, python, consistency]
---

# Python JSON parsing in hooks

## Context

Enforcement hooks receive JSON on stdin (tool input for PreToolUse, session context for Stop). Need to parse `file_path` from nested JSON reliably within the 100ms hook budget.

## Decision

Use inline Python (`python3 -c '...'`) for JSON stdin parsing in enforcement hooks, consistent with existing hook patterns (block-dangerous-bash.sh, check-tests-were-run.sh).

## Rationale

- **Consistency:** Existing hooks already use this pattern. Same parsing approach reduces cognitive load.
- **Reliability:** Python's `json` module handles edge cases (escaped paths, unicode, nested structures) that grep/sed cannot.
- **Availability:** python3 is a hard dependency of nana-dev-kit (memory_server requires it). No additional dependency.
- **Performance:** ~20ms for Python JSON parse, well within 100ms budget.
- **Alternative rejected:** jq (not guaranteed available on all systems), pure bash grep/sed (fragile for nested JSON, breaks on special characters in paths).

## Consequences

- Hooks require python3 in PATH (already guaranteed by install.sh prereq check)
- ~20ms overhead per hook invocation for Python startup + parse
- JSON parsing is robust to path edge cases (spaces, special characters)

## Related

- [[pure-bash-test-harness]] — tests are pure bash, but hooks are allowed python3
