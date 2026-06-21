---
title: "Phase 97: Frontier Positioning Sweep"
status: active
ceremony: standard
created: 2026-06-21
updated: 2026-06-21
scope:
  - companion/research/**
  - .gitignore
  - .dev-wiki/**
  - .claude/rules/active-phase.md
exit_criteria:
  - companion/ gitignored AND `git ls-files companion/` empty
  - pre-registration.md has decision-rule + protocol + anti-retrofit sections, ≥1 falsifiable threshold per outcome, frozen before T3
  - sweep-findings.md + convergence-map.md — every cluster URL-cited AND classified against the rubric
  - verdict.md states one of DIFFERENTIATED/COMMODITIZED/DIVERGENT/INCONCLUSIVE with explicit threshold mapping + a signal-half-life→pipeline-cadence recommendation
  - ZERO kit code/config change (verdict only); make test PASS; drift 0
---

## Objective

Produce a pre-registered, evidence-based read of where the agent-harness / agent-tooling frontier is
converging, and read it MECHANICALLY against a frozen decision rule to answer whether nana-dev-kit's
bet (deterministic spine + lifecycle ceremony) is **DIFFERENTIATED / COMMODITIZED / DIVERGENT** vs the
frontier. The external arm of the Ph92 "re-measure-once-then-shrink" — the internal arm
([[memory-layer-disposition]]) already returned KEEP. Reframed from layer-shrink to product-positioning
(A1 reject); shrink is a downstream consequence of a COMMODITIZED verdict. Rung A of the companion
de-risking ladder (B pipeline / C opencode workers / D generalization are future phases).

## Approach

One-shot sweep, lab-published artifacts PRIMARY (declared frontier direction), OSS repos SECONDARY
corroboration (A2 reject). Frozen instrument → run → mechanical verdict. Lives entirely in gitignored
`companion/research/` (local-only apparatus, never shipped). Produces a VERDICT only — executes no cut;
any shrink is a separate gated phase.

## Tasks

See `tasks.md` Phase 97. T1 [S] gitignore guard (controls-first) · T2 [M] pre-register the frozen
instrument · T3 [L] run the frontier sweep · T4 [M] mechanical verdict + half-life→cadence.

## Key Constraints

- Pre-registration FROZEN before T3 (anti-retrofit, [[stage2-episode-execution-design]] three-tier authority).
- Verdict read MECHANICALLY against the frozen rule — no post-hoc threshold tuning (guards apparatus-as-decision-avoidance).
- Lab artifacts primary / OSS secondary; honesty bound — internal lab harnesses unseen, read declared direction.
- gitignore guard (T1) verified BEFORE any research write — nothing leaks into the shippable kit.
- Does NOT relitigate the Ph95 memory KEEP; pairs with, not replaces, internal evidence.
- NO standing pipeline this phase (A3 down-scoped — T4 recommends cadence for rung B).
- Spec function served by `companion/research/pre-registration.md` (gitignored) — deliberate deviation, apparatus is private.

## Abort

A sweep that can't reach a frozen-rule outcome → INCONCLUSIVE with named resolving-evidence (routes
rung B), never a retrofitted verdict. >3 attempts on a task → ask user skip|abort.

## Decision

[[frontier-positioning-sweep]] (high). Ledger Phase-97 (all_accept:false — A1 reject→positioning,
A2 reject→lab-primary, A3 don't-know→half-life-to-T4).

## Outcome (implementation complete 2026-06-21 — status active, delivery gate pending)

4/4 tasks complete. **VERDICT = INCONCLUSIVE — forced-under-observed (differentiated-leaning).** The
mechanical OUTCOME label is INCONCLUSIVE (of record), kept SEPARATE from the differentiated-leaning
substance — never relabeled (anti-retrofit; independent cold re-derivation CONFIRMED: freeze MATCH,
retrofit-check CLEAN). Read against the FROZEN instrument (`sha256 600e1c9f`, re-verified at T4 vs
`companion/research/.frozen` — MATCH): **K_low=0** (zero COMMODITIZED primitives), **K_high=1** (B5
boundary-validator CONTESTED — OpenAI's value-capturing auto-Pydantic tool-arg validation sole FOR,
below the ≥2-labs-or-Anthropic+1 bar). CORE (B1 blocking gates + B4 assumption gate) UNCOMMODITIZED;
B2/B3 NOT-COMMODITIZED; 12/14 THIN; 3 labs affirmatively leave the discipline layer to tooling;
DIVERGENT=0; OSS corroborates DIFFERENTIATED. INCONCLUSIVE is FORCED by the rigorous rule's zero-tolerance
"any contest bars DIFFERENTIATED" clause firing on one NON-CORE primitive (the realized rigor/legibility
cost flagged at freeze; the simplified rule returns a clean DIFFERENTIATED). **NET: the external frontier
gives NO case to shrink the bet; combined with the Phase-95 internal memory KEEP, both arms of the Ph92
re-measure now agree.** Freeze used a SHA256 ATTESTATION (git ancestry can't guard a gitignored file).
A3 resolved: QUARTERLY core-primitive watch for rung B. ZERO shippable-kit change; make test PASS; drift 0.
Outcome detail in [[frontier-positioning-sweep]]. **Delivery gate flips + phase transitions active→completed
on the post-acceptance commit.**
