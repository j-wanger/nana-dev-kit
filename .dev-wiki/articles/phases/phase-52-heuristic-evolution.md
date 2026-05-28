---
title: "Phase 52: Heuristic Evolution — Counter Scoring, Deprecation Lifecycle, Dashboard"
aliases: [phase-52-heuristic-evolution]
category: phases
tags: [heuristic, evolution, scoring, deprecation, dashboard]
parents: []
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/**", "scripts/heuristic-dashboard.py", "wiki/heuristics/**", "eval/corpus/**", "tests/test_heuristic_evolution.sh"]
entry_criteria: "Phase 51 completed (7/7 tasks done). Heuristic judge fires at Step 6.5. 15 heuristic articles with helpful/harmful counters at 0. Ground-truth mapping (25 scenarios, 84% coverage) exists."
exit_criteria: "Counter + lifecycle companions exist, SKILL.md pointer, dashboard + make target, SCHEMA.md lifecycle section, tests (8 assertions pass), 2 eval scenarios, roadmap Phase 7 DONE, make test + make eval pass."
---

# Phase 52: Heuristic Evolution — Counter Scoring, Deprecation Lifecycle, Dashboard

## Objective

Build the heuristic evolution feedback loop: judge verdicts from Step 6.5 flow back to update helpful/harmful counters on matched heuristic articles, trigger deprecation lifecycle transitions, and power an analysis dashboard. Final phase (7/7) of the cognitive enhancement roadmap.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/**` — heuristic-counter-update.md, heuristic-lifecycle.md, SKILL.md pointer
- `scripts/heuristic-dashboard.py` — new dashboard script
- `wiki/heuristics/**` — SCHEMA.md update (lifecycle rules), counter targets
- `eval/corpus/**` — new eval scenarios for counter and lifecycle
- `tests/test_heuristic_evolution.sh` — new test file
- `Makefile` — dashboard and test targets

## Approach

Three-stage build:
1. **Counter infrastructure** — heuristic-counter-update.md companion (~35 lines, attribution rules: helpful on judge score>=6/10, harmful on judge<=4/10 AND reviewer>=6/10, no-update at 5, Edit-based YAML updates, fail-open) + heuristic-lifecycle.md companion (~25 lines, active->under-review at ratio>0.3 AND total>=5, iron immune, deprecated terminal) + SKILL.md Step 6.5 pointer (~3 lines).
2. **Dashboard** — scripts/heuristic-dashboard.py (~70 lines, reads wiki/heuristics/*.md, YAML regex parsing, terminal table, zero-counter handling, never-matched surfacing, id-keyed) + make dashboard target.
3. **Tests/eval/docs** — test_heuristic_evolution.sh (8 assertions), 2 eval scenarios, SCHEMA.md lifecycle section, roadmap update.

## Decisions

- [[counter-attribution-uniform-global-verdict]] — Single judge verdict applies uniformly to all matched heuristics. Known approximation; per-heuristic attribution requires judge prompt changes (out of scope). Confidence: medium.

## Exit Criteria

- [x] `test -f templates/.claude/skills/dev-plan/heuristic-counter-update.md`
- [x] `test -f templates/.claude/skills/dev-plan/heuristic-lifecycle.md`
- [x] `grep -q 'heuristic-counter-update' templates/.claude/skills/dev-plan/SKILL.md`
- [x] `test -f scripts/heuristic-dashboard.py && python3 scripts/heuristic-dashboard.py --help 2>&1 | grep -qi 'heuristic\|dashboard'`
- [x] `grep -q '^dashboard' Makefile`
- [x] `bash tests/test_heuristic_evolution.sh` (8 assertions)
- [x] `grep -qi 'lifecycle' wiki/heuristics/SCHEMA.md`
- [x] `grep -q '\*\*DONE\*\*' .dev-wiki/articles/roadmap-cognitive-enhancement.md`
- [x] `make test && make eval`

## Constraints

- Counters are retrospective analytics, NOT selection signals. Matcher must NOT read counters.
- IRON rules immune to deprecation lifecycle transitions. Counters accumulate for observability only.
- Global verdict attribution: single judge verdict to all matched heuristics (up to 3).
- Minimum sample size: deprecation threshold requires helpful + harmful >= 5.
- SKILL.md budget: 316/350 lines. Companion files with <=3-line pointers.

## Checkpoints

- After counter companion: verify YAML round-trip with synthetic heuristic file.
- After lifecycle companion: test threshold at 2/5 (fires) and 1/4 (does not fire) and iron (never fires).
- After dashboard: verify all 15 heuristics covered, zero-counter handling, id-keyed output.

## Assumptions

- YAML frontmatter can be reliably read-modify-written by orchestrator (Read + Edit tools).
- Single-verdict judge output sufficient for counter attribution.
- SKILL.md has room for ~3 lines at Step 6.5.
- Dashboard uses Python 3 stdlib only (regex YAML parsing, no PyYAML).
