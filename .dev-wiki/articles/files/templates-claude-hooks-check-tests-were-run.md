---
title: "templates/.claude/hooks/check-tests-were-run.sh"
aliases: []
category: files
tags: [bash, claude-hook]
parents: [templates-claude-hooks]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "templates/.claude/hooks/check-tests-were-run.sh"
content_hash: "ad50bbfaf8ce50a1"
exports: []
imports: []
imported_by: ["templates/.claude/settings.json"]
data_reads: ["stdin (JSON)"]
data_writes: []
---

# templates/.claude/hooks/check-tests-were-run.sh

Stop hook that prevents Claude from declaring "done" if Python files were modified during the session but pytest was never run. Exit 0 allows stop; exit 2 forces Claude to continue (with a stderr prompt to run tests).

## Dependencies

- `python3` (external) -- parses session context JSON to scan `tool_uses` array.

## Dependents

- [[templates-claude-settings|settings.json]] -- registered as Stop hook.

## Key Logic

Two-phase scan of the `tool_uses` array from stdin JSON:

1. **Python file detection** -- iterates tool uses, checks `file_path` and `command` fields for `.py` substring. If none found, allows stop immediately.
2. **Pytest detection** -- if Python files were touched, scans tool uses for any `command` containing `pytest`. If absent, exits 2 with a message directing Claude to run `uv run pytest -x --cov=src --cov-fail-under=85`.

Both phases use inline Python one-liners with graceful fallback to `"no"` on parse failure.
