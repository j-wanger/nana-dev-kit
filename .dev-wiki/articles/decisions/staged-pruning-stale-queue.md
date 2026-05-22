---
title: Staged pruning to .stale-queue
status: accepted
confidence: high
date: 2026-05-22
source: plan
tags: [working-knowledge, pruning, recoverability]
parents: [phase-17-harden]
---

# Staged pruning to .stale-queue

## Context

working-knowledge.md accumulates entries over phases. Many have `[uses: 1]` and describe facts superseded by later decisions. Without pruning, the file grows unbounded, consuming instruction budget with stale context. Need a mechanism to remove stale entries without losing them permanently.

## Decision

Move stale entries to `.dev-wiki/.stale-queue` instead of deleting them. Pruning criteria: `[uses: 1]` AND entry older than 30 days AND not marked `[pinned]`. Maximum 5 entries pruned per session to limit churn. Entries in .stale-queue can be recovered manually if needed.

## Rationale

- **Recoverability:** Staging to .stale-queue means no data loss. An incorrectly pruned entry can be moved back.
- **Conservative:** Max 5 per session prevents aggressive pruning from removing entries that are actually needed. Over multiple sessions, the file converges to its useful subset.
- **Pinning:** `[pinned]` tag gives users an explicit opt-out for entries they want to keep regardless of age/usage.
- **Alternative rejected:** Direct deletion (irreversible, risky for entries that may still be relevant). Age-only pruning (ignores usage — a frequently-used old entry should stay). Usage-only pruning (a new entry at `[uses: 1]` hasn't had time to prove itself).

## Consequences

- .stale-queue file grows over time (acceptable: it is not loaded into context)
- Pruning is session-scoped — requires session-start.sh to run (no background cron)
- `[pinned]` tag is a new convention for working-knowledge entries
- Entries that age past 30 days but have `[uses: 2+]` are safe (only `[uses: 1]` entries qualify)

## Related

- [[memory-convergence-mcp-only]] — working-knowledge is separate from MCP memory; different lifecycle
