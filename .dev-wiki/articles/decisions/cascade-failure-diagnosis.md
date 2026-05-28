---
title: Cascade Failure Diagnosis — nana-init Root Cause
created: 2026-05-28
confidence: high
source: plan
tags: [harness, installation, enforcement]
---

# Cascade Failure: nana-init → Enforcement Disabled

## Decision

The experiment's three issue categories (unwired hooks, unused cognitive tools, prescriptive specs) share a root cause: nana-init not installed properly. Fix nana-init + add bidirectional registration test.

## Cascade Chain

1. nana-init in modules.json core skills but not installed to ~/.claude/skills/
2. /nana-init fails when invoked → project scaffold incomplete
3. .claude/enforce marker never created
4. enforce-spec/enforce-loop/enforce-memory check for marker → fail-open (exit 0)
5. No spec gate → no /dev-plan → no cognitive tools fire

## Evidence

- State loader audit: 25 of 26 skills installed, nana-init missing
- Smoke invariant gap: tests check modules.json → filesystem, not reverse
- Third recurrence: pre-compact.sh (Phase 15-23), MCP CWD (Phase 4-38), now nana-init
- Additional orphan found: py-review-stop-prompt.md in templates but not in modules.json

## Resolution

Fix nana-init installation + register py-review-stop-prompt.md + bidirectional registration completeness test to prevent future orphans.
