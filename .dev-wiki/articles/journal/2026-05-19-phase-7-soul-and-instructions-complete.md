---
title: "Phase 7 complete -- Soul & Instructions Enhancement"
aliases: []
category: journal
tags: [soul, instructions, personal, protocols, testing, budget]
parents: [phase-07-soul-and-instructions-enhancement]
created: 2026-05-19
updated: 2026-05-19
source: debrief
---

# Phase 7 Complete -- Soul & Instructions Enhancement

## What Happened
- Completed all 5 Phase 7 tasks in a single session: cognitive protocols, personal extraction, AGENTS.md rename, sync, budget regression test
- Three-critic multi-angle review (context engineering, harness design, UX) produced unanimous convergence on soul vs AGENTS.md delineation
- nana-soul.md restructured: 2 new sections (Before acting, Memory discipline), 1 renamed (Code quality lens), 1 new bullet (surgical discipline), personal section extracted -- landed at 50 lines (target was <=60)
- New file: templates/.claude/rules/nana-personal.md (personal profile, installed globally by install.sh)
- install.sh updated to copy nana-personal.md alongside nana-soul.md (validates 3 source files)
- tests/test_templates.sh expanded from 6 to 14 assertions including instruction budget regression (191/300 lines)

## Decisions Made
- [[soul-vs-agents-delineation|Soul vs AGENTS.md delineation]] -- extracted this session

## Problems Solved
- Soul/AGENTS.md boundary ambiguity -- resolved via litmus test: "would this apply in a Rust project?" Yes = soul, No = AGENTS.md
- Personal data in shared template -- extracted to nana-personal.md (installed globally, not scaffolded per-project)

## Artifacts Changed
- `templates/.claude/rules/nana-soul.md` (restructured: 50 lines, 3 protocols)
- `templates/.claude/rules/nana-personal.md` (new: personal profile)
- `templates/AGENTS.md` (Verification -> Pre-commit sequence)
- `templates/.github/instructions/nana.instructions.md` (synced to soul)
- `install.sh` (now copies 4 files: skill + soul + personal + memory_server)
- `tests/test_templates.sh` (14 assertions, was 6; includes budget regression)
- `docs/report.html` (regenerated)
- `docs/workflow.html` (regenerated)

## Soft Observations / Phase N+1 Candidates
- Three-critic multi-angle review pattern highly effective for design decisions -- reusable for future architectural choices
- Instruction budget at 191/300 leaves 109 lines of headroom for future protocol additions
- Personal profile extraction pattern (nana-personal.md) separates user-specific from universal config -- reusable for multi-user kit distribution

### Activation Quality
- active-knowledge.md had 5 entries (Phase 7 key facts: delineation principle, protocol sources, budget math)
- Delineation principle and budget math were consumed during implementation; protocol sources guided soul content
- Hit rate: high -- all distilled facts were consumed during implementation

## Related
- [[phase-07-soul-and-instructions-enhancement|Phase 7: Soul & Instructions Enhancement]]
- [[soul-vs-agents-delineation|Soul vs AGENTS.md delineation]]
