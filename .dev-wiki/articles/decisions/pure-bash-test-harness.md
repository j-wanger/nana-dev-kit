---
title: "Pure bash test harness"
aliases: [bash test harness, zero-dep tests]
category: decisions
tags: [testing, bash, zero-dependency]
parents: [phase-02-automated-testing]
created: 2026-05-15
updated: 2026-05-15
source: plan
confidence: high
---

## Context

Phase 2 needs an automated test suite. The project is zero-dependency (bash only), so the test framework choice must align with that constraint. Two options were considered: a pure bash harness with simple assert functions in helpers.sh, or bats-core, a structured bash testing framework.

## Decision

Pure bash test harness with assert functions in `tests/helpers.sh`. Each test script sources helpers.sh, creates temp dirs, runs assertions, and cleans up. `make test` orchestrates all scripts fail-fast.

bats-core was rejected because it adds an external dependency, violating the project's zero-dependency principle. The test suite is small enough that simple assert functions (assert_eq, assert_file_exists, assert_contains, assert_exit_code) are sufficient.

## Consequences

- Test suite stays zero-dependency, consistent with the rest of the kit
- No structured TAP output or test isolation features that bats-core provides
- Test reporting is manual (pass/fail counts in helpers.sh summary function)
- If the test suite grows significantly, this decision may need revisiting
