---
title: Cascade Failure via Silent Disablement
tags: [anti-pattern, transferable, activation-architecture]
created: 2026-05-28
updated: 2026-05-28
source: phase-55-cascade-failure-diagnosis
---

# Cascade Failure via Silent Disablement

## Anti-pattern

A component that isn't installed/registered causes downstream components to silently disable themselves, rather than failing loudly. The system appears functional but an entire subsystem is inactive.

## Symptoms

- Tests pass (they test individual components, not the activation chain)
- No error messages (fail-open design masks the gap)
- Features documented as available but never firing in practice
- Bug reports like "X doesn't seem to do anything" with no error trail

## Evidence

Three instances in nana-dev-kit history:
1. **pre-compact.sh** (Phase 15-23): hook script existed on disk but wasn't registered in settings.json. 8 phases before discovery.
2. **MCP memory server CWD** (Phase 4-38): settings.json pointed to wrong directory. Import check never ran. 34 phases before diagnosis.
3. **nana-init** (Phase 43-55): skill not installed → enforce marker not created → all enforcement hooks silently passed → cognitive layer fully disabled. 12 phases before root cause found.

## Root cause

Fail-open design (hooks exit 0 when preconditions aren't met) combined with no end-to-end activation test. Each component individually works, but the chain from "installed" to "active" has gaps that no single test covers.

## Fix

**Bidirectional registration invariant**: test that filesystem → config AND config → filesystem. Every component registered in configuration must exist on disk, and every component on disk must be registered in configuration. Phase 55 implemented this with 40 assertions in `test_registration.sh`.

**Functional smoke tests**: structural tests (file exists, grep for pattern) are necessary but not sufficient. At least one test per component must pipe real input through it and check output.
