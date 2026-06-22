---
title: "Phase 102 — contract-driven loop: feedback recovers the floor (+ an adversarial pass that earned its keep, and an incident)"
date: 2026-06-22
type: journal
phase: phase-102-contract-loop
tags: [contract-loop, rung-c, pillar-2, feedback, opencode, edge-screener, adversarial-verification, incident, held-out-design]
---

## What happened

Built and ran the rung-C pillar-2 experiment: a delegated `opencode/big-pickle` worker re-implements a
hard edge-screener function in a per-run copy, scored each iteration against a contract's VISIBLE
guardrails (`check-fidelity.py`), fed rich feedback (failing assertion + a disjoint counterexample) on
failure, iterating over a continued session; a HELD-OUT integrity test validates the converged impl.
4 arms (single-shot / best-of-N / contract-loop / bare-loop), byte-frozen pre-registration, 48 scored runs.

## The finding

**A contract-governed LOOP recovers the Phase-101 implementation-difficulty floor — via FEEDBACK, not
resampling and not naming the invariant.** decision-lag (the clean primary task): single-shot 0/15,
best-of-N (5 attempts, no feedback) 0/3, bare-loop 3/3, contract-loop 3/3.
- **feedback = bare-loop − best-of-N = +1.0 (SUPPORTED)** — same 5-attempt budget; the loop recovers,
  resampling doesn't. The recovery is feedback, not luck-from-more-tries.
- **invariant-in-loop = contract − bare = +0.0 (directional)** — naming the invariant is nearly inert
  once feedback exists; it only sped convergence ~1 iteration (`[3,2,2]` vs `[4,3,3]`).
- **gaming = 0/3** — the held-out confirms genuine recovery.

This sharpens Ph101 (told-the-invariant ≠ able-to-implement-it) and rhymes with the amplifier-nulls
(Ph59/80): the capable worker doesn't need to be TOLD the rule — it needs to be SHOWN where it broke.
The best-of-N arm (added by the adversarial review at planning) was load-bearing: without it, the
recovery would have been confounded with resampling.

## The adversarial pass earned its keep (and bit back)

A clean-context adversarial-refutation workflow (4 lenses, ~470k tokens) was run against the controls-
first instrument that my deterministic checks had ALREADY passed. It found two REAL holes the
deterministic controls missed:
- **Held-out LEAK**: the work-copy shipped the invariant in sibling-file docstrings AND the original
  un-stubbed `.pyc` bytecode (`copytree` had no ignore). A worker could recover the answer. Fix:
  ignore `__pycache__`/`*.pyc`, scrub invariant docstrings tree-wide, grep the whole tree.
- **Held-out UNDER-PINNING**: the held-out pinned the invariant at ONE locus; a do-nothing stub and a
  position-localized lookahead passed it. Fix: an apparatus-authored strict test sweeping EVERY position
  (decision-lag) / near+far removals (pit), + real-compounding (catches do-nothing). All closed + re-
  verified BEFORE the freeze; the attacks became controls.

**Lesson banked:** adversarial verification before the freeze catches what deterministic controls can't
(the controls test what you thought of; the adversary tests what you didn't). But run it SERIALLY.

## The incident (owned)

The adversarial workflow — run CONCURRENTLY with the floor-recheck runner in the same dir — triggered an
apparatus `cleanup()` bug: `shutil.rmtree(workcopy.parent, ignore_errors=True)` with no guard; a cwd
race produced an empty path → it deleted `/Users/jwang/edge-screener`, silently. Restored intact (`.git`
from `p87-substrate`, working tree byte-matches HEAD `4ed8071`, src checksum `931c0caef3742029` identical,
9/9 tests pass; maintainer chose the `.git` restore). Fix: `cleanup` now refuses any non-tempdir path;
all subsequent work serial. **Root cause (mine): never run a mutating workflow concurrently with a runner
in the same directory; guard every `rmtree`; never `ignore_errors=True` on a destructive op.** This is
the empty-glob/empty-path `rmtree` class the project's own working-knowledge already warns about.

## Held-out design lesson (bit twice)

The held-out must be INVARIANT-FOCUSED. Including orthogonal robustness edge cases mislabels a genuine
recovery as gaming: decision-lag's `test_empty_window` (caught pre-freeze, excluded) and pit's
`test_before_baseline` (MISSED — froze the whole membership file). The pit "gaming 3/3" was therefore an
instrument ARTIFACT (the impls correctly implement inclusive-through-removal but RAISE rather than
return-baseline pre-timeline). Reported VERBATIM from the frozen instrument + diagnosed + a clearly-
labeled post-hoc re-score (6/6 recovery) — anti-retrofit: the frozen scorer was NOT changed.

## Health Delta

No kit code changed (ships nothing — `check-fidelity.py` shipped Ph100). `make test` PASS (55/55),
`make eval` 50/50, drift 0. Apparatus gitignored (`companion/research/contract-loop/`). edge-screener
restored + intact (checksum identical, src/tests clean vs the restored `.git`).

## Gate Compliance

Phase-102 gate-log: `direction=approved delivery=accepted`. Assumption-ledger revisit (A1-A4 held;
`check-assumption-ledger.sh --revisit` clean — no blank rows). Direction gate closed at planning
(all_accept:true); delivery accepted (maintainer authorized run-through-to-verdict + the `.git` restore).

## Soft Observations / Phase N+1 Candidates

- **Measure a gaming RATE.** Gaming was detectable-in-principle (controls) but NOT exhibited (the worker
  was truthful). A deliberately WEAKER/narrower visible gate (one that under-specifies the invariant)
  would let the loop overfit → an actual gaming-rate measurement. Evidence: pit's single visible guardrail
  + the worker still recovered. Framing: "elicit-and-measure-gaming" follow-on.
- **Rung-D generalization.** rung-C is mapped end-to-end (check Ph100 / dashboard Ph99 / loop Ph102);
  the natural next rung is a high-stakes opinion-heavy domain (AML / trading) per the Ph97 convergence map.
- **Held-out-design rule.** "Held-out must be invariant-focused (exclude orthogonal edge cases)" should be
  a checklist item for any future visible/held-out-split measurement — it bit twice this phase.
- **Apparatus-safety rule.** "Guard every rmtree; never run a mutating workflow concurrent with a runner"
  — a reusable rule for the companion/research apparatus pattern.
