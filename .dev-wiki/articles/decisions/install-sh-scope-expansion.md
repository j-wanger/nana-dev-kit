---
title: "install.sh scope expansion"
aliases: [install scope expansion, 3 files to 4 actions, memory server registration]
category: decisions
tags: [install, memory, mcp, escape-hatch]
parents: [phase-04-dev-wiki-and-memory-integration]
created: 2026-05-15
updated: 2026-05-15
source: plan
status: accepted
confidence: medium
---

## Context

install.sh currently copies 3 files (py-init SKILL.md, nana-soul.md, .nana-dev-kit-path). Phase 4 requires memory_server to be available globally and registered as an MCP server in ~/.claude/settings.json. The existing decision [[install-sh-stays-minimal]] constrained install.sh to 3-file copies.

## Decision

Expand install.sh from 3-file copy to 4 actions: the original 3 plus copying memory_server/ to ~/.claude/memory_server/ and registering the MCP server in ~/.claude/settings.json via idempotent python3 JSON merge. This is a DEPENDENCY escape hatch per the dev-wiki hooks protocol -- Phase 4's objective requires install.sh evolution.

The JSON merge uses python3's json module (already expected on target systems for hook scripts) to idempotently add a mcpServers entry. If settings.json doesn't exist, it creates it. If it exists without mcpServers, it adds the key. If mcpServers already has the entry, it's a no-op.

## Consequences

- install.sh grows from simple file copy to include directory copy + JSON manipulation
- python3 becomes a hard dependency for install.sh (was already soft dependency for hooks)
- Idempotent design preserved: running install.sh twice produces identical results
- Supersedes [[install-sh-stays-minimal]] for Phase 4+ (noted via DEPENDENCY escape hatch)
- MCP server registration is global -- all Claude Code sessions get memory server access
