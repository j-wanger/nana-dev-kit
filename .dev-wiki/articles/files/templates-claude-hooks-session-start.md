---
title: "templates/.claude/hooks/session-start.sh"
aliases: []
category: files
tags: [bash, claude-hook]
parents: [templates-claude-hooks]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "templates/.claude/hooks/session-start.sh"
content_hash: "651b1e472c049fb6"
exports: []
imports: []
imported_by: ["templates/.claude/settings.json"]
data_reads: ["PROJECT_STATE.md", ".claude/rules/py-session-state.md"]
data_writes: ["stdout (context injection)"]
---

# templates/.claude/hooks/session-start.sh

SessionStart hook that loads project and session state files into Claude's context at the beginning of each session via stdout output.

## Dependencies

External: none (pure bash with grep).

## Dependents

- [[templates-claude-settings|settings.json]] -- registered as SessionStart hook.

## Key Logic

- Reads `PROJECT_STATE.md` if present, outputs under an `=== Project State ===` header.
- Reads `.claude/rules/py-session-state.md` conditionally: extracts the line after `## Current Focus` via `grep -A1`. If the focus value is empty or literally `"(not set)"`, skips session state output entirely.
- Outputs to stdout, which Claude Code captures as context injection for the new session.
- Both file reads are guarded by existence checks; missing files are silently skipped.
