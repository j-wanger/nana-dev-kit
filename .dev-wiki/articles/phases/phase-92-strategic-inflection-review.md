---
title: "Phase 92: Strategic Inflection Review & Roadmap Re-sequencing"
aliases: [phase-92-strategic-inflection-review]
category: phases
tags: [strategy, objectives, deterministic-vs-llm, roadmap, subtraction]
parents: []
created: 2026-06-18
updated: 2026-06-18
source: plan
status: active
scope: [".dev-wiki/**", ".claude/rules/active-phase.md", "specs/phase-92-memory-layer-prune.md"]
entry_criteria: "Phase 91 delivered (e62e4dd); maintainer called an inflection point"
exit_criteria: "two decision articles present; assumption-ledger --gate + --schema pass for Phase 92; roadmap re-sequenced to 93->94->95; old prune spec carries the re-sequence note"
---

# Phase 92: Strategic Inflection Review & Roadmap Re-sequencing

## Objective

At ~91 phases, re-examine the kit's strengths/limitations and founding objectives, and define the
deterministic-vs-LLM component boundary — grounded in the kit's OWN measured evidence (the amplifier
program), not recollection. Produce a direction decision + a det-vs-LLM principles artifact + a re-sequenced
roadmap. Decisions/docs only — NO implementation code.

## Scope

- `.dev-wiki/**` (the two decision articles, assumption-ledger Phase-92 block, owned `_CURRENT_STATE.md`
  sections, this phase article, index, log, tasks)
- `.claude/rules/active-phase.md` (compaction anchor)
- `specs/phase-92-memory-layer-prune.md` (re-sequence pointer only)

OUT: any implementation code; any memory-layer cut (Phase 95 authority, gated on the Phase-94 re-measure);
reverting/editing d43950f / df3e623 / 75b48af / b8bd416.

## Exit Criteria

- [x] [[strategic-inflection-review]] + [[deterministic-vs-llm-boundary]] articles present with the corrected findings
- [x] `check-assumption-ledger.sh --gate` and `--schema` pass for Phase 92
- [x] `_CURRENT_STATE.md` + `active-phase.md` re-sequenced to Phase 93 -> 94 -> 95
- [x] old `phase-92-memory-layer-prune` spec carries the re-sequence note

## Method

Evidence-grounded review via a 7-agent workflow (5 parallel surveys over skills / hooks / memory / the eval
program / founding objectives -> a synthesis -> an adversarial critique). The critique was the quality gate
and corrected five synthesis overclaims (Ph87 det-beat-reviewers = binary-file confound; "five nulls" = 4
clean + 1 instrument-dead; enforce-memory field evidence ~4:2 toward genuine; the linter-skills size-inflated
~40%; "every measured positive in the deterministic spine" partly circular). The direction (assumption) gate
recorded the two maintainer positions.

## Notes

Two maintainer gate positions (2026-06-18): FRAME = **product for consumers** (rejected instrument-primary);
DIRECTION = **re-measure-once-then-shrink** (NOT the synthesis's "refocus", which smuggled in two unmeasured
build commitments). Re-sequenced roadmap: Phase 93 install.sh re-sync (consumer-serving + re-measure
prerequisite) -> Phase 94 consumer memory re-measure -> Phase 95 memory-layer shrink (supersedes
`specs/phase-92-memory-layer-prune.md`). Det-vs-LLM principles adopted as a maintenance guideline, NOT a
mandate to rewrite the working linter-skills. The full workflow output (surveys + synthesis + critique) is in
the run transcript; the durable distillation lives in the two decision articles.
