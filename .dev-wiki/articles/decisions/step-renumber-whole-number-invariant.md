---
title: "Whole-number gap-free Step headings across lifecycle SKILL templates, test-enforced"
aliases: ["step-renumber-whole-number-invariant", "step-renumber", "step-numbering-continuity"]
category: decisions
tags: [dev-plan, dev-debrief, spec, skill-templates, refactor, test-invariant, deterministic]
parents: [phase-61-validate-memory-knowledge-integration]
created: 2026-05-29
updated: 2026-05-29
source: debrief
confidence: high
---

## Context

The three lifecycle skill templates (dev-plan, dev-debrief, spec) had accreted decimal-step creep (`2.5`, `6.5`) and alpha-postfix steps (`6a`, `12d`) across Phases 8–60 as features were inserted between existing steps. The numbering had become non-sequential and hard to reference. This was a deterministic/mechanical change, explicitly walled off from the Phase 61 A/B ([[deterministic-success-over-eval-ceremony]]: structural assertions + firing tests are the rigorous validator for mechanical changes, not a judge eval).

## Decision

**Renumber every `## Step N` heading to whole-number, gap-free 1..N per template, and codify the invariant as a test.** Result: dev-plan → 1..18, dev-debrief → 1..26 (cross-file: Steps 18, 23, 24, 25 live in `debrief-finalization.md`), spec → 1..9. All gap-free, no decimals, no alpha postfixes on main Step headings. ~200 reference edits across the 3 skill dirs + ~15 companions (including `referenced_at:` companion frontmatter). New `tests/test_step_numbering.sh` (6 assertions: no-decimal + gap-free 1..N per template) wired into `make test` (12th script).

A full ref-integrity audit was run, not just heading checks — it caught a partial-token corruption (`Step 2/2.5` → `Step 4/2.5`) that the heading-only success criterion would have shipped green. Pre-existing approximations were left as-is (out of scope): the dev-plan orchestrator-overview "(Steps 9–14)" still approximates the inline span (actually 9–15), kept equivalently approximate to its prior "(Steps 5–7)".

Alternative rejected: validate via judge A/B (a byte-level renumber has no judgeable quality delta — a judge would launder variance, not measure signal).

## Consequences

- Future Step insertions must keep whole-number gap-free numbering; `tests/test_step_numbering.sh` fails otherwise.
- `make test` is now 12 scripts (+6 assertions); README "~340 tests across 12 scripts" count synced.
- Lesson surfaced (candidate `/wiki-capture`): a mechanical token-renumber needs a full ref-integrity audit, not a heading-only check — partial-token corruption passes a heading-only gate.
