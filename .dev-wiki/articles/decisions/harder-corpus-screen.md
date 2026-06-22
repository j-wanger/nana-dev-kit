---
title: "Phase 101: harder-corpus contract screen on edge-screener (test the avenue Phase-100's ceiling-saturated null routed forward)"
aliases: [harder-corpus-screen, harder-corpus-contract-screen, edge-screener-contract-screen]
category: decisions
tags: [contract-fidelity, harder-corpus, edge-screener, rung-c, opencode, amplifier-screen, heu-012, measurement, pre-registration, integrity-invariant, calibration-pilot]
parents: [phase-101-harder-corpus-screen]
created: 2026-06-22
updated: 2026-06-22
source: plan
confidence: high
---

## Context

Phase 100 ([[contract-fidelity-screen]]) returned a clean amplifier-null — a contract adds no measurable fidelity over bare for a capable `opencode/big-pickle` worker — but the corpus was **ceiling-saturated**: four toy tasks the worker aced regardless of arm, so the screen tested "does a contract help where a worker already succeeds?" (no), NOT "where it would otherwise FAIL." Phase 100 routed the harder-corpus question forward. This phase takes it on, attacking that exact limitation: construct real code-development tasks **hard enough that a bare prompt plausibly fails for an integrity reason**, and measure whether a contract that names the integrity invariant keeps the worker more faithful than a prose spec or bare prompt.

The substrate is `/Users/jwang/edge-screener` — a stock-screener backtesting platform whose whole thesis is *un-foolable integrity* (no-lookahead decision-lag `weights[k]` earn `returns[k+1]`, cost application, point-in-time survivorship), with ~50 rigorous tests (several explicitly anti-gaming). The domain creates genuine failure headroom: a plausible-but-subtly-wrong implementation passes a casual eye but fails the integrity tests, which are deterministic ground truth.

## Decision

Phase 101 is a **measurement phase** reusing the Phase-100 harness adapted to an edge-screener workspace. Construct from-scratch **FUNCTION-level stubs** of integrity-critical edge-screener functions (each with one strong, namable invariant); the worker re-implements the stubbed function in a per-run throwaway edge-screener copy. The three arms (bare/spec/contract) at information parity differ ONLY in whether the integrity invariant is named (the test is held-out). Score **PRIMARILY** by the held-out integrity test (deterministic, ship-blocking — the function's full functional+integrity test, so a vacuous stub fails functionally), **SECONDARILY** by a cross-model judge (descriptive, can never overturn the deterministic verdict).

A mandatory **difficulty-calibration pilot** keeps only tasks where bare FAILS for an integrity reason, stably (≥2/N bare runs fail the SAME integrity assertion); no in-band task → informative null. A **forked, frozen `analyze-hard.py`** (deterministic-primary headline, `MIN_CORPUS=3`, `n=3` pinned — NOT the judge-primary Phase-100 `analyze.py`) reads the verdict mechanically.

Direction gate positions (ledger Phase-101, all_accept:false):
- **A1 accept** — a mandatory calibration pilot gates the corpus; no in-band task → informative null (a clean "no discriminating harder corpus constructible" is a valid result).
- **A2 REJECT** — bug-injection-repair rejected by the maintainer in favor of **from-scratch stub** (more genuinely "actual code development"); function-granularity + the A1 pilot mitigate floor risk.
- **A3 accept** — per-run edge-screener copy reusing its `.venv`; smaller corpus (3-4 tasks × n=3); opencode runs pytest in the copy. Feasibility verified in the pilot.
- **A4 accept** — edge-screener is the base (real, genuinely hard, un-foolable integrity tests, the maintainer's domain; worker-in-edge-screener gives automatic nana-isolation).

## Why

The integrity tests are **un-foolable ground truth**, so the design flips Phase 100's headline: **deterministic-PRIMARY, judge SECONDARY** (the opposite of Phase 100 where the judge was the headline). Controls-first ([[HEU-012]]): each held-out scorer is validated against a seeded **known-wrong** reference (the canonical lookahead/survivorship/cost bug it MUST fail) AND a seeded **real** reference (it MUST pass) — clean-on-seed = a dead instrument → reject that task; all-clean → abort. Adversarial+Tier-1-hardened controls: failure-mode stability (≥2/N same assertion); contract-leakage diff (the contract names the property, not the test's operative literals); the held-out truly unreachable (grep the whole tree); information parity; a **contract-arm floor guard** (≥1 in-band task with contract>bare by the effect form for a VERDICT, else null — guards "floored corpus dressed as a verdict"); byte-frozen before scored runs. The real edge-screener is NEVER mutated (per-run copies + checksum). The phase ships NOTHING (kit unchanged; this is a measurement re-run). The in-kit working-knowledge leak hazard ([[can't-measure-clean-context-in-kit]]) does NOT apply — the worker runs in edge-screener, not nana.

## Alternatives considered

- **Bug-injection-repair** (the dashboard recommendation) — rejected by the maintainer (A2) in favor of from-scratch stub: re-implementing a stubbed function is more genuinely "actual code development" than repairing a planted bug.
- **Reuse Phase-100 `analyze.py` verbatim** — rejected: it is judge-primary, `MIN_CORPUS=4`, `n≥5` — contradicts this phase's deterministic-primary / 3-task / n=3 design. Forked into `analyze-hard.py` (reuses only the effect-form math).
- **Synthetic-but-hard tasks** — rejected: edge-screener is real, genuinely hard, and the maintainer's domain; synthetic tasks lack the un-foolable integrity ground truth.

## Consequences

The apparatus lives entirely in gitignored `companion/research/contract-screen-hard/` (corpus stubs + held-out scorers + seeded reference/known-wrong + per-run runner + byte-frozen pre-registration + results + verdict), like Ph97/98/100. No `scripts/`/`modules.json`/hook/test/`Makefile` change; the kit ships nothing. A clean informative null is a valid success that bounds where contracts can be measured at all. Ledger Phase-101 (all_accept:false).

## Verdict (Phase 101 outcome, 2026-06-22)

**The corpus discriminated — Phase 100's ceiling is broken.** The mandatory pilot put all 3 tasks IN-BAND: the bare arm failed the *same integrity assertion* 3/3 on every task (a bare worker re-implementing an integrity-critical function ships functionally-running but integrity-violating code: same-bar lookahead; no long-only rejection; exclusive-not-inclusive membership). 27 scored runs (3 tasks × 3 arms × n=3), 0 infra-fail, frozen instrument sha-intact, real edge-screener src/tests unmutated.

**A1 (deterministic primary) — a DIFFERENTIATED result, not Phase 100's null:**
- **pit (membership inclusivity): contract HELPS** — det 1.00 (contract) vs 0.00 (bare/spec); non-overlapping ranges = effect by the frozen rule. Naming "membership is inclusive THROUGH the removal date" made the worker get it right 3/3 where the unnamed arms failed 3/3.
- **decision-lag: genuine floor** — even told the invariant, the worker set new weights directly at day k instead of the reference's one-day `pending` deferral; the un-foolable behavioral test catches it. **Naming the invariant ≠ implementing it correctly when the implementation is the hard part.**
- **leverage: a held-out-test WORDING ARTIFACT (not a floor)** — the contract worker correctly rejects negative weights + sum>1 (honors the invariant), but the test asserts `pytest.raises(ValueError, match="long-only")` — it pins error-message wording the contract-leakage rule forbids the contract from supplying, so a correct impl fails on wording.
- Headline: **contracts CAN add real fidelity on hard delegation — but task-specifically, only where the gap is a nameable semantic invariant the worker can act on, NOT where the gap is implementation difficulty.** A genuine refinement of the Phase-100 amplifier-null (which found no contract value on *easy* tasks). NOT a blanket "contracts work."
- (The frozen `analyze-hard.py` cross-task *headline label* prints "AMPLIFIER-NULL" because it averages the strong pit effect with the two floors; the spec's per-task **contract-floor guard** — the actual decision mechanism — records pit's lift. Reported verbatim, rule un-edited per anti-retrofit.)

**A2 (deterministic vs the secondary judge) — neither scorer is a reliable sole arbiter:**
- Judge genuinely WRONG on decision-lag (9/9 runs judge=HONORED while det=FAIL): the same-bar bug is too subtle to catch by reading source — only the generative behavioral test catches it. → **deterministic-PRIMARY VINDICATED.**
- Deterministic test genuinely WRONG on leverage-contract (3/3 runs): the impl honors the invariant, the judge correctly said HONORED, det failed only on message wording. → the judge caught a det artifact.
- → A robust contract-fidelity scorer needs a deterministic test that asserts **BEHAVIOR ONLY** (no message-wording), with the judge as a cross-check — the control the leverage task lacked (named follow-on).

Verdict + apparatus gitignored `companion/research/contract-screen-hard/` (`verdict.md`, `pilot.md`, `results.json`, `.frozen`). Claim scoped to the 3-task corpus + `opencode/big-pickle`. Ships nothing (kit unchanged).

## Source

Phase 101 direction gate 2026-06-22 (ledger Phase-101; A1 accept, A2 reject→from-scratch stub, A3 accept, A4 accept; all_accept:false). Spec `specs/phase-101-harder-corpus-screen.md` (nana:approved 2026-06-22). Relates to [[contract-fidelity-screen]] (Ph100, the ceiling-saturated null this attacks), [[can't-measure-clean-context-in-kit]] (the leak hazard, here N/A — worker runs in edge-screener), [[HEU-012]] (controls-first — the held-out test must fail the canonical bug).
