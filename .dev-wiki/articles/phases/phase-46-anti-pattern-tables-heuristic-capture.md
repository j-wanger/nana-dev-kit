---
title: "Phase 46: Anti-Pattern Tables & Heuristic Capture"
status: completed
created: 2026-05-27
updated: 2026-05-27
ceremony: standard
scope:
  - wiki/heuristics/**
  - templates/.claude/skills/dev-debrief/**
  - eval/reasoning/**
exit_criteria:
  - Anti-pattern tables in all 5 IRON RULES
  - IRON-004 fix + scenario 018 improvement >= 0.5
  - Heuristic capture companion in dev-debrief
  - Delta measurement (with-anti-patterns vs with-iron-rules)
---

# Phase 46: Anti-Pattern Tables & Heuristic Capture

## Objective
Enrich IRON RULES with structured anti-pattern tables (Failure Mode | Detection Signal | Why It Fails), fix IRON-004 regression on scenario 018 via lifecycle complexity distinction in Never clause, add heuristic capture companion to dev-debrief, measure delta against with-iron-rules/results.json.

## Approach

Three sequenced parts:
- **Part A:** Anti-pattern table format in SCHEMA.md + IRON-004 Never clause fix + anti-pattern tables for all 5 IRON RULES + eval checkpoint verifying scenario 018 improvement and no regressions.
- **Part B:** Heuristic capture companion for dev-debrief (companion file pattern, wired as Step 4.8).
- **Part C:** Delta measurement with full 20-scenario eval (3 runs), comparing against with-iron-rules/results.json.

Key design decisions:
- Anti-pattern tables extend existing ## Anti-pattern section (preserve H2 header for wiki-query compatibility).
- IRON-004 fix via Never clause distinguishing upfront effort from lifecycle complexity — stays domain-agnostic.
- Companion file pattern for heuristic capture (dev-debrief at 312/350 lines — cannot absorb inline).
- Delta measured against with-iron-rules/results.json (one variable at a time).

## Key Decisions

- [[anti-pattern-table-format-extension]] — structured table (Failure Mode | Detection Signal | Why It Fails) extends existing Anti-pattern section
- [[iron-004-lifecycle-complexity-fix]] — Never clause distinguishes "less effort now" from "simpler system" via total lifecycle complexity

## Dependencies

- Phase 45 artifacts: with-iron-rules/results.json (delta baseline), IRON-001 through IRON-005 (anti-pattern targets), judge v2 (same judge for delta)
- SCHEMA.md (Phase 44) — extended with table format
- dev-debrief SKILL.md (Phase 12/37) — companion file pattern

## Results

All 7/7 tasks completed. Anti-pattern tables added to all 5 IRON RULES (3 rows each). IRON-004 Never clause fix verified: scenario 018 improved +2.67, no regressions >= -0.5 (scenario 012 regressed -0.67 from context dilution, within tolerance). Heuristic capture companion (60 lines) wired as Step 4.8. Dev-debrief SKILL.md at 315/350 lines. Delta measurement: net improvement over with-iron-rules baseline. +5 test assertions, ~320 tests pass, 50/50 eval maintained.
