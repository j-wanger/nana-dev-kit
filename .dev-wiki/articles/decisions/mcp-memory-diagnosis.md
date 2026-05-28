---
title: MCP Memory Data Loss Diagnosis
created: 2026-05-27
status: accepted
confidence: high
source: investigation
---

# MCP Memory Data Loss Diagnosis

## Root Cause

Three compounding issues cause memory entries to appear "lost":

1. **CWD mismatch (primary):** `settings.json` configures `cwd: ~/.claude` but Claude Code launches the MCP server with CWD = the active project directory. `project_dir = ".memory"` resolves to `<project_root>/.memory/memory.db`, not `~/.claude/.memory/memory.db`. Each project directory gets its own DB. Switching projects = different DB = entries not found.

2. **Health probe checks wrong path:** `session-start.sh` line 83 checks `$HOME/.claude/memory_server/memory.db` — this path has never existed. The probe silently returns 0 on failure.

3. **Health probe uses wrong column:** Query uses `WHERE is_active=1` but the actual column is `active` (storage.py:54). SQL error caught by `|| echo "0"` fallback, always reports 0.

## Evidence

- `~/.memory/global.db` exists (69KB, May 12) but has 0 entries — schema only, never populated
- `/Users/jwang/nana-dev-kit/.memory/memory.db` exists (4KB main + 3.8MB WAL) with 11 active entries, all from 2026-05-27+
- `~/.claude/.memory/` does not exist (the path settings.json CWD would produce)
- No `.memory/memory.db` under `~/.claude/` at all
- Entry `mem_-s_rhYC8NNyB` explicitly records "MCP memory completely empty after Phase 49"
- All 11 current entries are from Phases 49-53 (same day, 2026-05-27) — entries from Phases 19-48 (May 22-25) are gone

## Resolution

**Diagnosis complete. No fix applied in this phase.**

The data loss was real — Phase 19-48 entries are irrecoverable (the `.memory/memory.db` from those sessions no longer exists, likely because the MCP server restarted with a fresh DB). The current 11 entries are from recent sessions.

**Bugs to fix in a future phase (out of scope for Phase 53):**
- `templates/.claude/hooks/session-start.d/memory-nudge.sh`: fix DB path and column name
- CWD behavior is Claude Code platform behavior — document, don't attempt to override
- Consider using `scope: "global"` for bridge-decisions to survive CWD changes
