---
title: "Phase 51: Prompt-Type Hooks — Heuristic-Informed Runtime Judging"
aliases: [phase-51-prompt-type-hooks]
category: phases
tags: [heuristic, eval, reasoning, judge, subagent]
parents: []
created: 2026-05-27
updated: 2026-05-27
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/**", "eval/reasoning/**", "wiki/heuristics/**"]
entry_criteria: "Phase 50 completed (8/8 tasks done). 15 heuristic articles with triggers exist. Reasoning eval with 25 scenarios and judge v2 ready."
exit_criteria: "See spec exit criteria (8 items)"
---

# Phase 51: Prompt-Type Hooks — Heuristic-Informed Runtime Judging

## Objective

Build trigger-based heuristic matching and a heuristic-informed approach judge that fires during dev-plan Step 6.5, evaluating reasoning quality against relevant heuristics' criteria. Wire the infrastructure so future phases can add heuristic evolution scoring.

## Scope

Files and modules affected:
- `templates/.claude/skills/dev-plan/**` — heuristic-matcher.md, heuristic-judge-prompt.md, SKILL.md Step 6.5 integration
- `eval/reasoning/**` — selective injection mode, ground-truth mapping, analysis
- `wiki/heuristics/**` — read-only (trigger field extraction)

## Approach

Build in 4 stages: (1) Ground truth mapping + trigger matcher (cheapest falsification first), (2) Plan-adapted judge prompt with exemplars, (3) SKILL.md Step 6.5 integration + run-eval.py --selective mode, (4) Matching analysis + analysis doc. Key constraints: fire-and-forget (judge scores never shown to planner), subagent isolation, 1200-char injection budget, 60s timeout, graceful degradation.

## Decisions

- [[fire-and-forget-heuristic-judge]] — Judge runs isolated, scores used for routing only (Phase 47 negative result)
- [[ground-truth-first-falsification]] — Manual mapping before matcher build, cheapest falsification path

## Exit Criteria

- [ ] `test -f templates/.claude/skills/dev-plan/heuristic-matcher.md`
- [ ] `test -f templates/.claude/skills/dev-plan/heuristic-judge-prompt.md`
- [ ] `grep -q 'heuristic.matcher\|heuristic-matcher' templates/.claude/skills/dev-plan/SKILL.md`
- [ ] `test -f eval/reasoning/selective/ground-truth.json && python3 -c "import json; g=json.load(open('eval/reasoning/selective/ground-truth.json')); assert len(g) >= 25, f'only {len(g)} scenarios'"`
- [ ] `python3 eval/reasoning/run-eval.py --help 2>&1 | grep -q 'selective'`
- [ ] `test -f eval/reasoning/selective/results.json && python3 -c "import json; r=json.load(open('eval/reasoning/selective/results.json')); assert 'scenarios' in r or 'runs' in r, 'missing expected structure'"`
- [ ] `test -f eval/reasoning/traces/phase-51-analysis.md`
- [ ] `make test && make eval`

## Constraints

- Heuristic injection budget: max ~1200 characters combined per judge invocation
- Fire-and-forget: judge scores logged and routed, never shown to planning agent
- Subagent isolation: matcher and judge run as separate Agent subagents
- Latency budget: matcher + judge within 60 seconds combined
- Graceful degradation: skip silently if wiki/heuristics/ missing or empty
- Match cap: top 3 heuristics per invocation

## Checkpoints

- After matcher built: test on 5 eval scenarios, verify appropriate matches
- After selective eval: if negative delta on >50% scenarios, report negative finding
- After Step 6.5 integration: dry-run Phase 52 stub to verify judge fires

## Assumptions

- LLM trigger matching via Agent subagent produces meaningful results. If false: fall back to domain-tag-only matching.
- Judge v2 rubric transfers to planning artifacts with exemplar rewrites. If false: judge mechanism still validates, recalibrate in Phase 7.
- SKILL.md has room (~5 lines). Current: 315/350 lines. If false: extract Step 6.1 to companion first.

## Notes

Spec at specs/phase-51-prompt-type-hooks.md (approved 2026-05-27).
