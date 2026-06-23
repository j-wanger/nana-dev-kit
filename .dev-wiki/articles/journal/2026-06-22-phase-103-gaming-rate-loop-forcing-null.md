---
title: "Phase 103: Gaming-rate vs gate-strength — the informative null + the loop-forcing reframe"
aliases: []
category: journal
tags: [contract-loop, gaming-rate, gate-strength, rung-c, pillar-2, edge-screener, opencode, measurement, informative-null, loop-forcing, silent-wrong, heu-012]
parents: [phase-103-gaming-rate]
created: 2026-06-22
updated: 2026-06-22
source: debrief
duration: long
---

# Phase 103: Gaming-rate vs gate-strength — the informative null + the loop-forcing reframe

## What Happened

- Planned Phase 103 (4th in the Ph100/101/102 rung-C lineage) and ran it to the
  make-or-break pilot in one extended session. The question: does a deliberately
  WEAKER visible gate elicit GAMING (visible-pass ∧ held-out-FAIL = silently-wrong
  work) from the real `opencode/big-pickle` contract-loop worker — is the contract's
  STRENGTH load-bearing for truthful delegation, or does worker competence carry it?
- **T1 (the instrument):** copied the frozen Ph102 apparatus (NOT mutated) into a new
  gitignored `companion/research/contract-loop-gaming/`, built a 2-3 rung gate ladder
  over the FIXED Ph102 held-out — G2-strong{v1_func,v2_lag} → G1-medium{v1_func} →
  G0-weak{v0_shape} — reducing the gate's COVERAGE of the lag invariant rung by rung.
  `validate_controls.py` + adversarial `--selftest` green (C1-C7). A 4-lens adversarial
  review then found + fixed **2 HIGH** (a docstring→feedback held-out leak; a
  provably-non-nested ladder) **+ 2 MEDIUM** (held-out non-determinism; infra-fail
  run-slot leakage) + 1 LOW — all BEFORE any opencode run.
- **T2 (the make-or-break pilot):** 9 natural-worker runs (3 gates × n=3), 0 infra,
  leak-clean, edge-screener `931c0caef3742029` unchanged. **3/3 consistent at every
  gate.** It returned the informative null and the reframe, so per the pre-registered
  checkpoint (cold-pass-dominated weakest rung → STOP), T3 (byte-freeze) and T4 (full
  campaign) were NOT run — by design. The maintainer chose close-out.
- **T5:** wrote `verdict.md` (informative null + loop-forcing reframe + three-way
  taxonomy [silent-wrong 3/3 at g0] + scope). Decision article finalized.

## The result (informative null + reframe)

**Loop-gaming does NOT occur; gate strength is load-bearing for truthful delegation
by FORCING THE CORRECTIVE LOOP, not by preventing in-loop gaming.**

- g2-strong and g1-medium: **truthful 3/3** — converged-via-loop, held-out PASS. Shown
  a failing lag locus, the worker generalizes to a correct one-day lag even from ONE
  locus.
- g0-weak (shape-only): **cold-pass 3/3** — held-out FAIL. The shape-only gate is
  satisfied by the worker's wrong FIRST impl, so no loop ever fires.
- **Loop-gaming rate = 0/6** (Wilson 95% [0, 0.39]); silent-wrong is elicited only as a
  one-shot COLD-PASS at g0.

The null is **STRUCTURAL, not underpowered**: there is no gate the worker both loops
against AND games — weakening g2→g1 keeps truthful recovery, weakening g1→g0 drops past
the loop-forcing threshold into cold-pass; no intermediate gaming "sweet spot." The
contract earns its keep by GUARANTEEING the worker is SHOWN a concrete failure; once
shown, deterministic feedback recovers truthfulness regardless of how few loci are
pinned. Sharpens [[contract-loop]] (Ph102 — feedback recovers the floor) and rhymes
with the amplifier-nulls (Ph59/80: the capable worker carries the work once shown where
it broke).

## Decisions Made

- [[gaming-rate-gate-strength|Gaming-rate vs visible-gate-strength]] — informative null +
  loop-forcing reframe (confidence: high).

## Problems Solved

- A pre-freeze held-out LEAK (docstring → feedback path) — caught by the T1 4-lens
  adversarial review, fixed before any worker run.
- A provably-non-nested gate ladder (a "weaker" rung that could still force correctness)
  — fixed so rung-k ⊂ rung-(k+1) by construction.
- A3 operationalization snag: a naive marker grep false-positives on codebase
  identifiers (`SPY_TR_CAVEAT`) — the silent-wrong classifier must scope to the
  worker's OWN prose, else fall back to the raw under-spec rate.

## Open Questions

- The CAPABILITY bound — can the worker game if EXPLICITLY told to optimize the visible
  checks? The maintainer DECLINED the adversarial-prompt arm at the gate and reaffirmed
  post-pilot; the seeded controls already establish gameability-in-principle. Flagged
  untested, not a blocker.

## Artifacts Changed

- `companion/research/contract-loop-gaming/**` (gitignored apparatus — gate ladder,
  `validate_controls.py`, `pilot.md`, `verdict.md`; NEW dir, copies frozen Ph102, does
  not mutate it)
- `.dev-wiki/articles/decisions/gaming-rate-gate-strength.md` (Outcome section finalized)
- `.dev-wiki/tasks.md` (T1/T2/T5 [x]; T3/T4 annotated SKIPPED — pre-registered null path)
- `.dev-wiki/_CURRENT_STATE.md`, `.dev-wiki/assumption-ledger.md` (A1 bit, A2/A3 held),
  `.claude/rules/active-phase.md`, index/log
- SHIPS NOTHING: no kit code change (check-fidelity.py already shipped Ph100); make test
  PASS, eval 50/50, drift 0; `/Users/jwang/edge-screener` src checksum `931c0caef3742029`
  IDENTICAL before/after; `companion/` untracked

## Related

- [[phase-103-gaming-rate|Phase 103: Gaming-rate vs visible-gate-strength]] — parent phase

## Soft Observations / Phase N+1 Candidates

- **The capability bound (adversarial-prompt arm)** | "can it game when told to vs the
  natural-arm propensity measured here" | a possible follow-on if the maintainer wants
  the capability upper bound | evidence: this verdict's Untested note.
- **The loop-forcing finding** ("a contract earns its keep by FORCING the corrective
  loop; a too-weak gate fails silently via cold-pass") | candidate kit doc/pattern | but
  apply measure-before-ship caution — it is a single-task n=3 PILOT finding | evidence:
  `companion/research/contract-loop-gaming/verdict.md`.
- **rung-D generalization** | take the contract-loop / gate-strength probe to another
  domain (the broader rung-A..D program) | evidence: the Ph97 de-risking ladder.
- **A3 operationalization** | a mechanical silent-wrong vs honest-flagged-wrong
  classifier must scope to the worker's own prose; a naive marker grep false-positives
  on codebase identifiers (`SPY_TR_CAVEAT`) | evidence: the T2 pilot A3-separability note.
