---
title: "Phase 61 complete — Memory & Knowledge Integration A/B (all 5 directions CUT) + step-renumber"
aliases: ["phase-61-complete", "memory-integration-ab-complete"]
category: journal
tags: [memory, knowledge-wiki, retrieval, ab-testing, mcp-memory, hot-cache, step-renumber, context-engineering]
parents: [phase-61-validate-memory-knowledge-integration]
created: 2026-05-29
updated: 2026-05-29
source: debrief
duration: ~3-4 hours (post-compaction estimate; marathon session resumed from 2/7 checkpoint)
---

# Phase 61 complete — Memory & Knowledge Integration A/B + deterministic step-renumber

## What Happened

Resumed Phase 61 from the 2/7 banked checkpoint (T1 signal-gate+pre-reg and T2 wiki-search-D1-CUT done prior session) and drove the remaining 5 tasks to completion. Experiment-first: decide by pre-registered A/B which memory/knowledge-retrieval integrations earn a place in the harness flow, defer the build to Phase 62.

- **T3 — D2 (MCP memory_search read-path) measured A/B → CUT.** Cheapest-first store inventory falsified the "pruned tail" hypothesis by inspection: the MCP store is 20 entries (bridge/harvest channel), a strict SUBSET of the ~90-entry always-loaded `working-knowledge.md` (same pipeline feeds both). Ran the best-case A/B anyway (user asked for measurement, not prior): mean(A)=9.33, mean(B)=9.33, **delta=0.00** (decision −0.33, reasoning +0.33 — a wash), variance-dominated. Non-zero cost (memory_search round-trip + ~175 tokens) for zero lift ⇒ net-negative ⇒ burden-of-proof cut. Cleanest "redundant retrieval" signature: B = A + (subset of A) ⇒ Δ→0.
- **T4 — D3 architecture → 2-tier (curate-into-hot-cache); D4 moot.** No 3rd runtime-retrieved store tier. Derived from D1 (−0.67) + D2 (0.00) nulls. D4 (absorb-vs-search-raw) subsumed by the D1 cut + T1 signal gate.
- **T5 — aggregate + per-direction keep/cut + Phase-62 build list.** All five runtime-retrieval directions (D1–D5) measured net-zero-or-negative. The load-bearing positive: the always-loaded hot cache IS the effective retrieval layer.
- **T6 — deterministic step-renumber.** dev-plan → 1..18, dev-debrief → 1..26 (cross-file: Steps 18/23/24/25 in `debrief-finalization.md`), spec → 1..9; gap-free, no decimals/postfixes. ~200 ref edits across 3 skill dirs + ~15 companions. New `tests/test_step_numbering.sh` (6 assertions), wired into `make test` (12th script). A full ref-integrity audit caught a partial-token corruption (`Step 2/2.5`→`Step 4/2.5`) the heading-only criterion would have shipped green.
- **T7 — regression gate.** make test 12/12 scripts green; make eval 54/54 (100%); test_companions green (renumbered `referenced_at:` frontmatter consistent). No non-target regression.

All 7 Phase-61 tasks marked [x]. Direction gate was approved prior session; delivery gate is this debrief.

## Decisions Made

- [[cut-mcp-memory-read-path-d2|CUT the MCP memory_search read-path into planning (D2)]] -- delta=0.00, store ⊂ hot cache, net-negative after cost
- [[two-tier-curate-into-hot-cache|2-tier architecture: curate-into-hot-cache, no 3rd runtime tier (D3)]] -- derived from D1+D2 nulls
- [[hot-cache-is-the-effective-retrieval-layer|The always-loaded markdown hot cache IS the effective retrieval layer]] -- load-bearing meta-finding
- [[step-renumber-whole-number-invariant|Whole-number gap-free Step headings, test-enforced (T6)]] -- ~200 ref edits, 12th test script

## Problems Solved

- "Should we wire the real retrieval engines into planning?" -- answered NO by measurement: the hot cache already supplies the relevant knowledge, so runtime retrieval is redundant-at-best (D2 Δ=0) / diluting-at-worst (D1 Δ=−0.67).
- Decimal/postfix step-numbering creep across 3 lifecycle templates -- renumbered to whole-number gap-free, codified as a test invariant so it can't silently re-accrete.

## Open Questions

- D2 re-test trigger (deferred): if the MCP store ever grows past the hot-cache 100-entry cap with valuable DISTINCT entries, re-run the D2 A/B (memory_search as overflow recall). Concrete numeric trigger, not a present feature.
- Weak-parametric + properly-absorbed + covered sweet spot remains UNTESTED (would require building the absorb pipeline + a non-commodity corpus first). Same caveat as Phase 59. Separate future call.

## Artifacts Changed

- `eval/memory-integration/results.md` (+T3/T4/T5: D2 A/B + verdict, D3 2-tier + D4-moot, aggregate per-direction keep/cut + Phase-62 build list)
- `templates/.claude/skills/dev-plan/SKILL.md` (steps renumbered 1..18)
- `templates/.claude/skills/dev-debrief/SKILL.md` (steps renumbered 1..26; cross-file with debrief-finalization.md)
- `templates/.claude/skills/spec/SKILL.md` (steps renumbered 1..9)
- ~15 companion files across the 3 skill dirs (`Step N` refs + `referenced_at:` frontmatter renumbered)
- `tests/test_step_numbering.sh` (NEW — 6 assertions, no-decimal + gap-free per template)
- `Makefile` (test target → 12 scripts), `README.md` (test count synced)

## Related

- [[phase-61-validate-memory-knowledge-integration|Phase 61: Validate Memory & Knowledge Integration]] -- parent phase
- [[cut-active-research-step-2-7|Phase 59 CUT]] -- D1 is Phase-59-redux confirmed by measurement
- [[memory-architecture-classification|Memory architecture 5-layer classification]] -- the meta-finding validates "strengthen always-loaded .claude/rules/ activation points" with measured evidence

## Retro Check (Phases 51-60)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 1 (memory venv broke recurrently P56-58, root-caused + fixed P58: optional sqlite-vec absent + test hard-failing instead of skipping) | low |
| 2. Decision Reversals | 1 (Phase 58 shipped active-research Step 2.7 → Phase 59 CUT it; a healthy measurement-caught reversal, the pre-registered method working as designed) | low |
| 3. User Corrections | 0 systemic (the recurring "USER OVERRIDE" notes are a documented standing preference — autonomous phase execution + direction-gate waiver — not corrections) | none |

Recommendations:
- No systemic issues. The one recurring blocker (memory venv) is resolved with a durable guard ([[guard-optional-dep-tests]]); the one reversal is the burden-of-proof measurement method catching its own n=1 false positive, which is the intended behavior, not a reliability gap.

## Soft Observations / Phase 62 Candidates

- **Phase 62 candidate (the ONE direction with affirmative evidence): improve hot-cache CURATION quality** — the dev-debrief → `working-knowledge.md` distillation, the 100-entry cap eviction policy (currently usage-count + oldest-date), and dedup against existing entries. Evidence: the baseline's strength in Phase 61 IS the evidence the hot cache is the effective layer. | Link: `eval/memory-integration/results.md` Phase-62 build list.
- **Lesson (candidate /wiki-capture):** a mechanical token-renumber needs a full ref-integrity audit, not a heading-only check — caught a partial-token corruption (`Step 2/2.5`→`Step 4/2.5`) that the heading-only success criterion would have shipped green.
- **Pre-existing approximation preserved (out of scope):** dev-plan SKILL orchestrator-overview "(Steps 9–14)" approximates the inline span (actually 9–15); was "(Steps 5–7)" before, kept equivalently approximate.
