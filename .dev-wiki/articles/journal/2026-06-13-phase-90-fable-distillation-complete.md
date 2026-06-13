---
title: "Phase 90 complete — Fable-5 Distillation"
date: 2026-06-13
phase: 90
tags: [soul, dev-plan, context-shaping, assumption-surfacing, fable-5, opus-4-8, subtraction]
status: complete
---

# Phase 90 — Fable-5 Distillation

## What happened

Fable-5 (removed 2026-06-13) ran signal-watch and nana-dev-kit Phases ~83-89 (Jun 9-12); switching back to opus-4-8 produced a "drastic" felt contrast in planning, assumption-uncovering, and interaction clarity. Jake asked to distill the fable patterns and update the kit + soul so opus behaves more like fable, referencing github.com/sgup/ai.

A contrastive read of paired transcripts (signal-watch fable 39-41 vs opus 15-19; kit fable 83-89 vs opus 80-82, model attribution from the transcripts' `"model"` field) + sgup/ai's `Fable5.md` produced `eval/fable-distill/findings.md`. The **governing finding**: opus already complies with the T0 protocol and assumption gate **in form, not substance** — it writes the "weakest assumption" section generically where fable mechanized it. So more prose of the same kind is the kit's own measured failure mode (Ph46 dilution, Ph47 overcorrection). The lever is **context-shaping + a few checkable forcing-functions**, not more instruction.

Jake's direction-gate reframe sharpened the scope: of the gaps I'd called "intrinsic / unrecoverable by a rules file," which are recoverable by **system design**? Answer: the reframe behaviors are recoverable by moving the reasoning into a context configuration where it's produced, not performed (clean-context forcing functions) — exactly the soul's context-shaping thesis.

Two tracks shipped, both-landings (global `~/.claude` + kit `templates/`, parity-verified):
- **Track A** — 5 checkable forcing-functions into `nana-soul.md` (2 new lines + 3 sharpenings, on-disk absence-diff confirmed first): name-the-likeliest-wrong-claim, mark-inferred-as-inferred, what-still-speaks-the-old-contract, no-regressions-needs-a-baseline, match-effort-to-blast-radius.
- **Track B1** — reframe-absorption beat in dev-plan Step 10 (gates forward progress, on a *material* reframe, on restate-in-project-vocab + name-what-it-invalidates + check-against-loaded-constraints). Recovers fable's pause-validate (I1) structurally.
- **Track B2** — clean-context framing subagent recovering reframe-DEPTH (I3) BUILT but STAGED + pilot-gated. Ph80 in-kit leak + Ph47 self-dialogue-negative require a consuming-project pilot (`eval/fable-distill/pilot-protocol.md`) before wiring. NOT in the dev-plan flow.
- **I2** mid-phase reveal-banking DEFERRED — its destination (memory) is the Phase-91 prune target; building for a layer about to be cut fails the subtraction test.

Ships on JUDGMENT, not measurement (interaction quality unmeasurable in-kit — Ph59 reasoning-eval, Ph80 clean-context). The B2 pilot is the one real future measurement. Memory-prune renumbered Phase 90 → 91.

## Decisions

- [[fable-distillation-round]] (high) — the two-track approach, codifiable-vs-intrinsic split, and the pilot-gated B2.

## Review Gate

Unified reviewer on the global-rules + core-skill diff: **8.5/10 ACCEPT-WITH-FIXES**. One insisted-on finding (3, MEDIUM): soul line #2 ("keep confirmed and inferred separable") shipped *vibey* — no checkable tell, the exact comply-in-form failure the phase diagnosed, reproduced in the fix. Rewritten to "Mark inferred claims as inferred — never let a guess read as a confirmed fact." Three LOW terseness/guard items (filler in #5, 3-sentence bullet in #1, spurious-firing risk in the reframe beat) all fixed inline (the reframe beat now carries an explicit non-firing example). All on-thesis (checkability / terseness / anti-ceremony), so all applied — ate the dogfood.

## Health Delta

No code changed (rules prose + skill prose + eval docs). make test / make eval unaffected; eval denominator unchanged (50). The audit trail: global `~/.claude/rules/nana-soul.md` and `~/.claude/skills/dev-plan/SKILL.md` edited live (already shaping sessions) and parity-mirrored to `templates/`.

## Process note

Practiced what the phase ships: applied "match effort to blast radius" to the dev-plan/debrief ceremony itself — skipped the background state-loader/artifact-writer orchestration (I held all state; the offload would have added latency, not value) and finalized inline, while keeping the load-bearing gates (direction gate, review gate on the high-blast diff, delivery gate). USER OVERRIDE noted: edited the global soul file directly (A4 accept) — identity-level, all-projects blast radius.

## Soft Observations / Phase N+1 Candidates

- **B2 pilot is the real test** — run `eval/fable-distill/pilot-protocol.md` in signal-watch; a negative result is publishable (bounds where context-shaping recovers model-intrinsic behavior). Filed in Blockers.
- **Watch for comply-in-form recurrence** — the phase's own risk is that opus ritualizes the 5 new lines. The checkability is the hedge; if the next few planning sessions read them as ceremony, that's the signal to cut, not add. (This is the one claim most expected to be wrong — recorded in the ledger A2.)
- **sgup Fable5.md full contract** — Jake picked surgical-lift over the full drop-in; the ~1.2KB contract remains a parked option (the "Both, layered" choice) if the surgical version under-delivers.
- **Delta-format reporting template** — the tactical `baseline 2 failing {a,b} → now 3: +c` template was left as a deferred kit-rules nicety (only the principle went into the soul); candidate for a coding-discipline rules file.
- **fable's terse-mechanical register** — judged not recoverable by any mechanism; not chased. If a future model-behavior phase revisits, this is the known-hard residual.
