---
title: Context Injection Budget
tags: [reasoning-pattern, transferable, context-engineering]
created: 2026-05-28
updated: 2026-05-28
source: phase-46-anti-pattern-tables
---

# Context Injection Budget

## Pattern

When injecting supplementary content into an LLM's context at runtime (heuristics, domain knowledge, retrieved articles), the total injection at any single decision point must stay under a dilution threshold. Beyond this threshold, the injected content degrades performance on non-target tasks.

## Evidence

Phase 46 added anti-pattern tables (~400 tokens) to heuristic articles. Scenario 012 consistently dropped from 5/5/5 to 5/4/4 across 3 evaluation runs. The injected content was correct and relevant — the degradation came from context dilution, not content quality.

The established budget: **1200 characters combined** across all injected content at a single decision point. This is approximately 300-400 tokens depending on content density.

## When to apply

Any system that injects retrieved content into an LLM prompt at runtime:
- RAG pipelines injecting retrieved passages
- Heuristic/rule injection into planning prompts
- Memory retrieval results added to conversation context
- Domain knowledge surfaced during decision-making steps

## Trade-offs

- **Too little injection**: agent misses relevant context, makes uninformed decisions
- **Too much injection**: context dilution degrades quality on the primary task
- **Priority ordering matters**: when budget is exceeded, truncate lowest-priority content first. In this project: memory results first, heuristics second, domain wiki last (domain wiki highest priority)

## Example

```
# BAD: inject everything found
inject(heuristic_text + domain_articles + memory_results)  # 3000+ chars

# GOOD: shared budget with priority truncation
budget = 1200
content = prioritize([domain_articles, heuristics, memory_results])
inject(truncate_to_budget(content, budget))
```
