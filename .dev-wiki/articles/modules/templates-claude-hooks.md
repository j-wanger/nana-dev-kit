---
title: "templates/.claude/hooks/"
aliases: []
category: modules
tags: [bash, hooks, python3]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: scan
type: module
path: "templates/.claude/hooks/"
files: [templates-claude-hooks-audit-log, templates-claude-hooks-auto-ruff-format, templates-claude-hooks-block-dangerous-bash, templates-claude-hooks-check-tests-were-run, templates-claude-hooks-py-review-stop-prompt, templates-claude-hooks-scan-secrets, templates-claude-hooks-session-start]
external_deps: [bash, python3, gitleaks, ruff, uv]
internal_deps: []
dependents: []
content_hash: "999a3eef41bf670d"
---

# templates/.claude/hooks/

Claude Code lifecycle hook templates implementing the 5-layer dev harness. Covers PreToolUse, PostToolUse, SessionStart, and Stop hooks for audit logging, safety gating, formatting, and review prompts.

## Files

- [[templates-claude-hooks-audit-log|audit-log.sh]] — PostToolUse hook; logs tool calls to audit trail (22 lines)
- [[templates-claude-hooks-auto-ruff-format|auto-ruff-format.sh]] — PostToolUse hook; auto-formats Python files with ruff (16 lines)
- [[templates-claude-hooks-block-dangerous-bash|block-dangerous-bash.sh]] — PreToolUse hook; blocks destructive bash commands (36 lines)
- [[templates-claude-hooks-check-tests-were-run|check-tests-were-run.sh]] — Stop hook; verifies tests were executed before session end (48 lines)
- [[templates-claude-hooks-py-review-stop-prompt|py-review-stop-prompt.md]] — Stop prompt; triggers 8-point PR review checklist (11 lines)
- [[templates-claude-hooks-scan-secrets|scan-secrets.sh]] — PreToolUse hook; scans for leaked secrets via gitleaks (24 lines)
- [[templates-claude-hooks-session-start|session-start.sh]] — SessionStart hook; initializes session state (26 lines)

## Key Patterns

- All .sh hooks read JSON from stdin via python3 JSON parsing
- Exit 0 = allow, exit 2 = block (Claude Code hook protocol)
- Standalone scripts deployed to target projects (no inter-hook dependencies)

## Dependencies

**Internal:** None (standalone templates)

**External:** bash (shell), python3 (JSON parsing), gitleaks (secret scanning, optional), ruff (formatting, optional), uv (package runner, optional)

## Dependents

- [[templates-claude-settings|settings.json]] references each hook by path
