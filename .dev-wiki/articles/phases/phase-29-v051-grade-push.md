---
title: "Phase 29: v0.5.1 Grade Push"
aliases: [v051-grade-push]
category: phases
tags: [dx, testing, memory, spec, enforcement]
parents: []
created: 2026-05-23
updated: 2026-05-23
source: plan
status: completed
scope: ["tests/test_sync_rules.sh", "templates/.claude/skills/dev-plan/SKILL.md", "templates/.claude/skills/dev-plan/scope-exploration-spec.md", "templates/.claude/skills/nana/SKILL.md", "templates/.claude/skills/memory-consolidate/SKILL.md", "templates/.claude/skills/spec/SKILL.md", "templates/.claude/hooks/enforce-spec.sh", "templates/.claude/hooks/enforce-loop.sh", "tests/test_templates.sh", "templates/.claude/skills/MANIFEST", "README.md"]
entry_criteria: "Phase 28 complete, 169 tests passing, 43/43 eval, v0.5.0 tagged"
exit_criteria: "Root-skip guards in writability tests, dev-plan SKILL.md <=330 lines with companion, /nana + /memory-consolidate skills created, spec provenance marker in /spec, enforce-spec.sh provenance OR + event logging, MANIFEST + README updated, make test + make eval pass"
---

# Phase 29: v0.5.1 Grade Push

## Objective

Close 5 remaining gaps from the v0.5.0 five-lens critique: test robustness (root-skip), dev-plan ceiling headroom (companion extraction), in-session skill discovery (/nana), memory consolidation (/memory-consolidate), spec provenance enforcement with event logging.

## Scope

- `tests/test_sync_rules.sh` -- root-skip guards for writability tests
- `templates/.claude/skills/dev-plan/` -- Step 3 extraction to companion
- `templates/.claude/skills/nana/` -- new /nana discovery skill
- `templates/.claude/skills/memory-consolidate/` -- new consolidation skill
- `templates/.claude/skills/spec/SKILL.md` -- provenance marker in Step 6
- `templates/.claude/hooks/enforce-spec.sh` -- provenance OR check + event logging
- `templates/.claude/hooks/enforce-loop.sh` -- event logging
- `tests/test_templates.sh`, `templates/.claude/skills/MANIFEST`, `README.md` -- integration

## Exit Criteria

- [x] `grep -q 'id -u' tests/test_sync_rules.sh` -- root-skip guards present
- [x] `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 330 ]` -- ceiling headroom
- [x] `test -f templates/.claude/skills/nana/SKILL.md` -- /nana skill exists
- [x] `test -f templates/.claude/skills/memory-consolidate/SKILL.md` -- /memory-consolidate skill exists
- [x] `grep -q 'nana:approved' templates/.claude/skills/spec/SKILL.md` -- spec provenance
- [x] `grep -q 'enforcement.log' templates/.claude/hooks/enforce-spec.sh` -- event logging
- [x] `make test && make eval` -- no regressions

## Approach

Seven tasks ordered by dependency. Independent items first (root-skip, companion extraction, new skills, spec provenance), then enforcement hardening, then integration task last. Key constraint: enforce-spec.sh uses OR logic (marker OR exit-criteria) for backward compat with ~20 existing marker-less specs. No vendored Python changes.

## Constraints

- enforce-spec.sh backward compat via OR logic (provenance marker OR exit-criteria check)
- No changes to vendored memory_server/ Python code
- Enforcement log capped at 500 lines via tail truncation
- dev-plan SKILL.md target <=330 lines post-extraction

## Notes

- Bundle phase driven by v0.5.0 five-lens critique gap closure
- 3 decisions: skill-based-memory-consolidation, spec-provenance-html-comment, dev-plan-scope-extraction
