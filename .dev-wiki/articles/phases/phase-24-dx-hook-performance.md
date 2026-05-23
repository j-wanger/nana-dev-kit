---
title: "Phase 24: DX + Hook Performance"
aliases: [phase-24-dx-hook-performance]
category: phases
tags: [hooks, jq, performance, dx, install, readme]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: READY FOR COMPLETION
scope: ["templates/.claude/hooks/*.sh", "install.sh", "README.md", "tests/test_templates.sh"]
entry_criteria: "Phase 23 complete, 142 tests passing, 38/38 eval, v0.4.0 shipped"
exit_criteria: "No python3 -c in 6 migrated hooks, jq guards present, Getting Started in install.sh, Requirements in README, make test + make eval 100%"
---

# Phase 24: DX + Hook Performance

## Objective

Reduce hook latency by migrating 6 hooks from python3 -c to jq for JSON parsing. Improve first-run DX with Getting Started output from install.sh and a Requirements section in README.

## Scope

Files and modules affected:
- `templates/.claude/hooks/audit-log.sh` -- python3 -c to jq, add jq guard
- `templates/.claude/hooks/auto-ruff-format.sh` -- python3 -c to jq
- `templates/.claude/hooks/block-dangerous-bash.sh` -- python3 -c to jq, add jq guard
- `templates/.claude/hooks/scan-secrets.sh` -- python3 -c to jq
- `templates/.claude/hooks/enforce-spec.sh` -- python3 -c to jq
- `templates/.claude/hooks/check-tests-were-run.sh` -- python3 -c to jq
- `install.sh` -- Getting Started 3-path output
- `README.md` -- Requirements section before Quick Start
- `tests/test_templates.sh` -- jq assertions

Excluded: detect-loop.sh (pure bash, performance budget), wk-prune.sh (no JSON), session-start.sh (no python3 -c), enforce-loop.sh (no python3 -c), pre-compact.sh (no python3 -c).

## Approach

1. Migrate all 6 hooks in one task: add jq fail-open guard to audit-log + block-dangerous-bash, then replace each python3 -c invocation with equivalent jq -r expression.
2. Add Getting Started output to install.sh (3-path guide: /dev-init, /py-init, /wiki-init).
3. Add Requirements section to README before Quick Start.
4. Update test assertions and verify full suite.

## Exit Criteria

- [ ] `! grep -r 'python3 -c' templates/.claude/hooks/{audit-log,auto-ruff-format,block-dangerous-bash,scan-secrets,enforce-spec,check-tests-were-run}.sh`
- [ ] `grep -q 'command -v jq' templates/.claude/hooks/audit-log.sh`
- [ ] `grep -q 'command -v jq' templates/.claude/hooks/block-dangerous-bash.sh`
- [ ] `bash install.sh --dry-run 2>&1 | grep -qi 'dev-init'` (Getting Started output visible)
- [ ] `grep -qi 'requirements' README.md && grep -qi 'jq' README.md`
- [ ] `make test && make eval 2>&1 | grep -qE 'Score.*100'`

## Formal Spec

See `specs/phase-24-dx-hook-performance.md` (approved).

## Notes

1 decision made during planning: jq-hook-migration (replace python3 -c with jq in 6 hooks, fail-open guard, detect-loop.sh excluded).
