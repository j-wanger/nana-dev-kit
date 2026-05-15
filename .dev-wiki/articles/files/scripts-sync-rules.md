---
title: "scripts/sync-rules.sh"
aliases: []
category: files
tags: [bash]
parents: [scripts]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "scripts/sync-rules.sh"
content_hash: "1d1b52525898c659"
exports: []
imports: []
imported_by: ["Makefile"]
data_reads: ["AGENTS.md"]
data_writes: ["CLAUDE.md", ".github/copilot-instructions.md", ".cursor/rules/main.mdc", "GEMINI.md"]
---

# scripts/sync-rules.sh

Syncs AGENTS.md (single source of truth for project rules) to four agent-surface copies: CLAUDE.md, `.github/copilot-instructions.md`, `.cursor/rules/main.mdc`, and GEMINI.md.

## Dependencies

External: none (pure bash).

Invoked by: `Makefile` via `bash scripts/sync-rules.sh . .`

## Dependents

- `Makefile` -- `sync-rules` target

## Key Logic

- Accepts two positional args: `template-dir` (where AGENTS.md lives) and `target-dir` (project root for output). Both default to `.`.
- Reads AGENTS.md content into a shell variable, then writes it to four files with an auto-generated header warning against direct edits.
- The Cursor surface (`.cursor/rules/main.mdc`) gets additional YAML frontmatter wrapping (`description`, `globs`, `alwaysApply: true`).
- Creates `.github/` and `.cursor/rules/` directories as needed via `mkdir -p`.
- Exits non-zero if AGENTS.md is missing.
