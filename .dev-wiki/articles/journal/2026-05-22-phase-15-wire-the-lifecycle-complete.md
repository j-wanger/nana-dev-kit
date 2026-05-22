---
title: "Phase 15: Wire the Lifecycle complete"
aliases: []
category: journal
tags: [monorepo, skills, install, hooks, precompact, session-start, memory, integration]
parents: [phase-15-wire-the-lifecycle]
created: 2026-05-22
updated: 2026-05-22
source: debrief
---

# Phase 15: Wire the Lifecycle complete

## What Happened
- Imported 17 skill directories (6 dev-wiki + 11 knowledge-wiki) from ~/.claude/skills/ into templates/.claude/skills/, totaling 111+ files (~630KB). Source repos (~/dev-wiki, ~/knowledge-wiki) are now historical -- monorepo is canonical.
- Refactored install.sh from linear copy to module-group architecture (~240 lines) with --all/--core-only/--no-python/--dry-run flags and module dependency validation (core -> python, dev-wiki, knowledge-wiki).
- Added PreCompact hook (templates/.claude/hooks/pre-compact.sh): pure bash, reads committed _CURRENT_STATE.md + tasks.md + active-phase.md, outputs structured summary for context injection.
- Enhanced session-start.sh with memory_search topic guidance -- extracts active task topic from dev-wiki state and outputs actionable memory_search suggestion.
- Generated MANIFEST at templates/.claude/skills/MANIFEST with 114 entries (sorted file listing + md5 checksums) for drift detection baseline.
- Test suite expanded: 67 -> 92 tests (+25). All passing in ~5.2s.

## Decisions Made
- [[monorepo-skill-distribution|Monorepo Skill Distribution]] -- already captured during /dev-plan (deduped)
- [[import-source-canonical-installed|Import Source -- Canonical Installed Versions]] -- already captured during /dev-plan (deduped)

## Problems Solved
- SIGPIPE race: grep -q in pipefail mode causes premature pipe closure when the producing process hasn't finished writing. Fix: capture output to variable first, then grep.
- __pycache__ directories imported from ~/.claude/skills/ and had to be manually cleaned from templates/.claude/skills/.

## Open Questions
- /spec routing: skill listed in available skills but not recognized as command. Orthogonal to Phase 15. (carried forward from Phase 14)

## Artifacts Changed
- `templates/.claude/skills/` (17 new dirs, MANIFEST), `install.sh` (refactored ~240 lines)
- `templates/.claude/hooks/pre-compact.sh` (new), `session-start.sh` (enhanced)
- `tests/test_install.sh`, `tests/test_templates.sh` (expanded, 67 -> 92 tests)

## Soft Observations / Phase N+1 Candidates
- wiki-index ships .py files -- language-neutrality audit candidate
- __pycache__ imported, manually cleaned -- install.sh should exclude
- SIGPIPE race with grep -q in pipefail -- capture-to-variable pattern

### Health Delta
Tests: 67 -> 92 (+25). All passing in ~5.2s. install.sh execution: <10s. Soul: 59/60 (unchanged). Instruction budget: 245/300 (unchanged).

### Gate Compliance (Phase 15)

| Gate | Status | Finding |
|------|--------|---------|
| spec | 7/10(revised-to-accept) | Pass |
| approach | yes | Pass |
| plan-review | 7/10(revised) | Pass |
| tasks | yes | Pass |

Standard ceremony: all 4 gates present. No compliance issues.

### Retro Check (Phases 11-15)

| Dim | Signal | Note |
|-----|--------|------|
| 1. Blockers | none | 0 blocked tasks |
| 2. Reversals | none | 0 reversals |
| 3. User Corrections | low | 1: /spec routing (tooling, not process) |

Pattern shift: user corrections dropped from 3 (Phases 1-10) to 1. Gate enforcement validated across 5 phases. /spec routing should not carry indefinitely.

## Related
- [[phase-15-wire-the-lifecycle|Phase 15: Wire the Lifecycle]] -- parent phase
