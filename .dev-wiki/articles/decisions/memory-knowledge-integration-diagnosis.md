---
title: "Memory & knowledge subsystems own retrieval engines the harness flow never uses"
aliases: ["memory-knowledge-integration-diagnosis", "wiki-retrieval-regression-root-cause"]
category: decisions
tags: [memory, knowledge-wiki, retrieval, mcp-memory, fts5, context-engineering, diagnosis, ab-testing]
created: 2026-05-29
updated: 2026-05-29
confidence: medium
source: plan
phase: 61
---

# Memory & knowledge subsystems own retrieval engines the harness flow never uses

## The diagnosis (Phase 61 motivation)

Two evidence-grounded findings, one unifying cause.

**1. Wiki-retrieval regression — root cause.** `agentic-engineering-wiki` (1002 files) and `agent-memory-wiki` (2007 files) are registered in `~/.claude/wikis.json`, indexed (each has a `knowledge.db` FTS5/vector store), and on-topic — yet dev-plan never surfaces them. Cause: they are **raw web scrapes** (`raw/` + `knowledge.db`, ~0 absorbed `articles/`, stale `index.md`), and dev-plan Step 2 retrieves by reading `index.md` and scoring **article frontmatter tags/hierarchy** — it never queries the `knowledge.db` search index. Raw scrapes have no frontmatter → score 0 → "0 relevant articles." The retrieval *path* diverged from how the wikis are actually *stored*. The wiki "used to work" when wikis were small + curated (tagged articles); it broke when they became large raw scrapes with a search index the planner doesn't call.

**2. MCP memory is write-mostly.** 20 active entries, all auto-written by the dev-plan memory-bridge + dev-debrief harvest, but the only automatic read is `wiki-query` (rare) + the bridge's own dedup. session-start *nudges*, never `memory_search`es. Meanwhile working-knowledge.md (always-loaded `.claude/rules/`) is the layer doing the real work — but its `uses` counter increments on re-seeding, not reads (87/100 at `[uses:1]`), so what's load-bearing is unmeasured.

## Unifying cause

**Both subsystems own a real retrieval engine (wiki `knowledge.db`; MCP FTS5) that the harness flow doesn't use.** The layers that work are the always-loaded markdown ones (working-/active-knowledge, dev-wiki) — *because they're always in context*. The search-gated layers underperform because retrieval is voluntary/conditional and rarely fires. This is the project's own principle reflected back: *context shaping (what each component sees) beats instructions; strengthen always-loaded activation points.*

## Why this is A/B-gated, not a build

"Integrate" = wire the engines into the flow (Step 2 calls wiki search; the flow `memory_search`es; optionally via a retrieval-subagent firewall). But this is NOT a foregone win: [[cut-active-research-step-2-7]] measured retrieval injection **net-negative** when parametric knowledge is strong (commodity, well-documented topics). The candidate wikis are **raw scrapes of commodity web content** — the exact net-negative profile. Phase 59 left the weak-parametric/proprietary case UNTESTED; Phase 61 tests precisely that boundary, falsification-first behind a wiki-signal-quality gate, so a Phase-59-redux null kills it cheap rather than shipping a harmful integration.

## Implication

- The fix for the wiki regression and the memory-integration question converge: use the actual retrieval engines, validated by A/B.
- The deterministic step-renumber (whole-number harness steps) is walled off from the A/B per [[deterministic-success-over-eval-ceremony]].
- Decided directions ship in Phase 62; Phase 61 only measures + decides.

## Related

- [[cut-active-research-step-2-7]] — retrieval net-negative on strong-parametric content (the risk this phase must clear)
- [[measure-residual-research-delta]] / [[pre-registered-keep-trim-cut-measurement]] — the A/B methodology reused
- [[measurement-fan-out-as-workflow]] — execution mechanism for the fan-out
- [[deterministic-success-over-eval-ceremony]] — why the step-renumber needs no A/B
