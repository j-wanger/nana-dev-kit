---
title: "Vendor memory server"
aliases: [vendor memory_server, self-contained memory server]
category: decisions
tags: [memory, vendoring, distribution]
parents: [phase-04-dev-wiki-and-memory-integration]
created: 2026-05-15
updated: 2026-05-15
source: plan
status: accepted
confidence: medium
---

## Context

Phase 4 integrates nanaclaw's memory_server (2,373 lines Python, 12 source files, MCP stdio interface) into nana-dev-kit. Two alternatives considered: (1) vendor the full Python source into nana-dev-kit/memory_server/, (2) reference nanaclaw's install location via path.

## Decision

Vendor memory_server as-is from nanaclaw into nana-dev-kit/memory_server/, excluding tests/ and __pycache__/. Do not strip fastembed -- embedding.py already has try/except guard for optional dependencies. Split requirements into required (mcp, pydantic, pyyaml, nanoid, httpx) and optional (fastembed, sqlite-vec).

Path reference was rejected because it couples nana-dev-kit to a separate nanaclaw installation, breaking self-contained distribution. Sync decay is acceptable -- memory_server is a stable MCP interface unlikely to change frequently.

## Consequences

- Kit is fully self-contained: no external dependency on nanaclaw installation
- install.sh can copy memory_server to ~/.claude/memory_server/ without path resolution
- Sync decay risk: vendored copy may drift from nanaclaw source over time
- fastembed/sqlite-vec remain optional -- kit works without them (graceful degradation)
- Adds ~2,400 lines of Python to the kit's footprint
