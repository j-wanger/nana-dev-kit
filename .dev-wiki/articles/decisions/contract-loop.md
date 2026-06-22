---
title: "Phase 102: contract-driven downstream-worker LOOP (rung-C pillar 2 — does feedback recover the Ph101 floor, and does iteration breed gaming?)"
aliases: [contract-loop, contract-driven-loop, pillar-2-loop]
category: decisions
tags: [contract-fidelity, contract-loop, rung-c, pillar-2, edge-screener, opencode, amplifier-screen, heu-012, measurement, pre-registration, integrity-invariant, gaming-detection, best-of-n, feedback-vs-resampling]
parents: [phase-102-contract-loop]
created: 2026-06-22
updated: 2026-06-22
source: plan
confidence: medium
---

## Context

The rung-C culmination (pillar 2 — downstream-worker execution). Phase 100 ([[contract-fidelity-screen]]): contracts add no fidelity on easy/ceiling-saturated tasks (amplifier-null). Phase 101 ([[harder-corpus-screen]]): on hard integrity tasks where a bare prompt fails, naming the invariant helps **task-specifically** — but **decision-lag floored even with the invariant named** (the worker understood "weights decided at k first earn the return at k+1" yet implemented the subtle `pending` deferral wrong in one shot — implementation difficulty, NOT feedback-starvation). Pillar 1 (the deterministic check, `scripts/check-fidelity.py`) shipped Ph100; pillar 3 (the direction dashboard) shipped Ph99. This phase asks the full thesis: does wrapping the worker in a **loop governed by the contract** — implement → score the contract's VISIBLE guardrails → feed back the failing assertion + a counterexample → retry → up to a cap — recover that floor, and does iteration breed **gaming** (iterate-to-green on the visible checks while failing a deeper HELD-OUT validation)?

## Decision

Build a throwaway contract-driven loop apparatus (gitignored `companion/research/contract-loop/`) and run a pre-registered, controls-first measurement. Direction gate closed 2026-06-22 (ledger Phase-102, all_accept:true): A1 **rich feedback** (failing assertion + counterexample, not pass/fail — single-shot WITH the invariant named already floored, so the worker needs to know WHY/where it broke); A2 **visible-guardrail loop + a SEPARATE held-out validation** (gaming = visible-pass but held-out-FAIL); A3 arms **single-shot / contract-loop / bare-loop**; A4 worker substrate = **opencode loop** (`run --continue`/`--session`, the proven Ph100/101 worker).

**The adversarial review added a structural 4th arm — best-of-N.** "Recovery" over single-shot is confounded with simply taking *more attempts*: the loop might help via resampling, not feedback. A **best-of-N** arm (N *independent* single-shot attempts, NO feedback, take the best) runs at the loop's N, so the headline feedback claim is **`contract-loop − best-of-N`**, not `contract-loop − single-shot`. The bare-loop isolates the invariant's value *within* the loop; the best-of-N isolates feedback from resampling.

## Why

- **The floor is the whole point.** Ph101 proved decision-lag is an implementation-difficulty floor (naming ≠ implementing). A loop with rich feedback is the natural next lever — but only if the recovery is real (held-out confirms) and from feedback (best-of-N controls resampling). Without the best-of-N arm the result is uninterpretable.
- **Gaming is the real risk of iteration.** An iterate-to-green loop that optimizes a visible check can converge on a vacuous/over-fit impl. The visible/held-out split (the Ph100/101 keystone) makes gaming *measurable*: visible-pass but held-out-FAIL. It is only meaningful if gaming is **detectable in principle** — a seeded gamer must exist that passes all visible checks and fails held-out; if none can, the held-out is redundant.
- **Deterministic-primary, held-out as ground truth.** Ph101 showed the deterministic integrity test caught a subtle bug the judge missed; here the held-out generative test is the un-foolable arbiter of recovery vs gaming.

## How to apply

Per (task, arm, run): a per-run edge-screener copy (target function stubbed, held-out test removed + literals scrubbed) → opencode implements → `check-fidelity.py` scores the visible guardrails → on fail, rich feedback (assertion + a counterexample whose inputs are DISJOINT from the held-out's) → `opencode run --continue` → ≤ cap iterations → score the held-out ONCE in a SEPARATE copy. 4 arms byte-identical except the invariant-naming line. Controls-first ([[HEU-012]]): a seeded gamer passes-visible+fails-held-out, a seeded honored passes both, every visible check reds on a seeded defect — recorded BEFORE the freeze. Re-verify the decision-lag single-shot floor STILL exists (≥3 seeds) before freezing — no floor → no-floor null. Held-out never leaks (transitive-reachability + per-run transcript grep voids on hit). Terminal-failure bucketed (converging-truncated / stalled / regressing); infra-fail excluded. Byte-frozen pre-registration (corpus + split + 4 arm configs + feedback template + cap + N + best-of-N selection/tie-break + the decision rule incl. a pinned effect floor) before scored runs. Verdict read mechanically per arm with intervals; below the effect floor = "directional/underpowered." Real edge-screener never mutated; SHIPS NOTHING; claim scoped + worker pinned (`opencode/big-pickle`, this held-out probe).

## Anti-pattern

- Claiming feedback value that is really resampling (no best-of-N arm) — the confound the 4th arm exists to kill.
- "Recovering" a floor that no longer exists (skipping the single-shot floor re-verification).
- A held-out that leaks into the worker's session → "no gaming" becomes a measurement artifact.
- Iterating against the validation itself (visible == held-out) → gaming undetectable by construction.
- Over-reading a 4-arm × n=3 split as a recovery headline (ignoring the pinned effect floor).

## Source

Phase 102 plan. Spec `specs/phase-102-contract-loop.md` (nana:approved 2026-06-22). Builds on [[contract-fidelity-screen]] (Ph100) + [[harder-corpus-screen]] (Ph101). Apparatus gitignored `companion/research/contract-loop/`.
