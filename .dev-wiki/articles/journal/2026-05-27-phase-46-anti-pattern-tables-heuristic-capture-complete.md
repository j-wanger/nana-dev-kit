---
title: "Phase 46 complete"
aliases: []
category: journal
tags: [anti-patterns, iron-rules, heuristic-capture, eval, dev-debrief]
parents: [phase-46-anti-pattern-tables-heuristic-capture]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 46: Anti-Pattern Tables & Heuristic Capture — Complete

## What Happened
- Extended SCHEMA.md with structured anti-pattern table format (Failure Mode | Detection Signal | Why It Fails), 3-5 rows per heuristic
- Fixed IRON-004 regression on scenario 018 by adding Never clause distinguishing upfront effort from lifecycle complexity — scenario 018 improved +2.67 across 3 runs
- Added anti-pattern tables to all 5 IRON RULES (IRON-001 through IRON-005, 3 rows each)
- Created heuristic-capture.md companion (60 lines) wired into dev-debrief as Step 4.8
- Dev-debrief SKILL.md grew from 312 to 315 lines (safe under 350 ceiling)
- Ran Part A eval checkpoint verifying IRON-004 fix, then full 20-scenario delta measurement
- Scenario 012 consistently regressed -0.67 across all 3 runs — attributed to context dilution from expanded injection payload

## Decisions Made
- [[anti-pattern-table-format-extension|Anti-pattern table format extension]] -- confidence upgraded to high (validated via implementation)
- [[iron-004-lifecycle-complexity-fix|IRON-004 lifecycle complexity fix]] -- confidence upgraded to high (scenario 018 +2.67)

## Problems Solved
- IRON-004 scenario 018 regression -- fixed by distinguishing "less effort now" from "simpler system" via lifecycle complexity measure

## Open Questions
- Scenario 012 consistent regression (-0.67 across all 3 runs) from expanded injection payload — context dilution vs genuine degradation. Not blocking but warrants investigation.
- Strict calibration target (mean < 4.5) still not met (Phase 45: 4.68, Phase 46: ~4.83). Cross-model judging remains the next lever.

## Artifacts Changed
- `wiki/heuristics/SCHEMA.md` (anti-pattern table format definition)
- `wiki/heuristics/IRON-001-measure-before-optimizing.md` through `IRON-005-make-failure-visible.md` (anti-pattern tables added)
- `templates/.claude/skills/dev-debrief/heuristic-capture.md` (new companion, 60 lines)
- `templates/.claude/skills/dev-debrief/SKILL.md` (312->315 lines, Step 4.8 pointer)
- `eval/reasoning/with-anti-patterns/` (new eval condition directory)
- `eval/reasoning/iron-rules-injection-v2.md` (enriched injection text)
- `tests/test_templates.sh` (+5 assertions)

## Related
- [[phase-46-anti-pattern-tables-heuristic-capture|Phase 46: Anti-Pattern Tables & Heuristic Capture]] -- parent phase

## Soft Observations / Phase N+1 Candidates
- Expanded injection payload causes measurable context dilution: scenario 012 consistently dropped from 5/5/5 to 5/4/4 across all 3 runs. Detection signal: when injection text grows, check for non-target scenario regressions. | Injection payload size optimization | Evidence: with-anti-patterns/results.json vs with-iron-rules/results.json
- Self-grading variance inconsistency: Phase 45 showed zero variance across 3 runs (suspiciously deterministic), Phase 46 shows natural score variation. Zero-variance in Phase 45 may be an artifact of identical self-grading paths with smaller injection payload. | Self-grading bias measurement methodology | Evidence: comparing variance patterns across Phase 45 and 46 results
