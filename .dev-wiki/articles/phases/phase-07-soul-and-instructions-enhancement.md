---
title: "Phase 7: Soul & Instructions Enhancement"
aliases: []
category: phases
tags: [soul, identity, thinking, memory, instructions, protocols]
parents: []
created: 2026-05-19
updated: 2026-05-19
source: plan
status: completed
scope: ["templates/.claude/rules/nana-soul.md", "templates/.claude/rules/nana-personal.md", "templates/AGENTS.md", "templates/.github/instructions/nana.instructions.md", "install.sh", "tests/test_install.sh", "tests/test_templates.sh"]
entry_criteria: "Phase 6 complete, all templates functional"
exit_criteria: "Soul has Before acting + Memory discipline sections, personal profile extracted, AGENTS.md renamed, all synced, budget test passing"
---

# Phase 7: Soul & Instructions Enhancement

## Objective

Strengthen nana-soul.md with proceduralized thinking, memory discipline, and surgical discipline protocols. Sharpen the delineation between soul (cognitive identity) and AGENTS.md (operational contract). Extract personal data from shared template.

## Delineation Principle

Three-critic multi-angle review (context engineering, harness design, UX) produced unanimous convergence:

- **nana-soul.md** = cognitive identity. "How does this agent think and communicate?" Applies to all projects, all languages.
- **AGENTS.md** = operational contract. "What does this project require to be correct?" Project-specific toolchain and conventions.

Test: "Would this rule apply in a Rust project with no Python?" If yes → soul. If no → AGENTS.md.

## Approach

1. Add "Before acting" section (~6 lines) and "Memory discipline" section (~6 lines) to soul
2. Add surgical discipline as one bullet in "Work habits"
3. Rename "Review posture" → "Code quality lens" (soul), "Verification" → "Pre-commit sequence" (AGENTS.md)
4. Extract "Who you're working with" to nana-personal.md (installed by install.sh, not scaffolded per-project)
5. Sync nana.instructions.md, add regression tests

## Tasks (5 total: 2M + 3S)

1. **[M]** Add cognitive protocols to nana-soul.md
2. **[M]** Extract personal profile, install via install.sh
3. **[S]** Rename Verification → Pre-commit sequence in AGENTS.md
4. **[S]** Sync nana.instructions.md
5. **[S]** Protocol assertions + budget regression test

## Exit Criteria

- [x] nana-soul.md has "Before acting" and "Memory discipline" sections
- [x] Surgical discipline bullet in "Work habits"
- [x] "Review posture" renamed to "Code quality lens"
- [x] "Who you're working with" extracted to nana-personal.md
- [x] "Verification" renamed to "Pre-commit sequence" in AGENTS.md
- [x] nana.instructions.md mirrors soul
- [x] Total always-loaded lines ≤ 300 (191/300)
- [x] All tests pass (48/48)
