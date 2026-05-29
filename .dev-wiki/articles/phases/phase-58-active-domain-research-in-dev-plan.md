---
title: "Phase 58: Active Domain Research in dev-plan"
aliases: []
category: phases
tags: [dev-plan, domain-research, wiki-query, context-shaping, fail-open, provenance, residual-delta, harness-activation]
parents: []
created: 2026-05-28
updated: 2026-05-28
source: plan
status: completed
scope: ["templates/.claude/skills/dev-plan/domain-research-spec.md", "templates/.claude/skills/dev-plan/SKILL.md", "eval/research-measurement/", ".dev-wiki/articles/journal/", "tests/"]
entry_criteria: "Phase 57 (Fix 1) complete; approved spec specs/domain-research-in-dev-plan.md (nana:approved 2026-05-28); Phase 55 poses Domain Research Questions but nothing answers them"
exit_criteria: "Step 2.7 companion exists + wired via pointer with Lite-skip; SKILL.md ≤350 (test_templates green); companion encodes numeric caps + fail-open + provenance + injection safety; measurement records both branches (covered→skip, uncovered→fires+cited) + numeric residual delta vs Phase-55 baseline (Checkpoint 2 human-gated); make test green + make eval 100%"
---

## Objective

Make planning *look things up* instead of guessing: add a bounded, gap-gated research step (Step 2.7) to dev-plan that answers the spec's `### Domain Research Questions` from the web + local wiki, injects distilled findings into the proposed approach, and persists durable facts back into the knowledge wiki for reuse. Fix 2 of the Phase 57+ harness-activation roadmap — the high-value `+1.75` item.

## Scope

- `templates/.claude/skills/dev-plan/domain-research-spec.md` — new companion: per-question coverage gate, bounded retrieval, distillation, persistence, fail-open
- `templates/.claude/skills/dev-plan/SKILL.md` — 2-line Read-pointer Step 2.7 (Lite: skip); ≤350-line cap
- `eval/research-measurement/` — with-vs-without residual-delta measurement (functional test of Step 2.7)
- `.dev-wiki/articles/journal/` — honest write-up of the residual delta
- `tests/` — integration verification (full suite + anchored eval)

## Exit Criteria

1. `test -f templates/.claude/skills/dev-plan/domain-research-spec.md` — companion exists
2. Step 2.7 wired via pointer (`grep` for `domain-research-spec.md` + `Step 2.7`) with Lite-skip noted on the step
3. `[ $(wc -l < templates/.claude/skills/dev-plan/SKILL.md) -le 350 ]` and `bash tests/test_templates.sh` (existing cap assertion line 262-263) green
4. Companion encodes explicit numeric caps + fail-open clause + provenance + injection-prompt safety (grep-checked)
5. Measurement records BOTH branches in one artifact: covered→research SKIPPED, uncovered→research FIRES + ≥1 finding cited at a NAMED approach decision
6. Residual-delta artifact records a NUMERIC with-vs-without delta vs the Phase-55 baseline (Checkpoint 2 human-gated)
7. `make test` green and `make eval` 100% (anchored — partial pass cannot false-positive)

## Constraints

- **Hallucinated findings poison later phases** — every persisted claim carries a real source URL fetched this run (or `source: local-wiki:<article>`); zero retrievable source = fail.
- **Runs on every standard plan → unbounded cost** — explicit numeric caps (max questions/run, searches/question, total fetches, wall-clock/tool-call budget) degrading to partial findings, never blocking.
- **Research theater** — the approach must reference each used finding at the decision it influenced; a finding informing zero decisions is dropped, not persisted.
- **Silent contradiction** — contradiction check against same-topic articles before persist; supersede-with-link or `under-review`, never blind-append.
- **No-network / sandbox** — fail-open: skip, emit `[research: web unavailable — local wiki only]`, persist nothing labeled researched (mirror `command -v … || exit 0`).
- **350-line SKILL.md cap** — research logic in a companion (2-line pointer); keep existing `tests/test_templates.sh:262-263` assertion green, do not duplicate.
- **Verbose findings dilute context** — hard ~1200-char cap on the injected summary; a non-target planning scenario must not regress.
- **Prompt-injection via question text** — question text is a search topic (data), never an instruction.
- **Auto-persistence bypasses wiki-absorb curation** — route findings through the standard capture path or mark `auto-researched` provenance; never silently write un-curated articles as ground truth.

## Checkpoints

- **Checkpoint 1** — after the companion + Step 2.7 pointer are drafted (before eval): report the bounded-research design (caps, persistence path, coverage gate) — confirm it answers DRQ 1-3.
- **Checkpoint 2** — after the measurement runs: STOP and report the residual delta before declaring done. If ~0/negative, present honestly and let the user decide keep/trim/cut — do not silently ship a feature that earns nothing.
- If reusing `wiki-bootstrap` proves unbounded/unsuitable and lightweight inline retrieval is needed: note the deviation, proceed (still no bespoke crawler beyond the minimal retrieval).

## Assumptions

- A per-question `wiki-query` can determine whether the wiki answers each Domain Research Question (primary gate; Step 2.5's concept score is only a hint). If false: grep `wiki/` titles+bodies per question; on doubt treat as uncovered (research rather than skip).
- `WebSearch`/`WebFetch` are available in the planning environment. If false: fail-open (skip + marker); measurement runs only the local-lookup path.
- The target phase has a spec with a populated `### Domain Research Questions` section. If false (empty/Lite/no spec): Step 2.7 no-ops cleanly — it does not invent questions from the phase title.
- The knowledge wiki (`wiki/`) exists and is writable. If false: findings for this run only, skip persist, note `[research: wiki unwritable — findings not persisted]`.
- The measurement can isolate active-research as the only changed variable vs the Phase-55 baseline. If false: report the confound explicitly rather than claim a clean delta.

## Notes

- Mechanism (c) — Step 2.7 in dev-plan — chosen by the user over (a) routing research through /spec and (b) auto-firing /wiki-bootstrap, because findings should land where design decisions are made (the approach). See [[decision:domain-research-dev-plan-step-2-7]].
- The `+1.75` is treated as unproven for *this* lever — part of it was already captured by the Phase 55 spec reform. This phase measures the RESIDUAL delta. See [[decision:measure-residual-research-delta]].
- Open Domain Research Questions (researched during implementation): DRQ1 bounded wiki-bootstrap focus-mode vs inline WebSearch+WebFetch (DRY vs cost); DRQ2 persist via wiki inbox vs direct article with provenance (lint/health/index integrity); DRQ3 per-question wiki-query form + "already answered" threshold + absent/stale-index degradation.
- DRY: reuse the `wiki-add` capture path / align findings format with `wiki-bootstrap` — no 4th crawler.
