---
title: "Phase 9: File Lifecycle Reference"
aliases: []
category: phases
tags: [lifecycle, routing, orphan-cleanup, rules]
parents: []
created: 2026-05-19
updated: 2026-05-19
source: plan
status: completed
scope: ["templates/.claude/rules/file-lifecycle.md", "templates/.claude/hooks/session-start.sh", "templates/.claude/skills/spec/SKILL.md", "install.sh", "tests/test_install.sh", "tests/test_templates.sh"]
entry_criteria: "Phase 8 complete"
exit_criteria: "File lifecycle routing table created, PROJECT_STATE.md orphan removed, installed, tested -- ALL MET"
---

# Phase 9: File Lifecycle Reference

## Objective

Create a file lifecycle routing table and remove the orphaned PROJECT_STATE.md reference.

## Formal Spec

See `specs/phase-09-file-lifecycle-reference.md` (Opus-reviewed 9/10).

## Tasks (3 total: 1M + 2S)

1. **[M]** Create file-lifecycle.md + remove PROJECT_STATE.md orphan + update install.sh
2. **[S]** Update tests (install + templates + budget)
3. **[S]** Commit + push
