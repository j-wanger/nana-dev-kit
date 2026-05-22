---
title: "Phase 15: Wire the Lifecycle"
status: completed
started: 2026-05-21
completed: 2026-05-22
updated: 2026-05-22
ceremony: standard
scope:
  - templates/.claude/skills/dev-*/**
  - templates/.claude/skills/wiki-*/**
  - templates/.claude/skills/knowledge-wiki/**
  - templates/.claude/skills/MANIFEST
  - templates/.claude/hooks/pre-compact.sh
  - templates/.claude/hooks/session-start.sh
  - install.sh
  - tests/test_install.sh
  - tests/test_templates.sh
exit_criteria:
  - All 17 skill dirs imported with correct file counts
  - install.sh supports --all/--core-only/--no-python/--dry-run
  - Module dependency validation exits non-zero on missing prereqs
  - PreCompact hook produces structured output from committed state
  - session-start.sh outputs memory_search guidance
  - make test passes
tags: [integration, installer, hooks, monorepo]
---

# Phase 15: Wire the Lifecycle

## Objective

Make nana-dev-kit a complete one-command install of all three subsystems (Python scaffolding, dev-wiki lifecycle, knowledge-wiki pipeline) with modular opt-out, and add compaction resilience.

## Background

Closes Gaps 1.1 (dev-wiki skills not installed), 1.2 (knowledge-wiki skills not installed), 1.4 (session state disconnected from memory), and 1.5 (no PreCompact hook) from the engineering gap analysis.

## Approach

Module-by-module import from ~/.claude/skills/ (confirmed canonical), install.sh refactored to module-group pattern with flags + dependency validation, PreCompact hook as pure shell, session-start enhanced with memory_search topic guidance.

## Key Decisions

- [[monorepo-skill-distribution]] — single repo with modular install flags
- [[import-source-canonical-installed]] — import from installed versions, not source repos

## Constraints

- install.sh idempotent
- PreCompact hook pure POSIX shell + git (no Python, no MCP)
- No SKILL.md content modifications (verbatim import)
- install.sh --all <10s
- Module dependency graph: core → {python, dev-wiki, knowledge-wiki}

## Formal Spec

See `specs/phase-15-wire-the-lifecycle.md`
