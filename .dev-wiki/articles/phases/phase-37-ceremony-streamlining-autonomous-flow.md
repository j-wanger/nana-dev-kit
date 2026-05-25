---
title: "Phase 37: Ceremony Streamlining & Autonomous Flow"
aliases: [phase-37, ceremony-streamlining]
category: phases
tags: [ceremony, gates, autonomous-flow, dev-plan, spec, dev-debrief, delivery-report]
parents: []
created: 2026-05-25
updated: 2026-05-25
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/dev-plan/plan-review-companion.md", "templates/.claude/skills/dev-plan/implementation-guide.md", "templates/.claude/skills/dev-plan/task-schema.md", "templates/.claude/skills/spec/SKILL.md", "templates/.claude/skills/dev-debrief/SKILL.md", "templates/.claude/skills/dev-debrief/delivery-flow.md", "scripts/generate-delivery-report.py", ".claude/rules/dev-wiki-hooks.md", "templates/.claude/skills/MANIFEST", "tests/test_templates.sh", "tests/test_install.sh"]
entry_criteria: "Phase 36 complete, 240 tests, 47/47 eval, approach approved by user"
exit_criteria: "10 machine-checkable items (see below)"
---

# Phase 37: Ceremony Streamlining & Autonomous Flow

## Objective

Shift from 4 synchronous human approval gates (spec, approach, plan, tasks) to 2 boundary gates (direction + delivery). Agent operates autonomously between gates with automated quality checks.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/SKILL.md` — ceremony rewrite, agent-internal flow
- `templates/.claude/skills/dev-plan/plan-review-companion.md` — extracted Steps 7.5/7.6
- `templates/.claude/skills/dev-plan/implementation-guide.md` — 2-gate pre-flight
- `templates/.claude/skills/dev-plan/task-schema.md` — gate log format update
- `templates/.claude/skills/spec/SKILL.md` — --internal mode
- `templates/.claude/skills/dev-debrief/SKILL.md` — delivery report + auto-commit/push
- `templates/.claude/skills/dev-debrief/delivery-flow.md` — companion if needed
- `scripts/generate-delivery-report.py` — HTML report generator
- `.claude/rules/dev-wiki-hooks.md` — 2-gate references
- `templates/.claude/skills/MANIFEST` — regenerated
- `tests/test_templates.sh`, `tests/test_install.sh` — new assertions

## Exit Criteria

- [x] dev-plan SKILL.md has agent-internal flow, no Step 7.6, 2-gate template, ≤350 lines
- [x] plan-review-companion.md exists, referenced from SKILL.md
- [x] spec SKILL.md has --internal mode, ≤160 lines
- [x] generate-delivery-report.py exists and runs with --help
- [x] dev-debrief SKILL.md has delivery report + auto-commit/push, ≤350 lines
- [x] implementation-guide.md has 2-gate pre-flight (no 5-gate references)
- [x] dev-wiki-hooks.md updated for 2-gate ceremony
- [x] MANIFEST regenerated
- [x] make test passes (259 tests)
- [x] make eval 100% (47/47)

## Constraints

- SKILL.md ceiling 350 lines for complex-orchestration skills
- spec-always-mandatory: spec still runs, just agent-internal (not removed)
- Delivery report generated BEFORE commit (user accepted this timing)
- Auto-push only after user acceptance of delivery report
- No changes to hook scripts themselves (enforce-spec.sh, enforce-loop.sh still work)

## Assumptions

- enforce-spec.sh checks spec file existence, not approval status. If false: update hook to accept internal specs.
- enforce-loop.sh exit criteria checks are compatible with 2-gate model. If false: adjust hook behavior.
