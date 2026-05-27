---
title: "Phase 47 complete — Self-Dialogue in Dev-Plan (negative result)"
aliases: []
category: journal
tags: [self-dialogue, reasoning, eval, negative-result, dev-plan, iron-rules]
parents: [phase-47-self-dialogue-in-dev-plan]
created: 2026-05-27
updated: 2026-05-27
source: debrief
---

# Phase 47: Self-Dialogue in Dev-Plan — Negative Result

## What Happened
- Added self-dialogue (devil's advocate with IRON RULE citations) to dev-plan approach formulation
- Wrote eval protocol (self-dialogue-injection.md, 33 lines) and production companion (self-dialogue-prompt.md, 46 lines)
- Added Step 6.0.5 to dev-plan SKILL.md (309 to 315 lines, 35 lines remaining under 350 cap)
- Ran 6 eval runs: 3 inline (condition A), 3 subagent (condition B) against 20 reasoning scenarios
- **Negative result**: self-dialogue does not improve reasoning quality. Inline is net negative, subagent is net neutral
- Created cognitive enhancement roadmap artifact tracking 7-phase plan (4/7 done after this phase)

## Decisions Made
- [[self-dialogue-dual-condition-eval|Self-Dialogue Dual-Condition Eval]] — medium confidence, validated by running both conditions

## Problems Solved
- None (this was an exploration phase with clean execution but negative finding)

## Open Questions
- Scenario 012 context dilution (-0.67 from Phase 46) persists — still unresolved, not blocking
- Strict calibration target (mean < 4.5) still not met — cross-model judging remains next lever
- IRON RULES "surface reading" failure: IRON-004/005 override domain reasoning on scenarios 015/020 — needs heuristic selection investigation

## Artifacts Changed
- `eval/reasoning/self-dialogue-injection.md` (new, 33 lines — eval inline protocol)
- `templates/.claude/skills/dev-plan/self-dialogue-prompt.md` (new, 46 lines — production companion)
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 6.0.5 added, 309 to 315 lines)
- `eval/reasoning/with-self-dialogue-inline/results.json` (new — condition A, 3 runs x 20 scenarios)
- `eval/reasoning/with-self-dialogue-subagent/results.json` (new — condition B, 3 runs x 20 scenarios)
- `eval/reasoning/README.md` (updated with both conditions and negative result)
- `.dev-wiki/articles/roadmap-cognitive-enhancement.md` (new roadmap tracking artifact)
- `tests/test_templates.sh` (+4 assertions, 158 total)

## Related
- [[phase-47-self-dialogue-in-dev-plan|Phase 47: Self-Dialogue in Dev-Plan]]
- [[roadmap-cognitive-enhancement|Cognitive Enhancement Roadmap]]

## Soft Observations / Phase N+1 Candidates
- IRON RULES "surface reading": IRON-004 pushes toward rewrite on 015 (auth risk should override), IRON-005 pushes toward CVE fix on 020 (force multiplier insight should win). 3/3 inline runs flipped 015, 0/3 subagent runs flipped 015 | next lever: heuristic selection (matching rules to scenario types) | evidence: eval results in with-self-dialogue-inline/ and with-self-dialogue-subagent/
- Self-dialogue adds hedging not depth: devil's advocate generates shallow counterarguments without novel insights | implication: technique is architecturally sound but content-empty when same-context agent plays both sides | evidence: 6 eval runs across 2 conditions
- Next cognitive enhancement lever is heuristic selection (which rules to apply when), not heuristic application (forcing rules as counterargument ammunition) | evidence: negative result from Phase 47

### Health Delta
- Tests: +4 assertions (158 total), all pass
- Eval: 50/50 (unchanged)
- SKILL.md: 309 to 315 lines (6 net added, 35 remaining under 350 cap)
- Companion files: 94/94 pass validation (was 93 — new self-dialogue-prompt.md)
- Eval results: 2 new conditions (inline + subagent), negative result documented
