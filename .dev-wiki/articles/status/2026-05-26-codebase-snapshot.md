---
title: "Codebase Snapshot 2026-05-26"
aliases: []
category: status
tags: [snapshot]
parents: []
created: 2026-05-26
updated: 2026-05-26
source: debrief
---

# Codebase Snapshot — 2026-05-26

## Metrics

| Metric | Value |
|--------|-------|
| Total files | ~2,096 |
| Hook scripts | 19 |
| Skill directories | 26 |
| Automated tests | ~303 |
| Eval scenarios | 50 (100%) |
| VERSION | 0.5.0 |
| Phases completed | 42 |

## Recent Commits

- `9153408` Phase 41: Harness Hardening & Process Safeguards
- `7310391` Phase 40: install.sh Extraction & Anti-Pattern Hardening
- `92f26b7` Phase 39: Resilience & Health Probes
- `ef91738` Fix detect-loop.sh exit 1 on empty/non-Bash PostToolUse input
- `c9d7a48` Fix upsert to update matchers on existing hooks

## Phase 42 Additions

- `eval/comparison/` — harness effectiveness comparison framework
- 3 setup scripts (baseline, context, harness) + metrics collection + hook wrapper
- 2 starter codebases (feature-build, bug-fix) + frozen task definitions
- Methodology document with controls, scoring rubric, limitations
- Results from 3-condition comparison (A: bare, B: context, C: full harness)

## Known Issues

- MEDIUM: ci.yml hardcodes `src/` for mypy
- LOW: wiki-index ships Python files alongside .md
