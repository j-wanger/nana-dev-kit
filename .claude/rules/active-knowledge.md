# Active Knowledge
# userEmail
The user's email address is wang.jan.tried@gmail.com.
# currentDate
Today's date is 2026-05-15.

# Phase 4 Context

## Memory Server Structure
- Source: /Users/jwang/nanaclaw/memory_server/ (2,373 lines Python, 12 source files)
- MCP server runs via stdio: python -m memory_server
- Key files: server.py (entry point), storage.py (backend), embedding.py (optional fastembed)
- Required deps: mcp, pydantic, pyyaml, nanoid, httpx
- Optional deps (try/except guarded): fastembed, sqlite-vec

## Frozen-Snapshot Pattern
- Session-start reads MEMORY.md once at boot (~1500 tokens)
- Never edit mid-session; read-only frozen snapshot
- Graceful silent skip when .memory/MEMORY.md or .dev-wiki/_CURRENT_STATE.md missing

## Install.sh Scope Expansion
- Currently: 3-file copy (py-init SKILL.md, nana-soul.md, .nana-dev-kit-path)
- Phase 4: adds 4th action (memory_server/ copy + mcpServers JSON merge)
- DEPENDENCY escape hatch per dev-wiki hooks protocol
- JSON merge via python3 json module, idempotent (no-op if entry exists)

## MCP Server Registration
- settings.json mcpServers is top-level key
- Format: {"mcpServers": {"memory": {"command": "python3", "args": ["-m", "memory_server"]}}}
- Three cases: no settings.json, existing without mcpServers, existing with mcpServers

## Session-Start Sources
- session-start.sh currently reads: PROJECT_STATE.md, py-session-state.md
- Phase 4 adds: .dev-wiki/_CURRENT_STATE.md, .memory/MEMORY.md
- All reads have file-existence guards (silent skip)
