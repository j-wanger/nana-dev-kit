---
title: "MCP memory server CWD fix: install.sh set wrong working directory"
aliases: [mcp-cwd-fix, memory-server-cwd]
category: decisions
tags: [mcp, memory, install, bug-fix]
parents: [phase-38-install-integrity-functional-verification]
created: 2026-05-25
updated: 2026-05-25
source: debrief
confidence: high
---

## Context

MCP memory server had been non-functional since Phase 4 (33 phases). install.sh set the MCP server's `cwd` to `~/.claude/memory_server` (inside the package directory) instead of `~/.claude` (parent directory). The server never started because the working directory didn't match expected paths. This was masked by structural-only testing -- tests verified file existence but never ran the server.

## Decision

Fixed the CWD path in install.sh from `memory_server` subdirectory to parent `~/.claude` directory. Also fixed the live `~/.claude/settings.json` to unblock the current installation. Added install-time MCP server verification (Python import check) to catch similar issues in the future.

Alternatives considered:
- Fix only in install.sh template: rejected because the live settings.json was already broken and needed immediate repair.
- Add full server startup test: rejected as too heavy for install.sh; import check is sufficient to verify CWD is correct.

## Consequences

- MCP memory server now starts correctly on fresh installs and re-installs.
- Import check catches CWD errors at install time rather than silently failing at runtime.
- Exposed that 33 phases of "memory" features were never actually using persistent memory -- all worked via in-session context only.
