---
title: "Phase 78 complete — Skill-Crystallization Headroom Screen: DEGENERATE both arms → TERMINATE"
aliases: ["2026-06-04-phase-78-skill-crystallization-headroom-screen"]
category: journal
tags: [eval-validity, amplifier-vision, measurement, headroom, skills, crystallization, verifier-independence, edge-screener]
created: 2026-06-04
updated: 2026-06-04
---

# Phase 78 complete — Skill-Crystallization Headroom Screen

**PROGRAM-VERDICT: TERMINATE.** Both real candidates DEGENERATE; the capability→skill crystallization
module is dead-on-arrival on the tested candidates. Repo-only `eval/amplifier/skill-screen/`, frozen.

## The question
After the decision-retention line closed null across all three regimes (Ph70/71/77), Jake's real-usage
observation surfaced a new axis: the kit captures knowledge (→ wiki) and lifecycle (→ dev-wiki journal)
but has no route for capturing CAPABILITY (→ a reusable skill bundling tested tooling) — and that
crystallization only happens *inside* nana-dev-kit, never in a consuming project (edge-screener) unless
a phase explicitly targets it. Before building such a module, screen whether it would pay: does a
candidate tooling artifact embed NON-RECOVERABLE correctness a bare model fails to reproduce even given
the RECOVERABLE CORPUS (`R_A` = interface + goal + call sites) a non-crystallized project actually has?

## Method (verifier-independent, NO-LLM)
Cloned the frozen anchor-screen consensus apparatus (n=5/threshold=4 byte-verbatim); only `run_check`
swapped to dispatch to per-candidate harnesses that RUN the hidden spec-implied tests against an OFF
re-derivation, emitting PASS|FAIL:<assertion-id>. OFF = closed-book subagents given only `R_A` (no
repo/tool access). Guards: `.offleak` leak-check (C4/M5), spec-implied = entailed-by-`R_A` with a quoted
sentence per test (C3), candidate correctness located+quoted from the test file (C1), 4 controls (M3),
UNSTABLE disposition (M2). Pre-registration committed (`3f6a0cb`) BEFORE any OFF run; ancestor guard.

**Design hardened pre-registration by an agent-internal adversarial review** that read the candidate
artifacts and found 4 CRITICAL flaws in the first cut: C1 (I'd mis-attributed `check-install-drift.sh`'s
correctness — the /var canonical-path fix is Ph76's session-start.sh, not the drift script); C2 (OFF on
a lossy brief biases toward false HAS-HEADROOM — fixed to the recoverable corpus, the prior screens' bar);
C3 (the spec-implied split was retrofittable — mechanized via quoted entailing sentences); C4/M5 (no leak
guard — ported leak-check.sh). All folded in before the prereg commit.

## Candidates + result
- **edge-eligibility** (domain — point-in-time survivorship `eligible_on`, the inclusive-through-`d`
  rule; prior HAS-HEADROOM): **DEGENERATE 4/5**. The headline surprise — given a corpus that stated the
  GOAL (book the delisting crater; the name must be HELD when it lands) + the dependency fact
  (`members_on(d)` drops a name on its removal date `d`), the bare model DERIVED the inclusive-through-`d`
  add-back in 4/5 closed-book samples, with independent variable names and structures (verified not
  copied — the one near-match reused only the obvious name `removed_today` with a wholly different
  docstring/loop). The single failure was on a basic `re-added` assertion, not the survivorship crux.
- **nana-drift** (general — drift-comparator core; prior DEGENERATE): **DEGENERATE 5/5**, as predicted.
- **Controls** (gate the verdict, by pass-count): negative 5/5 PASS ✓; positive-unknowable 0/5 PASS ✓
  (the bare model REFUSED to invent the project's unknowable `rev-7f3a` token — it RAISED
  NotImplementedError/LookupError/a custom unavailable-exception rather than hallucinating, the Ph71
  "refused to invent an absent sentinel" echo, proving the instrument registers non-recoverable content
  as FAIL); recoverable-fully-specified 5/5 PASS ✓. Instrument LIVE, not INSTRUMENT-DEAD.

## Headline + how it extends the program
**A tooling artifact's correctness IS in the goal that motivated it** — state the goal and the model
re-derives the implementation. This extends the amplifier finding from *decisions* (Ph70/71/77) to
*capability*: harness headroom does not live in re-presenting what the model can recover. The
capability-crystallization line now closes alongside the decision-retention line. The kit's existing
capture routes are kept on operational grounds; no module built (burden-of-proof + subtraction, Ph64/72).

## Caveats (load-bearing)
1. **Conditional on the explicit-goal `R_A` framing** (Jake's pre-registered AskUserQuestion choice). The
   corpus stated the goal but never the implementation; under a weaker goal-only corpus the survivorship
   boundary might have shown headroom. Honest finding: *recoverable-from-an-explicit-goal*, not
   *recoverable-from-nothing*.
2. **Two candidates, not a census.** The surviving untested avenue stays the Ph70 one — genuinely
   PROPRIETARY/POST-CUTOFF correctness derivable from NO fair corpus. The positive-unknowable control
   proves the instrument WOULD flag such a case (0/5 recovered the unknowable token); these candidates
   were not such.
3. **Router reframe** (now moot, recorded): had a candidate shown headroom, the vessel question
   (regression test / lint rule vs skill) re-opens for a future genuinely-proprietary HAS-HEADROOM result.

## Verification
make test "All tests passed"; make eval 52/52; apparatus repo-only → no registration/settings/README/
firing-coverage churn; subjects (edge-screener `membership.py`/`eligibility.py` + the kit's
`check-install-drift.sh`) byte-identical pre/post; prereg `3f6a0cb` ⊂ HEAD; NO LLM in the scoring path.
4/4 tasks ✓. Apparatus frozen, sibling to anchor-screen/retention-screen/xsession-screen.
