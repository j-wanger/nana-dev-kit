---
title: "templates/.claude/hooks/scan-secrets.sh"
aliases: []
category: files
tags: [bash, claude-hook]
parents: [templates-claude-hooks]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "templates/.claude/hooks/scan-secrets.sh"
content_hash: "4a48a3da8c1628cc"
exports: []
imports: []
imported_by: ["templates/.claude/settings.json"]
data_reads: ["stdin (JSON)", "target file content"]
data_writes: []
---

# templates/.claude/hooks/scan-secrets.sh

PostToolUse hook for Write/Edit/MultiEdit tools that scans written files for potential hardcoded secrets. Emits a stderr warning if secrets are detected; never blocks (always exits 0).

## Dependencies

- `python3` (external) -- parses JSON from stdin to extract `file_path`.
- `gitleaks` (optional external) -- preferred scanner; used when available on PATH.

## Dependents

- [[templates-claude-settings|settings.json]] -- registered as PostToolUse hook.

## Key Logic

- Exits early if no `file_path` present or if the target file does not exist.
- **Primary path:** if `gitleaks` is installed, runs `gitleaks detect --no-git --source <file> --quiet`. A non-zero exit emits a warning.
- **Fallback path:** if `gitleaks` is not available, uses `grep -qEi` with a regex matching common secret patterns: `api_key`, `secret_key`, `password`, `token`, `credential` followed by an assignment operator and a value of 16+ characters.
- Always exits 0 regardless of detection result -- warnings are advisory only.
