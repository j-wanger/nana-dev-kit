---
title: "Phase 11: Process Hardening"
aliases: []
category: phases
tags: [process, discipline, guardrails, gates, enforcement, retro]
parents: []
created: 2026-05-19
updated: 2026-05-19
source: plan
status: active
scope: ["~/.claude/skills/dev-plan/implementation-guide.md", "~/.claude/skills/dev-debrief/SKILL.md", "templates/.claude/hooks/session-start.sh", "tests/test_templates.sh", "docs/*"]
entry_criteria: "Phase 10 complete"
exit_criteria: "Pre-flight gate verification added, detective audit added, session-start reminder added, regression tests pass, committed"
---

# Phase 11: Process Hardening

## Objective

Add structural enforcement for process gates that were previously documentation-only. Preventive layer (pre-flight refusal) + detective layer (audit in debrief) + template-level reminder (session-start) + regression tests.

## Scope

Files and modules affected:
- `~/.claude/skills/dev-plan/implementation-guide.md` (pre-flight gate verification)
- `~/.claude/skills/dev-debrief/SKILL.md` (gate-compliance audit)
- `templates/.claude/hooks/session-start.sh` (gate-check reminder)
- `tests/test_templates.sh` (regression + budget assertion)
- `docs/report.html`, `docs/workflow.html` (regeneration)

## Exit Criteria

- [ ] Pre-flight gate verification section in implementation-guide.md
- [ ] Gate-compliance audit in dev-debrief retro-check
- [ ] Session-start gate-check reminder emits warning
- [ ] Regression tests pass (gate-check + budget ≤300)
- [ ] Committed and pushed

## Constraints

- Instruction budget must stay ≤300 lines (current: 229/300): prevents over-specification bloat
- Gate enforcement is instructional (agent-compliance), not shell-blocking: prevents false sense of deterministic enforcement
- No new files in templates/.claude/rules/ (budget pressure): prevents scope creep

## Assumptions

- implementation-guide.md and dev-debrief SKILL.md are editable at skill paths. If paths change: update scope globs.
- active-phase.md Gates section format is stable (checkbox list). If format changes: update parsing logic.

## Notes

Motivated by Phase 10 retro check: 3 user corrections across 10 phases (all process discipline, zero technical failures). Pattern: violations cluster during execution momentum (5 phases in one session). Session-length awareness deferred to future phase.
