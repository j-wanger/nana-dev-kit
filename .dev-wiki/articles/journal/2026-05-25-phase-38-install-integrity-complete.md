---
title: "Phase 38: Install Integrity & Functional Verification complete"
aliases: []
category: journal
tags: [install, testing, hooks, integrity, mcp, memory]
parents: [phase-38-install-integrity-functional-verification]
created: 2026-05-25
updated: 2026-05-25
source: debrief
---

# Phase 38: Install Integrity & Functional Verification complete

## What Happened
- Pre-phase discovery: MCP memory server had been non-functional since Phase 4 (33 phases) due to install.sh setting wrong CWD path. Fixed in install.sh and live settings.json. Changed 6 files from fail-silent to fail-loud on MCP failures.
- Added 5 missing skills to install.sh: nana + memory-consolidate to CORE_SKILLS, py-lint + py-review + py-test to PYTHON_SKILLS.
- Fixed all 10 MultiEdit matcher sites in install.sh (7 upserts + 3 display strings).
- Fixed dev-wiki-scope-check.sh field path from .tool_input.file_path to .input.file_path.
- Regenerated MANIFEST (25 skills, 124 files).
- Added 23 functional verification tests covering module isolation, hook parsing, companion files, and MCP import.
- Documented PostToolUse field path inconsistency in _ARCHITECTURE.md Known Issues.

## Decisions Made
- [[mcp-memory-server-cwd-fix|MCP memory server CWD fix]] -- high confidence
- [[fail-loud-over-fail-silent-memory|Fail-loud over fail-silent for memory]] -- high confidence
- [[install-skill-module-assignment|Skills module assignment]] -- high confidence (confirmed from planning)
- [[posttooluse-field-path-inconsistency|PostToolUse field path: document only]] -- high confidence (confirmed)

## Problems Solved
- MCP memory server non-functional for 33 phases -- root cause: install.sh CWD pointed inside package instead of parent directory
- Silent memory failures masking broken infrastructure -- changed to visible warnings with diagnostic hints

## Open Questions
- PostToolUse stdin contract: does Claude Code send .input or .tool_input for Write/Edit PostToolUse hooks? Both patterns appear in working hooks.

## Artifacts Changed
- `install.sh` (~508 to ~535 lines: CORE_SKILLS iteration, MultiEdit matchers, MCP verify, session-start.d copy)
- `templates/.claude/hooks/dev-wiki-scope-check.sh` (field path fix)
- `templates/.claude/hooks/session-start.sh` (MCP health check)
- `templates/.claude/hooks/session-start.d/memory-nudge.sh` (fail-loud warning)
- `templates/.claude/skills/MANIFEST` (regenerated, 25 skills)
- `templates/.claude/skills/{dev-debrief,dev-plan,spec,wiki-query}/*.md` (fail-loud on MCP)
- `tests/test_install.sh` (+23 functional verification tests)
- `.dev-wiki/_ARCHITECTURE.md` (PostToolUse inconsistency documented)

## Health Delta
- Tests: 259 to 283 (+23 new functional verification tests)
- Eval: 47/47 (unchanged, 100%)
- install.sh: ~508 to ~535 lines

## Related
- [[phase-38-install-integrity-functional-verification|Phase 38]]

## Soft Observations / Phase N+1 Candidates
- Installed skill files at ~/.claude/skills/ are stale from prior install runs -- need re-install to pick up Phase 37-38 changes
- context-size-check.sh python3 vs jq inconsistency still unresolved | carried from Phase 36 | low priority
- delivery-flow.md companion exists in templates but not installed (stale skills)
