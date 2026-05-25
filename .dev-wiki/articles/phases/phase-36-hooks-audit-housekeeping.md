---
title: "Phase 36: Hooks Audit & Housekeeping"
aliases: []
category: phases
tags: [hooks, audit, housekeeping, nanaclaw, ts-init, readme]
parents: [phase-35-ts-init-implementation]
created: 2026-05-25
updated: 2026-05-25
source: plan
status: completed
scope: ["templates/.claude/hooks/*.sh", "README.md", ".dev-wiki/articles/decisions/*.md", "install.sh", "tests/*", "patches/", "templates/.claude/skills/ts-init/*", "templates/AGENTS-ts.md", "templates/.github/workflows/ci-ts.yml", ".dev-wiki/.hook-prefix-inventory.md", ".gitignore", "templates/.claude/skills/MANIFEST", "Makefile", "benchmark/README.md"]
entry_criteria: "Phase 35 complete, spec approved at specs/phase-36-hooks-audit-housekeeping.md (9/10), approach approved (8/10), plan reviewed (8/10), 224 tests passing, 47/47 eval"
exit_criteria: "12 machine-checkable items per spec: hook reconciliation article with all 6 dispositions, hook error evidence file, bash -n + set -euo pipefail on all kit hooks, README ts-init coverage, no stale 201, scratch inventory cleanup, nanaclaw PR URL or skipped reason, make test + make eval + install.sh --dry-run pass, MANIFEST freshness"
---

# Phase 36: Hooks Audit & Housekeeping

## Formal Spec

See [`specs/phase-36-hooks-audit-housekeeping.md`](../../../specs/phase-36-hooks-audit-housekeeping.md) for the approved spec (9/10, nana:approved marker present). The full constraint list, exit criteria, and checkpoints live there; this article summarizes.

## Objective

Diagnose and fix the hook errors Claude Code is surfacing in this project, reconcile kit-shipped (`templates/.claude/hooks/`) vs globally-installed (`~/.claude/hooks/`) hook sets into an explicit per-hook disposition, and bundle that with README ts-init coverage and an upstream nanaclaw sanitizer PR. Ship as housekeeping — no architectural changes, no L tasks.

## Scope

Files and modules affected:
- `templates/.claude/hooks/*.sh` -- all kit hooks (lint + targeted fixes + potential backports)
- `README.md` -- ts-init coverage, refreshed test count, stale 201 sweep
- `Makefile`, `install.sh`, `benchmark/README.md` -- stale 201 sweep
- `.dev-wiki/articles/decisions/hook-error-evidence.md` -- new (Task 1)
- `.dev-wiki/articles/decisions/hook-reconciliation.md` -- new (Task 2)
- `.dev-wiki/articles/decisions/nanaclaw-upstream-pr.md` -- new (Task 6)
- `tests/test_install.sh`, `tests/test_enforce.sh` -- updated if hook backport affects install
- `patches/nanaclaw-sanitize-fts.patch` -- read-only source for PR
- `templates/.claude/skills/ts-init/*`, `templates/AGENTS-ts.md`, `templates/.github/workflows/ci-ts.yml` -- TS polish spot-check
- `.dev-wiki/.hook-prefix-inventory.md`, `.gitignore` -- scratch cleanup
- `templates/.claude/skills/MANIFEST` -- regen if any skill file touched

## Exit Criteria

Summary (full list in spec, 12 machine-checkable items):

- [ ] hook-reconciliation.md lists disposition for all 6 global-only hooks
- [ ] hook-error-evidence.md exists with quoted errors OR "no errors found" branch (>=5 lines)
- [ ] `bash -n` and `set -euo pipefail` pass on every kit hook
- [ ] README has `/ts-init`, `--no-typescript`, "TypeScript" coverage
- [ ] No stale "201" test-count claim in README/Makefile/install.sh/benchmark/README.md
- [ ] `.hook-prefix-inventory.md` either deleted or gitignored
- [ ] `nanaclaw-upstream-pr.md` records PR URL OR `skipped: <reason>`
- [ ] `make test` passes (224+ tests)
- [ ] `make eval` passes (47/47)
- [ ] `bash install.sh --dry-run` still parses
- [ ] MANIFEST regenerated if any skill file under it changed (informational)

## Constraints

Summary (full list in spec, 8 CRITICAL constraints):

- No hook fix without quoted evidence (error string or specific lint finding) in commit message
- No global/kit divergence at end of phase (explicit disposition for all 6 global-only hooks)
- No silent settings.json breakage on hook rename
- Nanaclaw PR contains exactly one commit, no kit paths (push-only, clean branch)
- No stale "201 tests" claim survives the sweep
- `.hook-prefix-inventory.md` scratch never commits
- Hook changes are tested in tmpdir (`mktemp -d`), not against live phase-36 spec
- Node version claim in README is derived from `ci-ts.yml` matrix, not guessed

## Checkpoints

- After Task 1 (hook diagnosis evidence): report captured evidence + disposition matrix → wait for user confirmation before code changes
- After Task 2 (hook reconciliation): report 6-hook disposition (backport/delete/tolerate) → wait for user approval before executing
- After Task 6 (nanaclaw PR opened): report PR URL → wait for user confirmation, do NOT close or modify autonomously
- If hook lint surfaces >5 issues per hook: STOP, escalate (audit bigger than housekeeping)
- If a hook fix breaks `make test` or `make eval`: STOP, do not commit, ask
- If nanaclaw patch no longer applies cleanly to upstream HEAD: STOP, do not force-apply, ask

## Assumptions

- Hook errors are reproducible via `claude --debug`, `.dev-wiki/enforcement.log`, or session JSONL. If false: ask user to trigger and copy exact error string.
- Upstream `nanaclaw main` exists and accepts PRs (Jake owns repo). If false: `skipped: <reason>` branch.
- Existing kit hooks match Claude Code stdin/exit-code contract for registered events ([nana:<name>] prefix work done earlier). If false: contract drift surfaces in Task 3 lint.
- `jq` available locally (fail-open if missing). If false: distinguish "buggy hook" from "correctly fail-open warning".
- 224 test count current at phase start — verify with `make test 2>&1 | grep -c PASS` before README refresh.
- ts-init Node version derivable from `ci-ts.yml`. If unpinned: ask user before committing a number.

## Notes

- Approach: 8 workstreams in dependency order, all S/M (no L). See [[hook-reconciliation-approach]] for full sequencing rationale.
- 6 global-only hooks needing disposition: `context-size-check`, `dev-wiki-post-commit`, `dev-wiki-scope-check`, `post-compact`, `session-stop`, `stale-queue`. Two (`dev-wiki-post-commit`, `dev-wiki-scope-check`) are referenced by trigger pattern in kit-distributed `dev-wiki-hooks.md` rules — Task 2 disposition decides backport vs tolerate.
- Test count refresh set LAST (Task 5) so any new tests added by hook fixes are reflected.
- Hook fixes tested in `mktemp -d` tmpdir to avoid self-lockout via `enforce-spec.sh` regression.
- Nanaclaw PR is push-only (no bidirectional sync); patch at `patches/nanaclaw-sanitize-fts.patch` from Phase 34.

## Outcome

Phase completed 2026-05-25. All 8 tasks done, 12 exit criteria met. Key outcomes:
- install.sh rewritten: flat->nested schema, 11 global hooks, --project-local flag (~508 lines)
- 5 hooks backported to kit convention, 1 deleted (superseded)
- 240 tests (+16), 47/47 eval
- Nanaclaw upstream PR: https://github.com/j-wanger/nanaclaw/pull/1
- 1 USER OVERRIDE escape hatch: T4 expanded M->L (project-local install mode folded in)

Journal: [[2026-05-25-phase-36-hooks-audit-housekeeping-complete]]
