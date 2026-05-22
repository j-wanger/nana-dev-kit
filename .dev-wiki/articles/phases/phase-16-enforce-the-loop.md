---
title: "Phase 16: Enforce the Loop"
status: completed
started: 2026-05-22
updated: 2026-05-22
ceremony: standard
scope:
  - templates/.claude/hooks/enforce-spec.sh
  - templates/.claude/hooks/enforce-loop.sh
  - templates/.claude/hooks/session-start.sh
  - install.sh
  - tests/test_enforce.sh
  - tests/test_install.sh
  - Makefile
exit_criteria:
  - enforce-spec.sh blocks implementation writes when no approved spec exists for active phase
  - enforce-loop.sh checks file-existence deliverables at Stop, advisory for open tasks and debrief
  - 10 enforcement test cases pass deterministically
  - install.sh distributes hooks to ~/.claude/hooks/ and creates .claude/enforce marker
  - session-start.sh reports enforcement status (active/inactive)
  - make test passes (all existing + new tests)
tags: [hooks, enforcement, lifecycle, distribution]
---

# Phase 16: Enforce the Loop

## Objective

Add deterministic enforcement hooks that prevent implementation without an approved spec (PreToolUse gate) and verify deliverable existence at session end (Stop check), distributed globally via install.sh with per-project opt-in.

## Background

Phases 11-15 built layered gate enforcement (preventive in implementation-guide.md, detective in dev-debrief). This phase adds automated enforcement: hooks that run on every tool use and session stop, catching spec-less implementation and missing deliverables without relying on agent compliance.

## Approach

Global install to ~/.claude/hooks/ with .claude/enforce marker for per-project opt-in. Two hooks: enforce-spec.sh (PreToolUse on Write/Edit, blocks without spec) and enforce-loop.sh (Stop, checks deliverable files). Python JSON parsing consistent with existing hooks. Path allowlist for meta/test/md files.

## Key Decisions

- [[global-hooks-project-opt-in]] — hooks install globally, check CWD for .claude/enforce marker
- [[lightweight-deliverable-check-stop]] — Stop hook runs file-existence checks only, advisory for open tasks
- [[python-json-parsing-hooks]] — inline python3 for JSON stdin parsing, consistent with existing hooks

## Constraints

- Hooks must exit within 100ms (Python JSON parse ~20ms)
- Fail-open: absent .claude/enforce marker = exit 0 immediately
- No blocking on advisory signals (open tasks, missing debrief)
- Block only on: missing spec for implementation writes, missing deliverable files
- Path allowlist: .dev-wiki/, .claude/, wiki/, specs/, tests/, templates/, *_test.*, test_*.*, *_spec.*, *.md
- install.sh idempotent (run twice = same result)

## Assumptions

- Claude Code hook JSON schema remains stable (tool_name + input.file_path for PreToolUse). If false: adapt parsing to new schema.
- python3 available in PATH (guaranteed by install.sh prereq). If false: fall back to jq or pure bash.

## Results

All 6 tasks completed. 15 new tests (10 enforce + 5 install, total 107). Decision confidence upgraded medium -> high for all 3 decisions. Enforcement hooks distributed globally via install.sh with per-project opt-in marker.

## Formal Spec

specs/phase-16-enforce-the-loop.md (approved).
