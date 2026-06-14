---
title: "Memory MCP Consumer E2E Fix (fix-then-judge + PYTHONPATH env)"
aliases: ["memory-mcp-consumer-e2e-fix", "memory-pythonpath-env", "memory-fix-then-judge"]
category: decisions
tags: [memory, mcp, registration, pythonpath, env, fix-then-judge, per-project-topology, verify-by-firing, phase-91]
parents: [phase-91-memory-e2e-and-gate-forcing-function]
created: 2026-06-14
updated: 2026-06-14
source: plan
confidence: high
status: active
---

# Memory MCP Consumer E2E Fix (Phase 91, Track 1)

## Context
The kit's memory MCP server has been DEAD in every consuming project. The registration launches
`python -m memory_server`, and `-m <module>` resolves the package only from a cwd that CONTAINS it — only
nana-dev-kit (the kit source repo) does. Proven via the real `-m` launch: rc=1 "No module named
memory_server" from a consumer cwd; rc=0 with `PYTHONPATH=~/.claude`. Every "zero voluntary memory use" in a
consumer (the Phase-85/88/89 demand zeros) was therefore **couldn't-fire**, not absent demand — inadmissible
prune evidence.

This is the load-bearing question for the queued **Phase 92 memory-layer prune**: a prune that judges demand
on a layer the consumer could never reach is judging the wrong thing.

## Decision
**Fix-then-judge** (gate A1 accept): repair the consumer end-to-end break NOW so Phase 92 judges demand on a
WORKING layer — not cut-first. If false, Track 1 activates a layer Phase 92 then removes; the maintainer
accepted that risk because couldn't-fire is inadmissible prune evidence either way.

Three pieces:
1. **Root-cause fix — teach the registration an `env`.** Add an `env` field `{PYTHONPATH: $HOME/.claude}` to
   the modules.json mcp block and extend `scripts/register-settings.py` `cmd_mcp` to EMIT env (it previously
   wrote only command/args/cwd; the whole `mcpServers.memory` dict is replaced each regen). Landed in BOTH
   `~/.claude/settings.json` AND the authoritative `~/.claude.json` (Claude Code's native MCP config), with a
   read-back value assert.
2. **Verify-by-firing (A2 ⇒ HEU-012).** Only the Python import-chain was validated at plan time, NOT a fired
   MCP launch — so the FIRST Track-1 task is verify-by-firing `memory_search` in a real consumer
   (STOP-on-fail per the gate abort). T5 confirmed it: a consumer-context call returns without error and
   `<project>/.memory/memory.db` is created.
3. **Per-project topology (gate A3 accept).** Consumers need WITHIN-project continuity → per-project
   `<project>/.memory/` DBs, not a shared/global store; `MEMORY_PROJECT_DIR` deliberately not set. Ship a
   `.memory/` (+ `-wal`/`-shm`) gitignore in the template and a consumer memory-setup doc.

## Consequences
- The memory layer now **FIRES** in consumers — Phase 92's prune MUST re-measure demand on the now-working
  layer; its prior "zero use" was couldn't-fire and is now inadmissible.
- The fix reaches all consumers because the MCP registration is global (`~/.claude.json` is user-scope). No
  per-consumer arming needed for memory (unlike the gate hook).
- A determined consumer still needs the kit at `~/.claude` for the package to resolve — PYTHONPATH points
  there. `install.sh` still does NOT ship fastembed; cosine reinforcement remains maintainer-machine-only.
- The maintainer-directed propagation (USER OVERRIDE) touched `~/.claude.json`, `~/.claude/settings.json`,
  and consumer `.gitignore`/settings — outside the phase's declared scope, recorded as a deviation.

## Rejected Alternatives
- **Cut the memory layer first (cut-then-judge)** — rejected: couldn't-fire is inadmissible prune evidence;
  judge a working layer (fix-then-judge).
- **A shared/global memory store** (A3 alternative) — rejected: consumers need within-project continuity, not
  cross-project bleed; per-project `.memory/` DBs are correct.
- **Trusting the registration as proof** — rejected (HEU-012): only a fired `-m` launch from a consumer cwd
  proves it; the import-chain check alone passed while the server was dead.

## Source
[[assumption-approval-gate]], [[HEU-012]], [[memory-layer-prune-round]]
