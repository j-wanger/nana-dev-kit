---
title: "Phase 40: install.sh Extraction & Anti-Pattern Hardening"
aliases: [install-extraction, anti-pattern-hardening]
category: phases
tags: [install, extraction, refactoring, prevention, hooks, cleanup]
status: completed
created: 2026-05-25
updated: 2026-05-25
ceremony: standard
---

## Objective

Decompose install.sh (542 lines, #1 source of silent regressions) into declarative manifest + extracted Python registration script. Fix residual Phase 39 PostToolUse normalization gap. Codify anti-pattern prevention rules. Clean up stale phase articles.

## Scope

- `install.sh`, `scripts/register-settings.py` (new), `modules.json` (new)
- `templates/.claude/hooks/stale-queue.sh`, `templates/.claude/hooks/post-commit.sh`
- `.dev-wiki/articles/phases/` (housekeeping)
- `README.md`, `templates/.claude/skills/spec/SKILL.md`
- `tests/`, `eval/`

## Entry Criteria

- Phase 39 completed (6/6 tasks, all exit criteria met)

## Exit Criteria

1. install.sh < 320 lines, zero inline Python
2. modules.json defines all 5 module groups
3. register-settings.py passes independent tests
4. stale-queue.sh + post-commit.sh have dual-field fallback
5. No duplicate phase articles; Phase 24 status fixed
6. make test && make eval 100%
7. Spec/dev-plan reference functional smoke invariant

## Approach

Extract the ~137 lines of inline Python from install.sh into `scripts/register-settings.py`. Create `modules.json` as single source of truth for skill lists and hook registrations. install.sh reads modules.json via jq, calls register-settings.py for all JSON merges.

Key decisions: [[install-sh-extraction-approach]], [[functional-smoke-invariant-rule]]

## Formal Spec

See `specs/phase-40-install-extraction-anti-pattern-hardening.md`

## Constraints

- install.sh must remain idempotent
- modules.json parseable by both jq and Python
- No regressions in existing test suite

## Checkpoints

- After modules.json + register-settings.py: verify standalone operation
- After install.sh refactor: run full existing test suite
- After all tasks: make test && make eval 100%
