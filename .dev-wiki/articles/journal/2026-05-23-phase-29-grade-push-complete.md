---
title: "Phase 29: v0.5.1 Grade Push — complete"
aliases: []
category: journal
tags: [dx, testing, memory, spec, enforcement, skills]
parents: [phase-29-v051-grade-push]
created: 2026-05-23
updated: 2026-05-23
source: debrief
---

# Phase 29: v0.5.1 Grade Push — complete

## What Happened

- Closed 5 gaps from the v0.5.0 five-lens critique across 7 tasks: root-skip guards for CI robustness, dev-plan companion extraction for ceiling headroom, two new skills (/nana discovery + /memory-consolidate), spec provenance enforcement, and event logging in enforcement hooks.
- Key architectural additions: /nana skill reads MANIFEST via kit path marker for in-session skill discovery (37 lines); /memory-consolidate uses Claude MCP tools instead of vendored Qwen consolidator.py (45 lines); enforce-spec.sh restructured with provenance OR logic and enforcement.log.
- Dev-plan SKILL.md reduced from 341 to <=330 lines via Step 3 extraction to scope-exploration-spec.md companion — third companion extraction following the established pattern.

## Decisions Made

- [[skill-based-memory-consolidation|Skill-based memory consolidation]] — Claude MCP tools over vendored Qwen consolidator.py; no vendor fork divergence
- [[spec-provenance-html-comment|Spec provenance via HTML comment]] — `<!-- nana:approved -->` marker with OR fallback for ~20 existing specs
- [[dev-plan-scope-extraction|Dev-plan Step 3 scope extraction]] — companion extraction to scope-exploration-spec.md, target <=330 lines

## Problems Solved

- Root-as-user test failures — `id -u` guard skips writability tests when running as root (CI/Docker environments)
- Dev-plan ceiling pressure — 341/350 lines had zero headroom; extraction freed ~10-20 lines for future additions
- Enforcement gap for spec provenance — enforce-spec.sh now checks both `nana:approved` marker and exit-criteria (backward compat OR logic)

## Artifacts Changed

- `tests/test_sync_rules.sh` (root-skip guards with `id -u`)
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 3 extraction, <=330 lines)
- `templates/.claude/skills/dev-plan/scope-exploration-spec.md` (new companion)
- `templates/.claude/skills/nana/SKILL.md` (new skill, 37 lines)
- `templates/.claude/skills/memory-consolidate/SKILL.md` (new skill, 45 lines)
- `templates/.claude/skills/spec/SKILL.md` (provenance marker in Step 6)
- `templates/.claude/hooks/enforce-spec.sh` (provenance OR + enforcement.log + 500-line cap)
- `templates/.claude/hooks/enforce-loop.sh` (enforcement.log event logging)
- `tests/test_templates.sh` (MANIFEST freshness test + 5 new skill assertions)
- `templates/.claude/skills/MANIFEST` (2 new skill entries: nana, memory-consolidate)
- `README.md` (memory-consolidate note)

## Soft Observations / Phase N+1 Candidates

- MANIFEST is manually maintained — freshness test catches drift but Makefile automation would be more robust | Consider `make manifest` target | evidence: test_templates.sh manifest_freshness test
- dev-plan at 330/350 lines — next feature needs another extraction or ceiling raise | Plan extraction budget before adding features | evidence: scope-exploration-spec.md precedent
- enforcement.log is a new artifact not yet in eval corpus | Add eval scenarios for enforcement logging | evidence: enforce-spec.sh + enforce-loop.sh changes

## Health Delta

- Tests: all passing (new: MANIFEST freshness test + 5 skill assertions in test_templates.sh, root-skip guard in test_sync_rules.sh)
- Eval: 43/43 unchanged
- Active knowledge hit rate: 4/4 (100%) — all 4 entries directly used during implementation

## Related

- [[phase-29-v051-grade-push|Phase 29: v0.5.1 Grade Push]] — parent phase
