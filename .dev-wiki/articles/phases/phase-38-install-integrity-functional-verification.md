---
title: "Phase 38: Install Integrity & Functional Verification"
aliases: []
category: phases
tags: [install, testing, hooks, integrity]
parents: []
created: 2026-05-25
updated: 2026-05-25
source: plan
status: completed
scope: ["install.sh", "templates/.claude/hooks/dev-wiki-scope-check.sh", "templates/.claude/skills/MANIFEST", "tests/test_install.sh", "eval/corpus/*", ".dev-wiki/_ARCHITECTURE.md"]
entry_criteria: "Phase 37 complete, spec approved"
exit_criteria: "All 7 machine-checkable exit criteria from spec pass"
---

# Phase 38: Install Integrity & Functional Verification

## Objective

Fix known install gaps (5 missing skills, wrong hook matchers, broken JSON field parsing) and add post-install functional verification so structural-only tests never hide a broken artifact again.

## Scope

Files and modules affected:
- `install.sh` — skill lists, matcher patterns, JSON merge
- `templates/.claude/hooks/dev-wiki-scope-check.sh` — field path fix
- `templates/.claude/skills/MANIFEST` — regeneration
- `tests/test_install.sh` — functional verification tests
- `eval/corpus/` — scenario updates if needed
- `.dev-wiki/_ARCHITECTURE.md` — known issues documentation

## Exit Criteria

- [x] 5 missing skills installed (nana, memory-consolidate, py-lint, py-review, py-test)
- [x] No Write|Edit-only matchers remain (all include MultiEdit)
- [x] dev-wiki-scope-check.sh uses .input.file_path (not .tool_input)
- [x] make test passes
- [x] make eval 100%
- [x] MANIFEST includes new skills
- [x] PostToolUse field path inconsistency documented in _ARCHITECTURE.md

## Constraints

- MultiEdit must be added to ALL 7 hook registrations. Prevents: divergence where some hooks fire on MultiEdit and others don't.
- Skill module assignment: nana/memory-consolidate to core; py-lint/py-review/py-test to python. Prevents: over-install breaking module isolation.
- Functional tests must run in HOME=$(mktemp -d) isolation. Prevents: tests depending on developer state.
- No new hard Python dependency in make test. Prevents: breaking CI for bash-only environments.

## Checkpoints

- After fixing all 3 bugs: run make test + make eval to verify no regressions
- After adding functional tests: run full suite

## Assumptions

- PreToolUse stdin uses .input.file_path for Write/Edit. If false: check Claude Code docs.
- The 5 missing skills have no dependencies beyond companion .md files. If false: add dependency validation.
- MultiEdit fires hooks with same matcher syntax as Write|Edit. If false: adding to matchers is harmless (no-op).

## Notes

Post-phase-37 audit discovered MCP memory server had been non-functional since Phase 4 (33 phases) due to bad CWD path. Root cause: structural-only testing. This phase ensures functional verification catches similar gaps.
