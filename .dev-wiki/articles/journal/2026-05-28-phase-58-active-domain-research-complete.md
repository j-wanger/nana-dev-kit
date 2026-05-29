---
title: "Phase 58 complete (active domain research in dev-plan — Fix 2)"
aliases: []
category: journal
tags: [dev-plan, domain-research, step-2-7, residual-delta, measurement, fail-open, provenance, phase-58]
parents: [phase-58-active-domain-research-in-dev-plan]
created: 2026-05-28
updated: 2026-05-28
source: debrief
duration: ~90 minutes
---

# Phase 58 complete (active domain research in dev-plan — Fix 2)

## What Happened

- Fix 2 of the Phase 57+ harness-activation roadmap. Phase 55's spec template *poses* Domain Research Questions (DRQs) but nothing answered them — the planner still guessed from parametric knowledge on uncovered topics. This phase wired a bounded, gap-gated research step into dev-plan that actually answers DRQs.
- Task 1 (M): wrote `domain-research-spec.md` companion — per-DRQ `wiki-query` coverage gate (fires ONLY on uncovered questions), bounded retrieval with explicit numeric caps degrading to partial findings, prompt-injection safety (question text = data, never instruction), ~1200-char distillation cap, persistence via the wiki capture path with provenance (URL/date/auto-researched) + contradiction check (supersede/under-review, never blind-append), fail-open clauses (no web/questions/writable-wiki/timeout → skip + marker).
- Task 2 (S): wired Step 2.7 into dev-plan SKILL.md as a 2-line Read-pointer with `*(Lite: skip)*` (321→326 lines, under 350). Added a Step 6 anti-theater bullet: cite findings at named approach decisions.
- Task 3 (L): built + ran the residual-delta measurement (`eval/research-measurement/results.md`) — the *functional* test of an LLM-executed step the binary eval runner cannot score. Gate verified both ways vs the real wiki: COVERED (context-dilution budget) → research SKIPPED, zero calls; UNCOVERED (structured outputs) → research FIRED (3 searches, 1 fetch, within ≤10 budget). Hit Checkpoint 2 (STOP + report) before marking done.
- Task 4 (S): integration verification — 9/9 non-memory suites green, eval 54/54 (100%), companion-validation 99/99, line cap held.

## Decisions Made

- [[domain-research-dev-plan-step-2-7|Domain research in dev-plan via gap-gated Step 2.7 (mechanism c)]] -- medium. Findings inject at named Step 6 decisions; a finding informing zero decisions is dropped (research-theater guard).
- [[measure-residual-research-delta|Measure residual research delta, not the headline +1.75]] -- high for method, medium/directional for result. Subtraction test: ~0/negative residual triggers keep/trim/cut.

## Problems Solved

- Per-question gate vs Step 2.5 concept-coverage confusion -- the gate is per-DRQ `wiki-query`, NOT Step 2.5's concept score (different signal). Resolved in spec review.
- Research-theater + curation-bypass risks -- findings must land at named decisions (else dropped); auto-persist routes through the wiki capture path so `wiki-absorb` curation is preserved (DRY: no 4th crawler).

## Review Gate

9/10, accept. One MEDIUM finding: the companion's auto-persist inbox-schema needed to align with the existing `wiki-add` inbox format (provenance fields + contradiction-check) rather than a bespoke shape — fixed inline during debrief. Two suggestions noted (not blocking): (1) n=1 measurement should be strengthened with more topics; (2) a lightweight harness to regression-test LLM-executed skill steps. Both carried forward as soft observations / open questions.

## Gate Compliance

- direction=approved (present in gate-log:phase-58)
- delivery=pending — flips to accepted at the orchestrator's delivery gate (status does not auto-transition to completed here)

## Activation Quality (Step 6a)

`.claude/rules/active-knowledge.md` present with 2 distilled-entry blocks. Both reference decision slugs that appeared this session ([[decision:domain-research-dev-plan-step-2-7]], [[decision:measure-residual-research-delta]]). Hit rate 2/2 = 100% — active knowledge tracked the session's real decision surface. Phase-changed path: entries carried forward to working-knowledge.md, file cleared.

## Open Questions

- Residual research delta is +0.5 composite at n=1 (at significance threshold, topic-favorable). Kept Step 2.7 at Checkpoint 2. Strengthen with 2-3 more topics incl. a research-poor one before trusting it. (raised 2026-05-28)
- Haiku judge inter-run variance: mean ranges 2.97-4.85. (raised 2026-05-27, open)
- Memory server venv broken: libpython3.11.dylib not found (pre-existing; MCP tool path itself works — 18 active entries). (raised 2026-05-28, open)

## Artifacts Changed

- `templates/.claude/skills/dev-plan/domain-research-spec.md` (new Step 2.7 companion)
- `templates/.claude/skills/dev-plan/SKILL.md` (Step 2.7 pointer + Lite-skip; Step 6 citation bullet; 321→326 lines)
- `eval/research-measurement/results.md` (new — residual-delta measurement, +0.5 composite n=1)
- `.dev-wiki/articles/decisions/{domain-research-dev-plan-step-2-7,measure-residual-research-delta}.md` (latter gained `## Result (Phase 58 run)`)

## Related

- [[phase-58-active-domain-research-in-dev-plan|Phase 58: Active Domain Research in dev-plan]] -- parent phase
- [[2026-05-28-phase-57-hook-consolidation-enforcement-activation-complete|Phase 57]] -- prior roadmap fix (Fix 1)

## Soft Observations / Phase N+1 Candidates

- Residual-delta measurement is n=1 on a research-favorable topic; +0.5 sits at the project's significance threshold (Δ≥0.5 meaningful, variance <0.5) with unknown variance. | Phase N+1: run 2-3 more topics incl. a research-poor one to get a variance estimate before trusting Step 2.7's value. | Evidence: `eval/research-measurement/results.md`.
- Step 2.7 is LLM-executed, so the binary eval runner cannot score it — it has no make-eval scenario, only the one-shot measurement artifact. | Phase N+1: a lightweight harness to regression-test LLM-executed skill steps (covered→assert zero external calls; uncovered→assert a named cited decision). Generalizes Phase-57 "verify firing not presence" to skill steps. | Evidence: review-gate suggestion.
- Roadmap: Fix 2 done (this phase). Remaining harness-activation items: Fix 3 (AGENTS.md reshape — vague, no measured impact) and Fix 5 residual (a "kit uninitialized → run /nana-init" session-start nudge — Fixes 1/4 done, 5 mostly closed by Phases 55/57). | Phase N+1 candidates. | Evidence: Phase 57 journal roadmap note.
