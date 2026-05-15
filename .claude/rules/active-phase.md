# Active Phase Context

Phase: 2 - Automated Testing
Objective: Create `make test` target with automated test suite covering install.sh, sync-rules.sh, and template placeholders.
Scope: tests/*.sh, Makefile
Key constraints:
- Pure bash test harness — no external test frameworks (zero-dependency)
- Each test script sources tests/helpers.sh for shared assertions
- Tests must use temp dirs for isolation (mktemp -d), clean up after themselves
- Template tests are structural (grep for placeholder patterns), not end-to-end
Exit criteria:
- `make test` runs automated test suite
- Tests cover install.sh idempotency, sync-rules correctness, template placeholders
- All tests pass
Abort: if blocked >3 attempts on any task, ask user: skip or abort
