---
title: "templates/.claude/hooks/audit-log.sh"
aliases: []
category: files
tags: [bash, claude-hook]
parents: [templates-claude-hooks]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "templates/.claude/hooks/audit-log.sh"
content_hash: "8f47d8a1e80f406a"
exports: []
imports: []
imported_by: ["templates/.claude/settings.json"]
data_reads: ["stdin (JSON)"]
data_writes: [".nana/audit.jsonl"]
---

# templates/.claude/hooks/audit-log.sh

PostToolUse hook that appends a JSONL audit record for every file write operation, capturing timestamp, tool name, and file path.

## Dependencies

- `python3` (external) -- parses JSON from stdin to extract `file_path` and `tool_name`.

## Dependents

- [[templates-claude-settings|settings.json]] -- registered as PostToolUse hook.

## Key Logic

- Reads full stdin JSON, extracts `input.file_path` and `tool_name` via inline Python one-liners. Falls back gracefully if parsing fails.
- Exits early (exit 0) if no `file_path` is present (non-write tool invocations).
- Creates `.nana/` directory on first use, writes JSONL records to `.nana/audit.jsonl`.
- Model field cut in Phase 83 (couldnt-fire: `CLAUDE_MODEL` is never set by Claude Code, so the field could only ever hold `"unknown"` — [[prune-on-value-subtraction]]).
