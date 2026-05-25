---
title: "install.sh extraction: modules.json + register-settings.py"
aliases: [install-extraction]
category: decisions
tags: [install, extraction, refactoring, modules]
confidence: high
source: plan
created: 2026-05-25
updated: 2026-05-25
---

## Decision

Extract install.sh's ~137 lines of inline Python into `scripts/register-settings.py`. Create `modules.json` as the single declarative source of truth for module group definitions (skill lists, hook registrations, MCP config).

## Context

install.sh grew from 41 to 542 lines over 39 phases. Contains duplicated Python upsert logic (project-local: 46 lines, global hooks: 72 lines, MCP: 19 lines). 3 of 4 historical install.sh bugs were in the inline Python (CWD path, MultiEdit matchers, ghost hooks). 1 was in bash arrays (missing skills).

## Rationale

**Why modules.json (not just Python extraction):** Skill/hook data currently lives in 5 places (install.sh arrays, Python upsert calls, settings.json, MANIFEST, README). modules.json as single source of truth enables:
- Test validation: modules.json skills vs templates/.claude/skills/ filesystem
- README staleness: count hooks/skills from modules.json, compare to README claims
- MANIFEST generation: derive from modules.json
- install.sh simplification: read skill lists via jq instead of hardcoded arrays

**Why not bash function extraction:** The core complexity is in JSON manipulation (upsert, flat-to-nested migration, ghost cleanup). Bash can't do this cleanly. Python script extraction makes the JSON logic independently testable.

**Why not separate scripts (register-hooks.py + register-mcp.py):** Both are JSON merge operations on settings.json. One script with subcommands is simpler.

## Alternatives Considered

1. **Python extraction only** — addresses 3/4 bugs but doesn't create single source of truth
2. **Bash function extraction** — sourced lib/ modules. Doesn't address JSON manipulation complexity.
3. **Full rewrite in Python** — install.sh as thin bash wrapper calling Python for everything. Over-engineering for this project's needs.

## Status

Implemented in Phase 40. Confidence upgraded from medium to high — install.sh reduced from 542 to 318 lines (41%), zero inline Python, all tests pass.
