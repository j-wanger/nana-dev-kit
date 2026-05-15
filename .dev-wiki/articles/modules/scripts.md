---
title: "scripts/"
aliases: []
category: modules
tags: [bash, cli]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: scan
type: module
path: "scripts/"
files: [scripts-sync-rules]
external_deps: [bash]
internal_deps: []
dependents: []
content_hash: "59fdc7c5cb5d280b"
---

# scripts/

Multi-agent sync utility that reads a shared AGENTS.md and writes surface-specific copies for Claude Code (CLAUDE.md), GitHub Copilot (copilot-instructions.md), Cursor (.cursor/rules/main.mdc), and Gemini (GEMINI.md).

## Files

- [[scripts-sync-rules|sync-rules.sh]] — Reads AGENTS.md content and writes 4 agent-surface copies with appropriate wrapping (67 lines)

## Key Patterns

- Single-script module; no library exports
- Reads source content then writes multiple output files with surface-specific formatting

## Dependencies

**Internal:** None

**External:** bash (shell interpreter)

## Dependents

- Makefile references this module via `bash scripts/sync-rules.sh . .`
