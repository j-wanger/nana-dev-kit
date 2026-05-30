---
title: "Phase 70 — Single-decision anchor-headroom screen: the cheapest decisive go/no-go for the amplifier program; deterministic consensus criterion, controls-first, graded verdict"
aliases: [amplifier-anchor-headroom-screen, anchor-headroom-screen, phase-70-screen]
category: decisions
tags: [eval-validity, amplifier-vision, measurement, anchor-selection, headroom, phase-70]
parents: [phase-70-anchor-headroom-screen]
created: 2026-05-30
updated: 2026-05-30
source: plan
confidence: high
---

## Context

Phase 69 ran the Phase-68 ruler over 8 real consuming-project transcripts and found the planned live off/on run premature for two independent structural reasons: the ground-truth detector is blind (the anchor surfaces in prose, never inside an AskUserQuestion — 0 in-boundary events on all 8) AND the same-day-close / look-ahead anchor is degenerate (the base model handles it unprompted even in the harness-OFF baseline — `raw` hits OFF 11/22/30 vs ON 4/8/6, i.e. OFF ≥ ON; no lift to detect). The committed `measurability-gate.sh` prints NOT-MEASURABLE and is the trigger any future live run must flip.

The Phase-69 handoff listed Phase 70 as "predicate repair → valid anchor → live run," but that order is wrong and one step is structurally impossible as listed. Predicate-repair-first cannot even be DESIGNED on the current anchor: any boundary broadened to catch it in ON also catches it in OFF (the look-ahead phrase is in the OFF baseline more than in ON), collapsing to raw-text matching that discriminates nothing (`buried_phrase_outside_escalation` is the guard fixture). You cannot repair the detector until you know *where a valid anchor surfaces*. Anchor SELECTION is upstream of measurement — `VALID-MEASUREMENT.md:41` plus a high-trust harvested lesson: *an anchor is degenerate-for-lift iff the base model already produces the correct behavior unprompted in the OFF baseline, so a candidate must pass an OFF-baseline headroom screen before any off/on experiment is designed.*

This is also the binding question for the whole amplifier-measurement program, which is now five mostly-negative phases (65–69) and keeps hitting the same wall — the strong base model leaves little measurable headroom on commodity work (the Phase-59 → 61 → 69 lesson at rising generality). So before any more detector engineering or any expensive live run, the cheapest decisive thing is to find whether even ONE non-commodity single-decision anchor has real headroom.

## Decision

**Approach A — build AND run a single-decision anchor-headroom screen.** User-approved at the direction gate via AskUserQuestion on 2026-05-30 (forks "step back / redirect to product" and "predicate repair anyway" rejected; predicate-repair-first is structurally blocked). The screen tests anchor EXISTENCE: does the harness-OFF base model OMIT the correct behavior unprompted on any candidate, leaving room the harness could plausibly fill? An adversarial approach review scored the un-fixed design 4/10 (it risked being the 6th negative meta-phase); all five fixes are adopted:

1. **Deterministic consensus criterion, not a judge.** Each anchor carries a pre-registered deterministic check of one or more NAMED clauses (regex/structural over the model output). Runs fixed at n=5. HAS-HEADROOM iff the check FAILS in ≥4/5 with the SAME clause-id failing; DEGENERATE iff PASSES in ≥4/5; else UNSTABLE → quarantine. Consensus-by-clause, not OR-of-failures — because OR + run-to-run noise inflates false HAS-HEADROOM (= false continue, the costliest error; the Phase-58 n=1 false-positive is the scar this guards).

2. **Pure-reasoning anchors only.** A bare subagent differs from real harness-off in tool access (the confound that retired `eval/comparison`'s A-vs-C arm). Restricting to anchors whose correct behavior needs no tool makes the bare-subagent proxy valid and isolates harness-relevant headroom from a subagent capability gap; tool-gap-vulnerable candidates are quarantined with the reason stated.

3. **Drop the long-horizon / constraint-retention class from THIS screen.** A one-shot subagent cannot surface multi-turn retention degradation (where process-headroom would live) — a DEGENERATE verdict there is uninterpretable. Explicitly deferred to a future phase with a genuine multi-turn substrate. Phase 70 scopes to single-decision anchors; the null is scoped accordingly.

4. **Three controls, including the contested middle (controls-first checkpoint).** NEGATIVE = the known-degenerate look-ahead anchor (must screen DEGENERATE). POSITIVE = a constructed anchor requiring an unknowable fact (must screen HAS-HEADROOM). MIDDLE = a known-partial ~50/50 anchor (must screen UNSTABLE *and reproduce that on a blind re-run* — proving the screen QUARANTINES the contested band rather than drifting to a false HAS-HEADROOM). Any control misbehavior → STOP, the screen instrument is broken.

5. **Graded, priors-skeptic-proof verdict.** Candidate list + frozen shasum-pinned OFF prompts + per-anchor checks + the `base-model:` identity all pre-registered and COMMITTED before any run (the pre-registration commit must be a git ancestor of the first verdict commit — so the apparatus is fixed before the results it judges). Candidates seeded from the headroom priors (genuinely-novel / post-cutoff / proprietary — weak parametric knowledge — plus domain-nuance). Verdict ladder: ≥1 NATURAL anchor HAS-HEADROOM → CONTINUE (Phase 71 inherits a validated anchor); no natural but the ENGINEERED-FAVORABLE anchor HAS-HEADROOM → "headroom only under construction, not real work" → PARKED pending new priors; even the engineered-favorable DEGENERATE → STRONG TERMINATION.

The screen is harness-OFF ONLY; producing any harness-ON measurement or lift estimate is out of scope (a separate gated phase). The output is a frozen empirical record under `eval/amplifier/anchor-screen/`, not wired into `make test` / `make eval` (those stay the binary gates at 19 scripts / 52 scenarios). No harness-value claim anywhere: HAS-HEADROOM means lift is POSSIBLE, never that lift exists (a necessary, not sufficient, condition).

## Consequences

- **Decisive in either direction.** Either Phase 71 inherits a deterministically-validated anchor it can build a real off/on experiment on, or the program receives a graded null (PARKED / TERMINATE) that a priors-skeptic cannot wave away — inconclusiveness itself becomes a recorded interpretable state (UNSTABLE/quarantine), not a shrug. This is the burden-of-proof-on-the-feature discipline that turned the Phase-59 false-positive into an honest cut.
- **Pre-registration forces an intra-phase commit.** T1 (the apparatus + pre-registration) commits before T2/T3 produce verdicts, so the anti-retrofit guard (`git merge-base --is-ancestor`) can pass. A whole-phase single commit would defeat pre-registration.
- **The measurability gate is unaffected this phase.** The screen produces a valid ANCHOR; it does not itself flip `measurability-gate.sh` (which operates over transcripts a live run would produce). A CONTINUE verdict makes predicate-repair + the live-run designable in Phase 71; the gate flips only after that run exists.
- **Honest scope of a null.** A null here rules out single-decision headroom under the seeded priors only — it does NOT close the long-horizon / process-retention question, which is explicitly deferred to a multi-turn substrate. "Termination" language is reserved for the engineered-favorable-also-DEGENERATE case.

## Realized Result — PROGRAM-VERDICT: TERMINATE

The screen ran (n=5 per anchor, deterministic consensus). The controls validated the instrument (negative→DEGENERATE, positive→HAS-HEADROOM, middle→stability STABLE). Then **all four candidates screened DEGENERATE** — the three natural AML anchors (structuring, UBO indirect-aggregation, sanctions transliteration) AND the engineered-favorable (the EU AMLR €10,000 cash cap). The base model (claude-opus-4-8, bare) produced the correct behavior unprompted in 5/5 runs on every one. The **only** anchor with headroom was the positive control, whose answer is a fact that does not exist (the fictional Zephyr Act).

Per the pre-registered ladder, even-the-engineered-favorable-DEGENERATE ⇒ **TERMINATE** the single-decision anchor measurement program. The discriminating variable is not reasoning quality or domain difficulty (the model does the subtle multiply-and-sum, the structuring aggregation, the transliteration logic unprompted) — it is *unknown facts*. Single-decision harness headroom for a frontier model lives only in facts the model cannot know, which is a RETRIEVAL problem, not a reasoning-harness one. This extends the Phase-59 commodity-knowledge lesson to even niche-looking AML calls. See `eval/amplifier/anchor-screen/screen-record.md`.

## Handoff / disposition

TERMINATE is scoped to *single-decision anchor measurement of harness lift*. It does NOT close (and this screen could not test):

- **Retrieval on genuinely-unknowable facts** — the positive control proves headroom is reachable for proprietary/post-cutoff/fictional facts; that is the long-standing Phase-59 untested sweet spot (needs real proprietary data + an absorb pipeline). A future measurement of harness/retrieval value must use a *genuinely-unknowable-to-the-model* anchor, not a knowable regulation. **decidable-when:** a non-commodity corpus + absorb pipeline exists to source real proprietary/post-cutoff anchors.
- **Long-horizon / multi-turn process-retention** — explicitly dropped from this screen (one-shot subagent can't surface it). **decidable-when:** a multi-turn substrate exists to run constraint-set-then-test-after-interposed-work probes.
- **The harness's process/discipline value** (lifecycle gates, context retention, enforcement) — never a single-decision-anchor property; assess on its own terms, not via this measurement line.

There is **no Phase 71 predicate-repair / live off/on run** on a single-decision anchor: the screen found no valid anchor to carry it. The amplifier-measurement line, as a single-decision-anchor program, is closed. The kit reverts to assessing the harness on process merits and to the remaining engineering roadmap.

Related: [[amplifier-representativeness-audit]] (Phase 69 — the audit this screen acts on), [[amplifier-measurement-instrument]] (Phase 68 — the ruler), [[cut-active-research-step-2-7]] (the commodity-knowledge / no-headroom precedent this extends), [[roadmap-decidable-when]].
