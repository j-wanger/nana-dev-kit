---
title: "Phase 4: Dev-Wiki & Memory Integration"
aliases: []
category: phases
tags: [dev-wiki, memory, integration, scaffold, mcp]
parents: []
created: 2026-05-15
updated: 2026-05-15
source: plan
status: completed
scope: ["memory_server/", "install.sh", "tests/test_install.sh", "templates/.claude/hooks/session-start.sh", "templates/.claude/skills/py-init/SKILL.md", "README.md"]
entry_criteria: "Phase 3 complete, dev-wiki skill suite globally installed, nanaclaw memory_server exists"
exit_criteria: "memory_server vendored, install.sh registers MCP server, session-start reads dev-wiki + memory, SKILL.md suggests /dev-init, README documents integration"
---

# Phase 4: Dev-Wiki & Memory Integration

## Objective

Wire nanaclaw's memory system into the nana-dev-kit distribution, so every install gets a persistent memory MCP server. Enhance session-start to compose context from dev-wiki state and memory snapshots. Update documentation to reflect the integration.

## Approach

1. **Vendor memory_server** from nanaclaw into nana-dev-kit/memory_server/ (exclude tests/ and __pycache__/). Keep fastembed -- embedding.py has try/except guard. Split requirements: required (mcp, pydantic, pyyaml, nanoid, httpx) vs optional (fastembed, sqlite-vec).

2. **Expand install.sh** to 4th action: copy memory_server/ to ~/.claude/memory_server/ and register MCP server in ~/.claude/settings.json via idempotent python3 JSON merge. DEPENDENCY escape hatch for install-sh-stays-minimal.

3. **Enhance session-start.sh** to read .dev-wiki/_CURRENT_STATE.md and .memory/MEMORY.md with graceful silent skip when files are missing.

4. **Update /py-init SKILL.md** to suggest /dev-init after scaffolding for both new and existing project flows.

5. **Update README.md** with Memory & Dev-Wiki integration documentation, staying within line budget.

## Scope

- `memory_server/` -- vendored MCP memory server (new)
- `install.sh` -- expanded from 3-file copy to 4 actions
- `tests/test_install.sh` -- new test cases for MCP registration
- `templates/.claude/hooks/session-start.sh` -- enhanced context composition
- `templates/.claude/skills/py-init/SKILL.md` -- /dev-init suggestion
- `README.md` -- integration documentation

**NOT in scope:** dev-wiki hooks in templates/.claude/settings.json (deferred), memory_server code changes, fastembed stripping.

## Tasks (5 total: 3S + 2M)

1. **[M]** Vendor memory_server from nanaclaw (copy source, create requirements files)
2. **[M]** Update install.sh to register memory MCP server (copy + JSON merge)
3. **[S]** Enhance session-start.sh (dev-wiki state + memory snapshot reads)
4. **[S]** Update /py-init SKILL.md (add /dev-init suggestion)
5. **[S]** Update README.md (Memory & Dev-Wiki section)

## Key Decisions

- [[vendor-memory-server]]: Self-contained kit, vendor as-is from nanaclaw (no fastembed stripping)
- [[install-sh-scope-expansion]]: install.sh evolves from 3-file copy to 4 actions, DEPENDENCY escape hatch

## Exit Criteria

- [x] memory_server/ vendored with all .py files parsing as valid Python
- [x] install.sh copies memory_server + registers MCP server in settings.json (idempotent)
- [x] session-start.sh reads dev-wiki state and memory snapshot (graceful skip)
- [x] SKILL.md mentions /dev-init
- [x] README documents memory/dev-wiki integration within line budget

## Completion

All 5 tasks done, all exit criteria met. 38 tests pass. READY FOR COMPLETION pending user confirmation.
