---
title: "Phase 2: Automated Testing"
status: active
phase: 2
created: 2026-05-15T13:03:48
updated: 2026-05-15
---

# Phase 2: Automated Testing

## Objective

Convert manual smoke tests from `self-test.md` into automated shell-based tests. Ensure install, sync, and template generation are verifiable without manual intervention.

## Approach

Pure bash test harness with isolated test scripts. Each test creates temp dirs, runs assertions, cleans up. `make test` orchestrates everything. No external test framework (zero-dependency). Template placeholder tests are structural (grep-based, not end-to-end).

## Scope

- `tests/**` (new directory)
- `Makefile` (test target addition)
- `self-test.md` (reference only)

## Exit Criteria

- [ ] `make test` runs an automated test suite
- [ ] Tests cover install.sh idempotency (run twice, same result)
- [ ] Tests cover sync-rules correctness (output files match expected content)
- [ ] Tests cover template placeholder substitution
- [ ] All tests pass

## Tasks

5 tasks planned (see tasks.md Phase 2 section):
1. tests/helpers.sh — shared assertions (S)
2. tests/test_install.sh — install idempotency (M)
3. tests/test_sync_rules.sh — sync correctness + error cases (M)
4. tests/test_templates.sh — placeholder presence (S)
5. Makefile test target — orchestration (S)

## Key Decisions

- [[pure-bash-test-harness]] — zero-dependency stays zero-dependency (high confidence)
- [[structural-placeholder-verification]] — grep-based checks, not end-to-end (high confidence)

## Notes

- Shell-based tests (bash scripts) are the natural fit — no Python dependency needed for the kit itself
- `self-test.md` documents 13 manual test cases; prioritize the automatable ones
- Tests use temp dirs for isolation: `HOME=$(mktemp -d)` for install tests, `TDIR=$(mktemp -d)` for sync tests
