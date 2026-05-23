---
title: "Phase 21: Eval Expansion"
aliases: [phase-21-eval-expansion]
category: phases
tags: [eval, hooks, coverage, lifecycle, context]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: completed
scope: ["eval/**", "scripts/eval-runner.sh", "eval/validators/**", "eval/README.md"]
entry_criteria: "Phase 20 complete, 18/18 eval scenarios passing, 128 tests passing"
exit_criteria: "30+ scenarios across 4 categories (hook, skill, context, lifecycle), all passing, 128 tests still pass"
---

# Phase 21: Eval Expansion

## Objective

Extend the eval harness from 18 to 36+ scenarios across three expansion axes: structural coverage for 5 uncovered bash hooks, a new context eval category that validates rule files reach Claude's context window correctly, and lifecycle scenarios that chain multiple hooks in realistic session flows.

## Scope

Files and modules affected:
- `scripts/eval-runner.sh` -- new `context)` category case with checks array dispatch
- `eval/corpus/` -- 18+ new scenario directories (hook-audit-*, hook-auto-ruff-*, hook-scan-*, hook-block-*, hook-check-tests-*, context-*, lifecycle-*, skill-prompt-*)
- `eval/validators/validate-prompt.sh` -- new validator for skill prompt files
- `eval/README.md` -- documentation updates for context category

## Approach

1. Runner first: add context category to eval-runner.sh (checks array with file_exists, section_present, hook_output types)
2. Hook scenarios grouped by stdin contract: PostToolUse (audit-log, auto-ruff, scan-secrets), then PreToolUse+Stop (block-dangerous-bash, check-tests-were-run)
3. Context scenarios: validate soul sections, file-lifecycle, session-start guidance, rules installation
4. Lifecycle + docs: 2-3 multi-hook chain scenarios, update README

## Exit Criteria

- [ ] `[ $(find eval/corpus -name 'scenario.json' | wc -l) -ge 30 ]`
- [ ] `make eval && make eval 2>&1 | grep -qE 'Score.*100'`
- [ ] `make eval 2>&1 | grep -qi 'context'`
- [ ] `test -f eval/validators/validate-prompt.sh`
- [ ] `make test`

## Constraints

- Eval must run on any machine with bash+jq (no ruff, gitleaks, or other external tool requirements)
- Fixture JSON must match per-hook field paths (not uniform)
- `make eval` remains separate from `make test`

## Formal Spec

See `specs/phase-21-eval-expansion.md` (approved, revised-to-accept).

## Notes

3 decisions made during planning: context-eval-new-category (new runner category), hook-stdin-per-hook-contracts (per-hook fixture JSON), eval-missing-tool-fallback-only (test graceful-skip paths). Knowledge wiki DB was empty -- no articles retrieved; approach confirmed by index references to eval-harness-design and hooks-deterministic-control-points.
