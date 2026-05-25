---
title: "Phase 40: install.sh Extraction & Anti-Pattern Hardening complete"
aliases: []
category: journal
tags: [install, extraction, refactoring, modules, anti-pattern, prevention]
parents: [phase-40-install-extraction-anti-pattern-hardening]
created: 2026-05-25
updated: 2026-05-25
source: debrief
---

# Phase 40: install.sh Extraction & Anti-Pattern Hardening complete

## What Happened
- Decomposed install.sh from 542 to 318 lines (41% reduction), eliminating all 137 lines of inline Python across 3 blocks (project-local hooks, MCP registration, global hooks).
- Created modules.json as single declarative source of truth for 5 module groups (core, python, typescript, dev-wiki, knowledge-wiki) with skill lists, hook registrations, and MCP config.
- Extracted duplicated Python upsert logic into scripts/register-settings.py (~120 lines) with hooks + mcp subcommands, argparse CLI, flat-to-nested migration, and ghost cleanup.
- Completed PostToolUse normalization: stale-queue.sh and post-commit.sh now use `.tool_input // .input` fallback pattern matching the other 3 hooks.
- Phase article housekeeping: deleted Phase 12 duplicate, merged Phase 22 canonical, fixed Phase 24 status, added /init to README + install.sh Getting Started.
- Codified functional smoke invariant rule in spec SKILL.md and dev-plan implementation-guide.md.
- Added ~10 new tests (register-settings.py upsert idempotency, ghost cleanup, MCP registration, modules.json filesystem consistency).

## Decisions Made
- [[install-sh-extraction-approach|install.sh extraction: modules.json + register-settings.py]] -- confidence upgraded medium to high (validated by implementation)
- [[functional-smoke-invariant-rule|Functional smoke invariant]] -- confirmed high (codified in spec + dev-plan)

## Problems Solved
- install.sh inline Python was #1 source of silent regressions (3 of 4 historical bugs) -- eliminated entirely via extraction to register-settings.py
- Module definitions scattered across 5 locations -- consolidated into modules.json as single source of truth
- PostToolUse normalization gap in stale-queue.sh and post-commit.sh -- fixed with dual-field fallback

## Artifacts Changed
- `install.sh` (542 to 318 lines, zero inline Python, reads modules.json via jq)
- `modules.json` (new -- declarative module manifest, 5 modules)
- `scripts/register-settings.py` (new -- ~120 lines, hooks + mcp subcommands)
- `templates/.claude/hooks/stale-queue.sh` (PostToolUse dual-field fallback)
- `templates/.claude/hooks/post-commit.sh` (PostToolUse dual-field fallback)
- `templates/.claude/skills/spec/SKILL.md` (functional smoke invariant rule)
- `templates/.claude/skills/dev-plan/implementation-guide.md` (integration checklist)
- `templates/.claude/skills/MANIFEST` (regenerated)
- `tests/test_install.sh` (~10 new tests)
- `.dev-wiki/articles/phases/` (housekeeping: deleted duplicate, fixed statuses)
- `README.md` (added /init mention)

## Health Delta
- Tests: 291 to ~301 (+10 new tests for register-settings.py + modules.json)
- Eval: stable at 50/50 (100%)
- install.sh: 542 to 318 lines (41% reduction)
- Inline Python: 137 to 0 lines (100% elimination)

### Activation Quality
- Active knowledge had 3 entries for Phase 40 (inline Python structure, PostToolUse fallback, functional smoke invariant)
- All 3 entries were directly relevant and used during implementation
- Hit rate: 3/3 (100%)

## Related
- [[phase-40-install-extraction-anti-pattern-hardening|Phase 40]]

## Soft Observations / Phase N+1 Candidates
- test_harden.sh uses test_start/test_pass pattern (not assert_*) -- workflow.html "0 assertions" report is misleading but benign. Consider fixing the report parser to count both patterns.
- The user's 6-anti-pattern systematic review methodology surfaced issues invisible to per-phase testing. Validates "review the history, not just the code" approach.
