# Memory-Layer Liveness Probe — Phase 89 (read-only, run BEFORE the round)

Read-only by design (import check + registration read + row count; never a store) — the
observation apparatus must not write the rows it later counts. Run 2026-06-11, pre-T4-checkpoint.

## Probe record

- MCP registration: user-scope (`~/.claude.json` global `mcpServers.memory` + `~/.claude/settings.json`)
  — edge-screener sessions inherit it.
- server import command: `cd ~/.claude && memory_server/.venv/bin/python3 -c 'import memory_server'`
- exit code: 0
- marker states: `~/.claude/enforce-memory` PRESENT (armed; global marker is project-reachable, so
  edge-screener sessions ARE enforce-memory-nudged) · `/Users/jwang/edge-screener/.claude/enforce-memory` ABSENT
- before-round DB row count: 0 (`/Users/jwang/edge-screener/.memory/memory.db` ABSENT — no
  edge-screener session has ever stored a memory; consistent with the Phase-85 probe)
- kit DB row count (informational, not the demand substrate): 89 — includes 2 bridge-decision
  stores written by the Phase-89 planning session itself (kit-side writer liveness, live).

A demand zero in this round counts as evidence (couldnt-fire excluded by the exit-0 import).
Tool-DISCOVERY failures remain a separate tally (`couldnt-find`, per the pre-registration
admissibility pin 3): the layer being live does not guarantee a headless agent finds the
deferred tool.
