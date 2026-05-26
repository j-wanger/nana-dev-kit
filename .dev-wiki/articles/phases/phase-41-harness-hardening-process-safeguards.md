---
title: "Phase 41: Harness Hardening & Process Safeguards"
aliases: [harness-hardening, process-safeguards]
category: phases
tags: [hardening, process, safeguards, anti-pattern, jq, companion, debrief, cooldown]
parents: []
created: 2026-05-25
updated: 2026-05-25
source: plan
status: completed
scope: ["install.sh", "templates/.claude/hooks/session-start.sh", "templates/.claude/skills/dev-debrief/*", "templates/.claude/skills/**/*.md", "tests/*"]
entry_criteria: "Phase 40 completed (7/7 tasks, all exit criteria verified)"
exit_criteria: "jq guard, session timestamp, companion metadata (~92 files), bidirectional test, debrief enhancements, cooldown advisory, make test + make eval 100%"
ceremony: standard
---

## Objective

Resolve remaining anti-patterns (#3 momentum risk, #5 companion proliferation) with six targeted fixes: jq install guard, session-aware phase-cooldown advisory, bidirectional companion metadata validation, debrief duration tracking, and required soft observations.

## Scope

- `install.sh` — jq fail-stop guard
- `templates/.claude/hooks/session-start.sh` — session timestamp
- `templates/.claude/skills/dev-debrief/SKILL.md` — soft observations required, cooldown advisory
- `templates/.claude/skills/dev-debrief/executor-prompt.md` — duration estimation
- `templates/.claude/skills/**/*.md` — companion metadata frontmatter (~92 files)
- `tests/test_companions.sh` — new bidirectional validation test
- `Makefile` — wire new test

## Exit Criteria

1. jq guard in install.sh (fail-stop with multi-platform hint)
2. Session timestamp written by session-start.sh
3. Companion metadata on >=90% of companion files
4. test_companions.sh passing (Direction A + Direction B)
5. Debrief soft observations required + duration estimation
6. Cooldown advisory fires at >=2 phase commits
7. make test && make eval 100%

## Approach

Six surgical fixes, each independently testable. Order: jq guard (zero risk), session timestamp (1 line), companion metadata (largest surface area), bidirectional validation test, debrief enhancements (template changes), cooldown advisory (uses session timestamp). Companion metadata uses scripted batch approach.

Key decisions: [[companion-metadata-format]], [[cooldown-advisory-placement]], [[jq-guard-fail-stop]]

## Formal Spec

See `specs/phase-41-harness-hardening-process-safeguards.md`

## Constraints

- Companion frontmatter must not break cp -r distribution
- Forward-only: no retroactive validation of historical entries
- Cooldown advisory is advisory only (exit 0, never blocks)
- Soft Observations "none identified" is valid content
