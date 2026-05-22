---
title: "Phase 14: Adversarial Thinking & Review"
aliases: []
category: phases
tags: [adversarial, thinking-protocol, spec, constraint-generation]
parents: []
created: 2026-05-21
updated: 2026-05-21
source: plan
status: completed
scope: ["~/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/spec/*", "install.sh", "tests/*"]
entry_criteria: "Phase 13 complete, v0.3.0 shipped"
exit_criteria: "T0 forces named assumptions, spec has adversarial Step 2.5, companion file exists, install.sh copies it, make test passes"
---

# Phase 14: Adversarial Thinking & Review

## Objective

Make T0 thinking protocol and spec constraint generation genuinely adversarial, eliminating confirmed performative rubber-stamping.

## Scope

Files and modules affected:
- `~/.claude/skills/dev-plan/SKILL.md` (T0 wording rewrite)
- `templates/.claude/skills/spec/SKILL.md` (Step 2.5 insertion)
- `templates/.claude/skills/spec/adversarial-constraints-prompt.md` (new companion)
- `install.sh` (copy adversarial companion)
- `tests/test_install.sh` (install assertions)
- `tests/test_templates.sh` (template assertions)

## Exit Criteria

- [x] T0 in dev-plan Step 6 requires named weakest assumption + what breaks
- [x] Spec has adversarial Step 2.5 with clean-context subagent
- [x] adversarial-constraints-prompt.md exists (41 lines)
- [x] install.sh copies adversarial-constraints-prompt.md
- [x] make test passes (67 tests), soul <=60 lines (59)

## Constraints

- Soul frozen at 59/60 — no soul modifications: prevents line-budget violation
- Spec SKILL.md must stay ≤350 lines: prevents complexity creep in orchestration skills
- Adversarial subagent gets only objective+context: prevents shared-prior confirmation bias

## Assumptions

- T0 wording change fits within dev-plan SKILL.md without soul modification. If false: defer to Phase 15.
- Clean-context subagent can be expressed in ~40-50 line companion prompt. If false: compress or split.

## Notes

- Two decisions: T0 wording over structural subagent (cheap, testable), adversarial constraint generation as spec Step 2.5 (upstream from review)
- Wiki knowledge: AgentCoder 3-agent separation, falsifiability gap at authoring stage, tautological TDD risk
- Knowledge gaps: clean-context subagent design patterns, forcing function prompt engineering specifics
