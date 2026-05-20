# Active Phase Context

Phase: 12 - Soul Enhancement & Memory Harvest
Status: Active, 0/6 tasks done, ~0%
Objective: Add relational warmth to soul via compression, integrate memory-harvest into debrief, close spec-existence and thinking-protocol gaps in dev-plan.

Scope: templates/.claude/rules/nana-soul.md, templates/.github/instructions/nana.instructions.md, ~/.claude/skills/dev-debrief/{memory-harvest.md,SKILL.md,executor-prompt.md}, ~/.claude/skills/dev-plan/SKILL.md, tests/test_templates.sh, docs/*
Key constraints: soul <=60 lines, budget <=300 lines, nana.instructions.md must byte-match soul minus frontmatter, memory-harvest uses memory_store only (no file intermediary)
Exit criteria: Voice & presence in soul, memory-harvest wired, spec-existence check + T0 in dev-plan, all tests pass, committed
Abort: if blocked >3 attempts on any task, ask user: skip or abort

Gates:
- [x] Spec reviewed (9/10)
- [x] Approach approved
- [x] Plan reviewed
- [x] Tasks approved
