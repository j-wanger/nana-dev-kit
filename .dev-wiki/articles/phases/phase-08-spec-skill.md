---
title: "Phase 8: Spec Skill"
aliases: []
category: phases
tags: [spec, contract, review-gate, portable, thinking-protocol]
parents: []
created: 2026-05-19
updated: 2026-05-19
source: plan
status: completed
scope: ["templates/.claude/skills/spec/SKILL.md", "templates/.claude/skills/spec/spec-reviewer-prompt.md", "install.sh", "tests/test_install.sh", "tests/test_templates.sh", "README.md"]
entry_criteria: "Phase 7 complete, all templates functional"
exit_criteria: "Spec skill with two-tier review gate, phase template backported, installed, tested, README updated"
---

# Phase 8: Spec Skill

## Objective

Create a portable /spec skill for structured contract creation with a two-tier review gate (structural lint + semantic subagent review). Backport spec sections into dev-wiki phase template.

## Formal Spec

See `specs/phase-08-spec-skill.md` for the full contract (Opus-reviewed, 8/10).

## Tasks (4 total: 2M + 2S)

1. **[M]** Create SKILL.md + spec-reviewer-prompt.md (two-tier review gate)
2. **[M]** Backport Constraints/Checkpoints/Assumptions into phase template + dev-plan Step 6
3. **[S]** Update install.sh + tests
4. **[S]** Update README with /spec mention
