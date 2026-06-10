---
title: "Codebase Snapshot (Phase 84 ready for completion)"
aliases: []
category: status
tags: [snapshot, phase-84]
parents: [phase-84-hook-registration-hygiene]
created: 2026-06-10
updated: 2026-06-10
source: debrief
---

# Codebase Snapshot — 2026-06-10

## Metrics
- Test suite: `make test` green — 25 scripts (~500 assertions; Phase 84 added test_eval_hermeticity.sh, test_fixture_provenance.sh, test_lifecycle_hooks_firing.sh, +25 tests)
- Eval: `make eval` 52/52 (unchanged denominator; 2 explained init_git flips, resolved — eval/hook-hygiene/eval-diff.md)
- Drift: `check-install-drift.sh --count` → 0
- Exit criteria: 10/10 via eval/hook-hygiene/run-exit-criteria.sh (criteria 3-5 N/A-upstream for detect-loop)
- Skills: 26 dirs; hooks: 18 template .sh (+3 session-start.d modules); eval corpus: 52 scenarios

## Structure Changes (Phase 84)
- NEW `eval/hook-hygiene/` (capture-diagnosis, eval-diff, coverage-matrix, check-matrix.sh, rehearsal.log, run-exit-criteria.sh)
- NEW `tests/fixtures/real-events/` (byte-for-byte PostToolUse captures + provenance sidecars)
- `scripts/eval-runner.sh` hermetic (CLAUDE_PROJECT_DIR=$WORK_DIR in run_hook) + lifecycle init_git support
- `templates/.claude/hooks/post-commit.sh` redesigned (event-arrival-as-success)
- Kit repo self-consumes: gitignored `.claude/settings.json` + `.claude/hooks/`
- Machine-wide (out-of-repo, checkpoint-approved): 11 ghost global registrations removed from ~/.claude/settings.json; 6 consuming roots remediated (11/11 project-local registration, session-start.d synced)

## Test Status
make test: all 25 scripts pass. make eval: 52/52. Reviewer 9/10 ACCEPT (2 MEDIUM fixed inline, 2 deferred-with-rationale).

## Recent Commits
- fb6d189 Phase 83 — delivery accepted; flip delivery gate
- b4d9bfb Phase 83: Prune-on-Value Subtraction — debrief
- f6c7e8d Phase 83 review-gate fixes: 4 MEDIUM findings
- 82a69d8 Phase 83 self-check: sync audit-log file article
- 1e5f5cc Phase 83 T5: close-out — exit-criteria aggregator 10/10
(Phase 84 work is in the working tree, pending the delivery commit.)
