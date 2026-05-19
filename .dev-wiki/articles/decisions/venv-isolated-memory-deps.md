---
title: "Venv-isolated memory deps"
aliases: [venv memory deps, isolated venv for memory server]
category: decisions
tags: [venv, memory, pip, isolation, install]
parents: [phase-05-memory-bootstrap-and-report]
created: 2026-05-15
updated: 2026-05-15
source: plan
status: accepted
confidence: medium
---

## Context

Phase 5 needs to install pip dependencies (mcp, pydantic, pyyaml, nanoid, httpx) for the vendored memory_server. Two approaches considered: (1) install deps in an isolated venv at ~/.claude/memory_server/.venv/, (2) install via pip install --user into user site-packages.

## Decision

Create a venv at ~/.claude/memory_server/.venv/ during install.sh, pip install requirements.txt into it, and update the MCP config to use the venv's Python interpreter path. Graceful fallback: if python3-venv is unavailable, warn the user and continue (memory is optional functionality).

pip install --user was rejected because it pollutes user site-packages, risks version conflicts with other Python projects, and makes uninstall difficult. Venv isolation keeps all memory server deps self-contained and removable by deleting a single directory.

## Consequences

- Memory server deps are fully isolated -- no system Python pollution
- MCP config points to venv Python, ensuring correct interpreter with deps available
- install.sh gains network dependency (pip install) -- graceful fallback if venv creation fails
- Uninstall is clean: rm -rf ~/.claude/memory_server/.venv/
- Requires python3 -m venv to be available on the system (standard on modern Python 3.3+)
- config.py imports yaml at module level -- server won't start without deps in the venv
