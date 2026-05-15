---
title: "templates/.claude/skills/"
aliases: []
category: modules
tags: [markdown, skills, python]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: scan
type: module
path: "templates/.claude/skills/"
files: [templates-claude-skills-py-init-skill, templates-claude-skills-py-init-scanner, templates-claude-skills-py-init-transform, templates-claude-skills-py-lint-skill, templates-claude-skills-py-review-skill, templates-claude-skills-py-test-skill]
external_deps: [uv, ruff, mypy, pytest]
internal_deps: []
dependents: []
content_hash: "3bf564bf205e6296"
---

# templates/.claude/skills/

Claude Code skill definitions providing four slash commands: /py-init (scaffold/retrofit Python projects), /py-lint (lint+format+typecheck), /py-review (8-point PR checklist), and /py-test (test suite runner).

## Files

- [[templates-claude-skills-py-init-skill|py-init/SKILL.md]] — Scaffold/retrofit skill entry point with frontmatter
- [[templates-claude-skills-py-init-scanner|py-init/scanner.md]] — Companion: scans existing project structure
- [[templates-claude-skills-py-init-transform|py-init/transform.md]] — Companion: transforms/scaffolds project files
- [[templates-claude-skills-py-lint-skill|py-lint/SKILL.md]] — Lint, format, and typecheck skill
- [[templates-claude-skills-py-review-skill|py-review/SKILL.md]] — 8-point PR review checklist skill
- [[templates-claude-skills-py-test-skill|py-test/SKILL.md]] — Test suite runner with coverage reporting

## Key Patterns

- Each skill has a SKILL.md with frontmatter (name, description)
- py-init is multi-file (scanner + transform companions); others are single-file
- Markdown-driven skills (no executable code; instructions only)

## Dependencies

**Internal:** None (templates reference scaffolding files at deploy time)

**External:** uv (package management), ruff (linting/formatting), mypy (type checking), pytest (testing)

## Dependents

- install.sh copies py-init/SKILL.md to ~/.claude/skills/
