---
title: "jq as hard dependency for eval runner"
aliases: [eval-jq-hard-dependency]
category: decisions
tags: [eval, dependencies, jq, json]
parents: [phase-20-eval-harness]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: medium
---

## Context

The eval runner needs to parse JSON scenario manifests. Hook inputs are already JSON. Two options: jq (purpose-built, composable) or Python json.tool fallback (already available via memory_server venv).

## Decision

Hard fail with actionable install hint if jq is missing. jq is the natural tool for JSON manifest parsing: hook inputs embed JSON payloads directly, jq filters compose cleanly in bash pipelines, and jq is widely available on developer machines.

Alternative considered: Python json.tool fallback -- rejected because it adds a second parsing path, complicates error handling, and the eval harness is meant to be pure bash (consistent with existing test infrastructure).

## Consequences

Eval runner has a new dependency not required by `make test`. The runner checks `command -v jq` at startup and exits non-zero with an install hint. This is the first hard external dependency beyond bash/python3 in the kit.
