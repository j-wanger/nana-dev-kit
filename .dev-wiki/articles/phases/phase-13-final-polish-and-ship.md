---
title: "Phase 13: Final Polish & Ship"
aliases: [phase-13, final-polish, v0.3.0]
category: phases
tags: [polish, shipping, soul, install, versioning]
parents: []
created: 2026-05-20
updated: 2026-05-20
source: plan
status: completed
scope: ["templates/.claude/rules/nana-soul.md", "templates/.claude/rules/nana-personal.md", "templates/.github/instructions/nana.instructions.md", "install.sh", "VERSION", "docs/*", "tests/*"]
entry_criteria: "Phase 12 complete"
exit_criteria: "Soul 59/60 with H8+H9, personal profile templated, SKILL.md ceiling 350, v0.3.0 tagged and pushed, 63+ tests pass"
---

# Phase 13: Final Polish & Ship

## Objective

Apply 3 reviewer-recommended changes (thinking heuristics H8+H9, personal profile template for shipping, SKILL.md ceiling raise) and ship v0.3.0 as the first release ready for corporate project testing.

## Scope

Files and modules affected:
- `templates/.claude/rules/nana-soul.md` — add H8+H9 to Thinking protocol (+2 lines, 57->59/60)
- `templates/.github/instructions/nana.instructions.md` — sync to soul
- `templates/.claude/rules/nana-personal.md` — replace with generic template
- `install.sh` — conditional personal profile copy
- `~/.claude/skills/dev-plan/self-check-checklist.md` — ceiling 250->350
- `VERSION` — bump to 0.3.0
- `docs/report.html`, `docs/workflow.html` — regenerate
- `tests/*` — verify all pass

## Formal Spec

See `specs/phase-13-final-polish-and-ship.md` (reviewed 8/10, revised to accept).

## Exit Criteria

- [x] Soul has H8 (informed search) and H9 (lateral scope expansion), exactly 59 lines
- [x] nana.instructions.md byte-matches soul minus 4-line YAML frontmatter
- [x] Personal profile template has no Jake-specific content
- [x] install.sh conditionally copies personal profile (skip if existing)
- [x] SKILL.md complex-orchestration ceiling is 350
- [x] VERSION is 0.3.0
- [x] 65 tests pass (63+ requirement met)
- [x] v0.3.0 tag exists, pushed to origin

## Constraints

- Soul must stay <=60 lines (currently 57, adding 2 -> 59): prevents instruction-following degradation
- Instruction budget must stay <=300 lines (currently 239, +2 soul -> ~245): prevents context bloat
- H8 and H9 wording is verbatim from spec: prevents meaning drift from calibrated review text
- Personal template must pass Rust litmus test inverse: prevents shipping universal content as personal

## Checkpoints

- After soul edit: verify line count is exactly 59. If 60+: STOP (miscount).
- After personal profile edit: verify no Jake-specific content in template.

## Assumptions

- nana.instructions.md frontmatter is exactly 4 lines. If changed: update tail offset.
- self-check-checklist.md contains "250" for complex orchestration ceiling. If wording differs: adapt.

## Notes

External review assessed kit as "ready for corporate project test" with these 3 items. This is a polish-and-ship phase, not a feature phase. Two decisions made: personal-profile-template-for-shipping (high confidence), skill-ceiling-250-to-350 (high confidence).
