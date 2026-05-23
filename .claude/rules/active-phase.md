# Active Phase Context

Phase: 27 - DX + Ship
Status: Active, 0/4 tasks done
Objective: Fix stale docs, add staleness regression tests, ship v0.5.0
Scope: README.md, tests/test_templates.sh, install.sh, VERSION

Key constraints: No new features, install.sh cosmetic only, README tests must compute actual counts dynamically.

Exit criteria: make test, make eval, grep -qx '0.5.0' VERSION, git tag v0.5.0 exists

Tests: 160 passing. Eval: 43/43.

Gates: [x] spec [x] approach [x] plan-review [x] tasks
