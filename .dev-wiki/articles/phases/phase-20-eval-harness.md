---
title: "Phase 20: Eval Harness"
aliases: []
category: phases
tags: [eval, testing, benchmark, hooks, lifecycle]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: completed
scope: ["eval/**", "scripts/eval-runner.sh", "Makefile"]
entry_criteria: "Phase 19 complete, 128 tests passing, spec approved"
exit_criteria: "eval corpus 16+ scenarios, eval-runner.sh scores, make eval target, 128 tests still pass"
---

# Phase 20: Eval Harness

## Objective

Build a benchmark corpus and reproducible eval runner that validates nana-dev-kit's hooks, skill contracts, and lifecycle compliance against realistic fixture scenarios -- producing quantitative scores that track harness quality over time.

## Scope

Files and modules affected:
- `eval/corpus/` -- scenario directories (hook-*, skill-*, lifecycle-*)
- `eval/schemas/` -- JSON input schemas for hook contracts
- `eval/validators/` -- bash validation scripts for skill artifact contracts
- `scripts/eval-runner.sh` -- corpus runner with scoring and isolation
- `eval/README.md` -- corpus documentation
- `Makefile` -- new eval target

## Exit Criteria

- [ ] `test -d eval/corpus && [ $(find eval/corpus -name 'scenario.json' | wc -l) -ge 16 ]`
- [ ] `test -d eval/schemas && [ $(ls eval/schemas/*.json 2>/dev/null | wc -l) -ge 3 ]`
- [ ] `test -f scripts/eval-runner.sh && bash -n scripts/eval-runner.sh`
- [ ] `test -f eval/README.md`
- [ ] `grep -q '^eval[[:space:]]*:' Makefile`
- [ ] `make eval && make eval 2>&1 | grep -qE 'Score: [0-9]'`
- [ ] `make test`

## Constraints

- Every eval scenario runs in isolated HOME (tmpdir): prevents corruption of developer's ~/.claude/ or repo state
- Eval runner is pure bash + jq (no Python): consistent with existing test infrastructure
- `make eval` separate from `make test`: eval has different semantics (scores vs pass/fail)
- Scenario manifests are JSON (not embedded bash): enables future tooling
- Synthetic skill exemplars must NOT contain real project data or user-identifying information

## Assumptions

- jq is available on the eval machine. If false: fall back to Python json.tool or grep-based extraction
- Hook JSON input shapes match the fields parsed by templates/.claude/hooks/*.sh. If false: update schemas
- Eval runner completes in under 60 seconds. If false: add --quick flag for hook-only runs

## Formal Spec

See `specs/phase-20-eval-harness.md` (approved).

## Notes

Existing test infrastructure: helpers.sh (74 lines), 6 test scripts (128 tests). Eval supplements but does not replace these tests. Three decisions made during planning: binary scoring only, jq as hard dependency, eval/ as top-level directory.
