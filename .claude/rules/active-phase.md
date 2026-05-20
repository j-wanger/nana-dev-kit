# Active Phase Context

Phase: 13 - Final Polish & Ship
Status: Active, 0/5 tasks done, 0%
Objective: Apply 3 reviewer-recommended changes (soul H8+H9, personal profile template, SKILL.md ceiling) and ship v0.3.0.

Scope: templates/.claude/rules/nana-soul.md, templates/.claude/rules/nana-personal.md, templates/.github/instructions/nana.instructions.md, install.sh, ~/.claude/skills/dev-plan/self-check-checklist.md, VERSION, docs/*, tests/*

Key constraints:
- Soul must stay <=60 lines (57+2=59 target)
- Instruction budget <=300 lines (~245 after changes)
- H8+H9 wording verbatim from spec
- Personal template: no Jake-specific content

Exit: Soul 59/60 with H8+H9, personal templated, ceiling 350, v0.3.0 tagged+pushed, 63+ tests pass
Abort: if blocked >3 attempts on any task, ask user: skip or abort

Gates: [x] spec [x] approach [x] plan-review [x] tasks
