---
title: "templates/.claude/hooks/auto-ruff-format.sh"
aliases: []
category: files
tags: [bash, claude-hook]
parents: [templates-claude-hooks]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "templates/.claude/hooks/auto-ruff-format.sh"
content_hash: "1090072d8453dc95"
exports: []
imports: []
imported_by: ["templates/.claude/settings.json"]
data_reads: ["stdin (JSON)"]
data_writes: ["target .py file (in-place modification)"]
---

# templates/.claude/hooks/auto-ruff-format.sh

PostToolUse hook for Write/Edit/MultiEdit tools that auto-formats Python files with ruff after every write operation. Runs silently; skips non-Python files.

## Dependencies

- `python3` (external) -- parses JSON from stdin to extract `file_path`.
- `uv` (external, optional) -- required for ruff execution; hook is a no-op if `uv` is not on PATH.
- `ruff` (external, via uv) -- lint fixer and formatter.

## Dependents

- [[templates-claude-settings|settings.json]] -- registered as PostToolUse hook.

## Key Logic

- Guards on two conditions: file extension is `.py` AND `uv` is available on PATH. If either fails, exits silently.
- Runs two ruff passes sequentially: `ruff check --fix --quiet` (auto-fix lint issues) then `ruff format --quiet` (apply formatting). Both suppress stderr via `2>/dev/null || true`.
- Modifies the target file in-place; no backup or diff output.
