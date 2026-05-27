---
title: "Phase 47: Self-Dialogue in Dev-Plan"
aliases: [self-dialogue, devil-advocate-reasoning]
category: phases
tags: [reasoning, self-dialogue, dev-plan, eval, heuristics]
parents: [cognitive-enhancement-plan]
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/*", "eval/reasoning/*", "tests/test_templates.sh"]
entry_criteria: "Phase 46 completed (7/7 tasks done)"
exit_criteria: "self-dialogue-prompt.md exists, SKILL.md references it and stays <= 350 lines, eval delta >= 0.5 on differentiating scenario, no regression > 1.0, make test + make eval pass"
---

# Phase 47: Self-Dialogue in Dev-Plan

## Objective

Add structured self-dialogue (devil's advocate reasoning) to dev-plan approach formulation via clean-context subagent with heuristic-armed counterarguments. Measure reasoning quality delta via existing eval pipeline with dual-condition comparison: inline (A) vs subagent (B).

## Scope

Files and modules affected:
- `eval/reasoning/self-dialogue-injection.md` (new eval inline protocol)
- `templates/.claude/skills/dev-plan/self-dialogue-prompt.md` (new production companion)
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 6.0.5 pointer)
- `eval/reasoning/with-self-dialogue-inline/` (condition A results)
- `eval/reasoning/with-self-dialogue-subagent/` (condition B results)
- `eval/reasoning/README.md` (updated results)
- `tests/test_templates.sh` (new assertions)

## Approach

4-stage build order: (1) write protocol artifacts, (2) inline eval condition A, (3) subagent eval condition B, (4) wire production. Measure before building (IRON-001). Both conditions share core mechanic: generate 2-3 counterarguments citing IRON RULE IDs, resolve each, 200-word budget.

## Exit Criteria

- [ ] self-dialogue-prompt.md companion exists (~40-50 lines)
- [ ] self-dialogue-injection.md exists for eval mode (~30-40 lines)
- [ ] SKILL.md references self-dialogue and stays <= 350 lines
- [ ] Condition A: 3-run eval in with-self-dialogue-inline/results.json
- [ ] Condition B: 3-run eval in with-self-dialogue-subagent/results.json
- [ ] Delta >= 0.5 on at least one differentiating scenario (012, 014, 018) in at least one condition
- [ ] No scenario regression > 1.0; scenario 012 mean >= 4.0 in both conditions
- [ ] make test passes; make eval Score 100%

## Constraints

- SKILL.md ceiling: 350 lines (currently 309) — companion file pattern required
- Self-dialogue max 200 words total output — prevents context dilution
- Each counterargument must cite IRON RULE by ID — prevents performativity
- Self-dialogue output resolved before Step 6.5 — approach reviewer gets clean input
- Fail-open: if subagent lacks IRON RULE citations, discard and proceed

## Decisions

- [[self-dialogue-dual-condition-eval]] — medium confidence, test both inline and subagent to isolate whether clean-context separation adds value

## Notes

Phase 4 of 7 in cognitive enhancement roadmap (Phases 44-50). Prior art: adversarial-constraints-prompt.md in spec/ skill uses clean-context subagent pattern. T0 thinking protocol is inline pre-proposal; approach reviewer is post-proposal quality audit. Self-dialogue fills the gap: post-proposal adversarial critic armed with heuristics.
