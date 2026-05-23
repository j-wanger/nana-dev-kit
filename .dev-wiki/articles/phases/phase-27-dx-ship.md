---
title: "Phase 27: DX + Ship"
aliases: []
category: phases
tags: [dx, ship, readme, version, regression-tests]
parents: []
created: 2026-05-23
updated: 2026-05-23
source: plan
status: active
scope: ["README.md", "tests/test_templates.sh", "install.sh", "VERSION"]
entry_criteria: "Phase 26 complete, 159 tests passing, 43/43 eval"
exit_criteria: "README numbers fixed, staleness regression tests pass, install.sh summary updated, v0.5.0 tagged, make test + make eval pass"
---

# Phase 27: DX + Ship

## Objective

Fix stale documentation numbers across README.md, add regression tests that dynamically detect documentation drift, polish install.sh summary output, and ship v0.5.0.

## Scope

Files and modules affected:
- `README.md` -- fix 5 stale numbers (eval scenario count, hook fidelity count, test count)
- `tests/test_templates.sh` -- add dynamic count assertions for README accuracy
- `install.sh` -- update echo lines to list all 5 global hooks (cosmetic only)
- `VERSION` -- bump to 0.5.0

## Exit Criteria

- [ ] README.md has accurate counts for eval scenarios, hook fidelity, and tests
- [ ] Staleness regression tests compute actual counts and compare to README claims
- [ ] install.sh summary mentions all 5 global hooks
- [ ] VERSION contains 0.5.0
- [ ] v0.5.0 tag exists
- [ ] make test passes
- [ ] make eval passes

## Constraints

- No new features: this phase is documentation and packaging only
- install.sh changes are cosmetic (echo lines only, no functional changes)
- README regression tests must compute actual counts dynamically, not assert hardcoded numbers

## Notes

No new architectural decisions. This phase executes existing conventions (VERSION as single source of truth, test_templates.sh as regression test home).
