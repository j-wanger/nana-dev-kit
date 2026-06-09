---
title: "Phase 80 complete — Assumption-Surfacer Completeness Screen: clean-context control FAILED → INSTRUMENT-DEAD (the 5th amplifier-null, caught in the act)"
aliases: ["2026-06-09-phase-80-assumption-screen"]
category: journal
tags: [assumption-interrogation, surfacer, screen, circularity, clean-context-leak, amplifier-null, representativeness, blind-yes, degenerate]
parents: [phase-80-assumption-surfacer-completeness-screen]
created: 2026-06-09
updated: 2026-06-09
source: debrief
duration: unknown
---

# Phase 80 complete — Assumption-Surfacer Completeness Screen → INSTRUMENT-DEAD

## What Happened
- Origin: a handover doc + a team-upskilling conversation proposed reshaping the dev-plan human gate from approving the *approach* (a conclusion the maintainer can't evaluate → blind-yes) to taking **accept / reject / don't-know** positions on the plan's load-bearing **assumptions** (+ a cross-phase ledger, all-accept block). The plan was interrogated LIVE via that very mechanism (the gate eating its own dogfood): Jake **A1 accept / A2 REJECT / A3 accept / A4 accept**. The single A2 reject — "can't trust the agent-CHOSEN assumption *set*; solve set-completeness before building anything" — turned Phase 80 from a build into a **SCREEN**.
- An amplifier-null spike preview + the reframe pointed the screen at the **SILENT** assumption class via the project's REAL silent failures (the R5 silence-gap class: assumptions that left an outcome trace — a revision/supersession/blocked-task), NOT synthetic plants (avoids the Ph66/69 plants≠soft-reals ghost). Three real fixtures chosen: `mcp-cwd`, `line-cap`, `cascade`.
- **T1 (GATE) circularity-escape spike → GO**: non-circular outcome-determined ground truth was constructible for ≥3 past phases, so the phase proceeded past the hard gate (INSTRUMENT-DEAD would have stopped it for one task's cost).
- **T2** pre-registration committed `86d8584` BEFORE any scoring run, ancestor-guarded (re-verified at T6); fixed the closed verdict vocabulary, the variance-derived bar procedure, two-track verdict, and the explicit `surfacer ≈ baseline ⇒ 5th-amplifier-null` possibility up front.
- **T3** surfacer spec (naive baseline + scope-anchored/framing surfacer) + `coverage-check.sh` (deterministic, `--selftest`). **T4** fixtures (3 real silent cases + cost-sort-adversarial + negative) + `check.sh` (cloned from `anchor-screen/`, NO LLM in scoring, `--selftest`); controls green, no-leak invariant held at authoring time.
- **T5** ran the 50-run workflow (5 fixtures × 2 conditions × n=5), scored NO-LLM. **T6** wrote `screen-record.md` → **`^PROGRAM-VERDICT: INSTRUMENT-DEAD`**.
- **The decisive finding (a control failure, not a verdict):** the T5 workflow subagents ran INSIDE nana-dev-kit and inherited its always-loaded `working-knowledge.md`, which documents all 3 real fixtures' buried assumptions verbatim. The SURFACER's infrastructure-enumeration triggered **retrieval of those documented answers** — it leaked project-specific facts (Phase numbers, working-knowledge specifics) on **4/5, 5/5, 5/5** of the three real cases and **0/5** on the two cases NOT in working-knowledge (costsort-adversarial, negative). The headline SURFACER>NAIVE (line-cap 5/5 vs 0/5) is a **leak artifact** — SURFACER reciting "session-start.sh line cap 70→137, Phase 22" from working-knowledge, not surfacing it from the plan. The clean-context premise is violated for SURFACER on exactly the cases that matter.

## Decisions Made
- [[assumption-surfacer-completeness-screen|Assumption-Surfacer Completeness Screen]] (confidence low→**high**, finalized) — the screen returned a control-failure verdict; the clean signal that survives points DEGENERATE → Phase 81 should ship the SIMPLEST gate, not the elaborate machinery.

## Problems Solved
- **The amplifier-null, caught in the act:** the leak IS the harness re-presenting documented answers (Ph70/71/77/78 in its sharpest form). On the two cases the harness does NOT document, the surfacer had nothing to recall (leak 0/5). This extends the amplifier finding from decisions/tooling-correctness to **assumption-surfacing** — a 5th null.
- **Clean signal points DEGENERATE:** NAIVE ran clean (leak ~0/5) and recovered **3/4** silent-class assumptions by pure reasoning from the plan; the one fully-clean comparison (costsort-adversarial, 0 leak both conditions) was BOTH-CATCH. The project's silent failures were silent because **nobody ASKED** at planning time — not because the assumptions are unsurfaceable. A naive "list the load-bearing assumptions, cost-sorted" prompt surfaces them.
- **Self-check missed the agent's own buried assumption.** "Workflow subagents are clean-context" was MY load-bearing assumption — missed by self-check, caught only by an adversarial output audit (the leak in the run outputs). Live evidence that self-triggering interrogation fails where external forced checking works — the handover thesis, demonstrated on the very phase that screens it.

## Open Questions
- [parked: Phase-80] The accretion/budget assumption class (line-cap fixture) is the ONE place NAIVE cleanly missed AND where the SURFACER leak was strongest → whether scope-anchoring genuinely helps there is **UNMEASURED** (leak-confounded). A valid test needs a CLEAN consuming-project context (no nana-dev-kit working-knowledge). Re-trigger: building Phase 81 surfaces real demand to catch accretion-class assumptions.
- [methodological] Cannot measure "what a clean-context agent would surface" INSIDE the kit — always-loaded working-knowledge leaks the test answers (Ph66/69 representativeness, re-confirmed). Any future surfacing/headroom screen MUST run in a consuming-project context.

## Artifacts Changed
- `eval/assumption-screen/` (NEW repo-only line, sibling to `eval/amplifier/`; NOT wired into install.sh / Makefile / make test / make eval): `spike/` (T1 GATE → GO), `pre-registration.md` + `.prereg-commit` (`86d8584`, ancestor-guarded), `surfacer.md`, `coverage-check.sh` (`--selftest`), `fixtures/` (3 real silent + cost-sort-adversarial + negative), `checks/`, `check.sh` (`--selftest`, NO LLM in scoring), `runs/` (50), `verdicts/summary.md` (leak audit + per-case classification), `screen-record.md` (`^PROGRAM-VERDICT: INSTRUMENT-DEAD`).
- Work committed across `86d8584` / `d31c355` / `13f0242` / `405b4f7`.

## Related
- [[phase-80-assumption-surfacer-completeness-screen|Phase 80: Assumption-Surfacer Completeness Screen]] — parent phase
- [[skill-crystallization-headroom-screen|Phase 78]] / [[cross-session-retention-headroom-screen|Phase 77]] / [[cross-boundary-retention-headroom-screen|Phase 71]] / [[amplifier-anchor-headroom-screen|Phase 70]] — the prior four amplifier nulls this extends

## Soft Observations / Phase N+1 Candidates
- **Clean-context-leak is a GENERAL measurement hazard** | any in-kit measurement of "what a clean agent surfaces" is confounded by always-loaded working-knowledge — future such screens MUST run in a consuming project (re-confirms Ph66/69) | evidence: `eval/assumption-screen/verdicts/summary.md` leak audit.
- **External forced checking beats self-triggering interrogation** | the agent's OWN buried assumption (subagents are clean-context) was missed by self-check, caught only by an adversarial output audit — the handover's central thesis, observed live | evidence: `eval/assumption-screen/screen-record.md`.
- **5th amplifier-null** | the harness adds no measured value re-presenting what the model recovers — now extended from decisions/tooling-correctness to assumption-surfacing; surviving avenue unchanged (genuinely proprietary/post-cutoff) | evidence: `screen-record.md` "informative-null".
- **Phase 81 = ship the SIMPLEST gate** | naive "list load-bearing assumptions, cost-sorted" surfacer + accept/reject/don't-know + the A3 cross-phase ledger (detect-after backstop) with a debrief forcing-function for revisit-status + the all-accept blocking check ([[HEU-012]]); do NOT build the elaborate scope-anchored machinery (its only edge was the leak) | evidence: `screen-record.md` "Consequence for Phase 81".

### Activation Quality
`.claude/rules/active-knowledge.md` (Phase 80, 7 entries) — all 7 entries were on-thesis and load-bearing this session: the harness-vs-baseline frame, the T1 hard-gate, the `surfacer ≈ baseline ⇒ TERMINATE` null, the three review MAJORs (cost-sort-adversarial / entity-presence / variance-derived bar), the two-track verdict, the rep-1 reject signal, and the cuts. Hit rate ~7/7 — the active-knowledge correctly anticipated the amplifier-null outcome and the cuts; it did NOT anticipate the clean-context leak (the control failure), which only the adversarial output audit surfaced.
