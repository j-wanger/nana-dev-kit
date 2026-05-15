---
title: "templates/.claude/hooks/block-dangerous-bash.sh"
aliases: []
category: files
tags: [bash, claude-hook]
parents: [templates-claude-hooks]
created: 2026-05-15
updated: 2026-05-15
source: scan
type: file
path: "templates/.claude/hooks/block-dangerous-bash.sh"
content_hash: "ac109ed93658fc35"
exports: []
imports: []
imported_by: ["templates/.claude/settings.json"]
data_reads: ["stdin (JSON)"]
data_writes: []
---

# templates/.claude/hooks/block-dangerous-bash.sh

PreToolUse hook for the Bash tool that blocks dangerous commands before execution. Exit 0 allows the command; exit 2 blocks it with a stderr explanation shown to Claude.

## Dependencies

- `python3` (external) -- parses JSON from stdin to extract the `command` field.

## Dependents

- [[templates-claude-settings|settings.json]] -- registered as PreToolUse hook.

## Key Logic

Four grep-based pattern checks, each blocking with exit 2 and a descriptive stderr message:

1. **`rm -rf` with dangerous targets** -- blocks recursive force-delete targeting `/`, `~`, `$HOME`, or `..`.
2. **`git push --force`** -- blocks force-push; suggests `--force-with-lease` or PR workflow.
3. **`--no-verify` on commit/push** -- blocks hook bypass; directs to fix the underlying hook failure.
4. **`git reset --hard`** -- blocks hard reset; suggests `git stash` or file-specific checkout.

Commands not matching any pattern pass through (exit 0).
