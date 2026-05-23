---
title: "Per-hook stdin JSON field contracts"
aliases: [hook-stdin-per-hook-contracts]
category: decisions
tags: [eval, hooks, fixtures, json, contracts]
parents: [phase-21-eval-expansion]
created: 2026-05-22
updated: 2026-05-22
source: plan
confidence: medium
---

## Context

All 5 uncovered hooks use Python JSON parsing (`python3 -c "import sys,json; ..."`) to read stdin, but they parse different fields. Fixture JSON in eval scenarios must match each hook's actual field access pattern. A uniform schema would simplify corpus authoring but would mask real contract differences.

## Decision

Fixture JSON must match per-hook field paths:
- audit-log.sh, auto-ruff-format.sh, scan-secrets.sh: `{"input":{"file_path":"..."}}`
- block-dangerous-bash.sh: `{"input":{"command":"..."}}`
- check-tests-were-run.sh: `{"tool_uses":[...]}`

This is NOT uniform despite all using `python3` JSON parsing. Each hook's eval scenarios use the correct contract for that hook.

Alternative considered: single schema with all fields present. Rejected because hooks actually parse different fields -- a uniform schema would hide contract mismatches that the eval should catch.

## Consequences

Scenario authors must consult the hook source to determine the correct fixture JSON shape. The eval/schemas/ directory already has per-hook-type schemas from Phase 20 that document these contracts. New scenarios reference those schemas for fixture construction.
