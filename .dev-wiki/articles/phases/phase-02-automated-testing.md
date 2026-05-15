---
title: "Phase 2: Automated Testing"
status: not-started
phase: 2
created: 2026-05-15T13:03:48
---

# Phase 2: Automated Testing

## Objective

Convert manual smoke tests from `self-test.md` into automated shell-based tests. Ensure install, sync, and template generation are verifiable without manual intervention.

## Scope

- `tests/**`
- `Makefile` (test target)
- `self-test.md` (reference)

## Exit Criteria

- [ ] `make test` runs an automated test suite
- [ ] Tests cover install.sh idempotency (run twice, same result)
- [ ] Tests cover sync-rules correctness (output files match expected content)
- [ ] Tests cover template placeholder substitution
- [ ] All tests pass

## Notes

- Shell-based tests (bash scripts) are the natural fit — no Python dependency needed for the kit itself
- `self-test.md` documents 13 manual test cases; prioritize the automatable ones
