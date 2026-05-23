---
title: "Phase 23: Bug Fixes + README Rewrite"
aliases: [phase-23-bug-fixes-readme]
category: phases
tags: [bugs, readme, hooks, install]
parents: []
created: 2026-05-22
updated: 2026-05-22
source: plan
status: active
scope: ["templates/.claude/settings.json", "install.sh", "templates/.claude/skills/dev-debrief/memory-harvest.md", "README.md", "tests/test_install.sh", "tests/test_templates.sh"]
entry_criteria: "Phase 22 complete, 133 tests passing, 38/38 eval, v0.4.0 shipped"
exit_criteria: "PreCompact registered in settings.json + install.sh, memory-harvest.md aligned with memory-bridge.md API, README rewritten (90-100 lines, 7 sections), all tests + eval pass"
---

# Phase 23: Bug Fixes + README Rewrite

## Objective

Fix two orphaned artifacts (pre-compact.sh hook registration, memory-harvest.md API mismatches) and rewrite README.md for v0.4.0 to reflect the tool's current capabilities (22 skills, enforcement hooks, eval harness, memory bridge).

## Scope

Files and modules affected:
- `templates/.claude/settings.json` -- add PreCompact hook registration
- `install.sh` -- add pre-compact.sh to dev-wiki module copy + JSON merge
- `templates/.claude/skills/dev-debrief/memory-harvest.md` -- align with memory-bridge.md API
- `README.md` -- full rewrite (90-100 lines, 7 sections)
- `tests/test_install.sh` -- PreCompact assertions
- `tests/test_templates.sh` -- memory-harvest + README assertions

## Approach

1. Register pre-compact.sh in settings.json (Task 1, low risk)
2. Add to install.sh dev-wiki module with idempotency (Task 2)
3. Fix memory-harvest.md API shape to match memory-bridge.md (Task 3)
4. Rewrite README with 7 sections covering full tool surface (Task 4)
5. Update tests + commit (Tasks 5-6)

## Exit Criteria

- [ ] `jq -e '.hooks.PreCompact' templates/.claude/settings.json`
- [ ] `bash install.sh --dry-run 2>&1 | grep -q 'pre-compact'`
- [ ] `! grep -q 'category.*lesson' templates/.claude/skills/dev-debrief/memory-harvest.md`
- [ ] `grep -qi 'enforcement' README.md && [ $(wc -l < README.md) -ge 70 ]`
- [ ] `make test && make eval 2>&1 | grep -qE 'Score.*100'`

## Constraints

- pre-compact.sh goes in dev-wiki module group, NOT core (depends on .dev-wiki/ files)
- No new eval scenarios needed (hook-pre-compact-active-phase already exists)
- memory-harvest.md must use category="custom" with tags (not category="lesson"/"constraint")

## Formal Spec

See `specs/phase-23-bug-fixes-readme.md` (approved 8/10).

## Notes

- 2 decisions: pre-compact-dev-wiki-module (new), readme-budget-superseded (supersedes readme-concise-format)
- No knowledge gaps identified
