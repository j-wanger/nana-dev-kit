---
title: "Phase 55: Harness Activation Overhaul"
status: completed
created: 2026-05-28
updated: 2026-05-28
objective: Fix cascade failure that disabled the cognitive layer, add registration safeguards, reform spec template from prescriptive to reasoning-oriented, wire cognitive readiness diagnostic
ceremony: standard
scope:
  - install.sh
  - modules.json
  - templates/.claude/skills/spec/SKILL.md
  - templates/.claude/skills/spec/spec-reviewer-prompt.md
  - templates/.claude/hooks/session-start.sh
  - templates/.claude/hooks/session-start.d/
  - templates/.claude/skills/dev-plan/SKILL.md
  - tests/test_registration.sh
  - tests/
  - Makefile
exit_criteria:
  - nana-init installs correctly in temp HOME
  - py-review-stop-prompt.md registered in modules.json
  - Bidirectional registration test passes
  - Spec template has Success Vision + Domain Research Questions sections
  - Session-start emits cognitive readiness diagnostic
  - Dev-plan handles empty wiki with /wiki-bootstrap guidance
  - make test + make eval 100%
---

# Phase 55: Harness Activation Overhaul

## Motivation

Real-world effectiveness test (5 stock screener implementations) revealed the harness scored 7.5/10 — highest composite quality but only +0.25 over bare Claude Code. Root cause: cascade failure from nana-init installation gap disabled the entire enforcement layer. The cognitive layer (knowledge wiki, heuristics, spec review) exists as infrastructure but doesn't activate in practice. Strongest signal: open-ended prompts (+1.75) beat prescriptive specs.

## Approach

Three-layer fix:

1. **Fix the cascade** — nana-init not installed → enforce marker never created → all enforcement silently passes. Fix nana-init + py-review-stop-prompt.md orphan. Add bidirectional registration completeness test.

2. **Reform the spec** — rename Deliverables → Success Vision, add Domain Research Questions, strengthen anti-prescriptive guidance. The spec sets the floor (constraints, exit criteria) and elevates the ceiling (domain research prompts), not dictates implementation.

3. **Wire cognitive readiness** — structured session-start diagnostic replacing advisory nudges. Empty-wiki guidance in dev-plan.

## Constraints

- Session-start.sh ≤70 lines (use session-start.d/ modules)
- Dev-plan SKILL.md ≤350 lines, Spec SKILL.md ≤350 lines
- Keep 9-section spec structure (rename, don't restructure)
- Backward compatible with existing specs

## Key Decisions

- [[cascade-failure-diagnosis]]: nana-init not installed → enforce marker missing → all enforcement disabled
- [[spec-reform-reasoning-over-compliance]]: Reform spec based on +1.75 open-ended prompt finding
