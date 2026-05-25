---
title: "Fail-loud over fail-silent for memory MCP failures"
aliases: [fail-loud-memory, memory-fail-loud]
category: decisions
tags: [memory, mcp, observability, hooks]
parents: [phase-38-install-integrity-functional-verification]
created: 2026-05-25
updated: 2026-05-25
source: debrief
confidence: high
---

## Context

Six files across the kit silently swallowed MCP memory server failures -- memory_store calls wrapped in try/except with pass, memory_search returning empty on error, session-start skipping memory guidance without warning. This masked the CWD bug for 33 phases.

## Decision

Changed all 6 files from silent skip/fail-open to visible warnings with diagnostic hints when MCP memory server is unreachable. session-start.sh gains an MCP health check that verifies the server can be imported from the configured CWD. memory-nudge.sh warns when MCP is registered but no database exists.

Files changed: install.sh, session-start.sh, memory-nudge.sh, memory-harvest.md, memory-bridge.md, spec/SKILL.md, wiki-query/SKILL.md.

Alternatives considered:
- Hard-fail (exit 2) on memory unavailable: rejected because memory is optional in many workflows; blocking would break non-memory users.
- Keep fail-silent but add logging: rejected because logs are rarely checked; stderr warnings are immediately visible.

## Consequences

- Memory failures are now visible in session output, enabling faster diagnosis.
- Fail-open behavior preserved (hooks exit 0, skills continue without memory) but with clear warnings.
- Trade-off: slightly noisier output when memory is intentionally not configured. Acceptable because the warning includes a hint for how to resolve.
