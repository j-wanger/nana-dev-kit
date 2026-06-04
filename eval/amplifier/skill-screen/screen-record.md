# Screen Record — Skill-Crystallization Headroom Screen (Phase 78)

PROGRAM-VERDICT: TERMINATE

## What was measured
Whether crystallizing a phase's TOOLING into a reusable skill adds value over bare re-derivation — i.e.
whether a candidate tooling artifact embeds NON-RECOVERABLE correctness a bare frontier model fails to
reproduce even when given the RECOVERABLE CORPUS (`R_A` = interface + docstring-goal + call sites + task)
a non-crystallized consuming project actually has, but NOT the implementation or its tests. The cheap
go/no-go before building any capability→skill module. Repo-only, NO-LLM, verifier-independent. Successor
to the decision-retention line (Ph70/71/77, all null) — this tests the capability/correctness boundary.

## Result
- **edge-eligibility** (domain — point-in-time survivorship eligibility; prior HAS-HEADROOM): **DEGENERATE 4/5**.
- **nana-drift** (general — drift-comparator core; prior DEGENERATE): **DEGENERATE 5/5**.
- Controls (gate the verdict): negative 5/5 PASS ✓, positive-unknowable 0/5 PASS (≥4/5 FAIL) ✓,
  recoverable-fully-specified 5/5 PASS ✓ ⇒ instrument LIVE, not INSTRUMENT-DEAD.
- Both measurable real candidates DEGENERATE ⇒ per the pre-registered ladder, **PROGRAM-VERDICT: TERMINATE**.
  The capability→skill crystallization module is DEAD-ON-ARRIVAL on these candidates: do not build it.

## The headline
A tooling artifact's correctness IS in the goal that motivated it — when the goal is stated, the model
re-derives the implementation. The domain candidate was the test: point-in-time survivorship eligibility
(hold a delisted name THROUGH its removal date so the delisting "crater" books on a held position, drop
it strictly after) is the textbook silently-wrong-on-re-derivation correctness. Yet given a corpus that
stated the GOAL (book the crater; the name must be held when it lands) plus the dependency fact
(`members_on(d)` drops a name on its removal date `d`), the bare model derived the inclusive-through-`d`
add-back in 4/5 closed-book samples, with independent variable names and structures. This extends the
amplifier finding from decisions to capability: harness headroom does not live in re-presenting what the
model can recover — neither decisions (Ph70/71/77) nor tooling-correctness whose GOAL is recoverable.

## No harness-value claim
This screen makes NO positive claim that the harness amplifies anything. A TERMINATE means the measured
candidates' correctness is re-derivable from their recoverable corpus, so crystallizing them buys only a
token/latency saving (recorded, secondary), not correctness — and a saved artifact or a one-line note
captures that saving without a capture module's machinery (the subtraction test, Phase 64/72 lineage).

## Caveats (pre-registered + discovered)
1. **Conditional on the explicit-goal `R_A` framing** (Jake's pre-registered choice, AskUserQuestion
   2026-06-04). The corpus stated the GOAL (capture the delisting crater) but never the implementation.
   Under a weaker "goal-only" corpus that did NOT name the crater, the survivorship boundary might have
   shown headroom. The honest finding is therefore: *given a corpus that states the goal + the dependency
   semantics, even subtle survivorship correctness is re-derivable* — recoverability-from-an-explicit-goal,
   not recoverability-from-nothing. This is the load-bearing scope condition.
2. **Two candidates, not a census.** A broader pool could surface a HAS-HEADROOM case. The surviving
   untested avenue is the Ph70 one: genuinely PROPRIETARY / POST-CUTOFF correctness the model cannot
   derive from ANY fair corpus (a magic constant, a non-public algorithm) — the positive-unknowable
   CONTROL proves the instrument WOULD register such a case as HAS-HEADROOM (0/5 recovered the unknowable
   token). These candidates were NOT such — their correctness is derivable from their stated goals.
3. **Router reframe (now moot, recorded for re-trigger).** Had a candidate shown headroom, the next
   question was vessel: a "never reintroduce this bug" correctness is often better preserved as a
   regression TEST or lint rule (fires automatically) than as a skill (must be remembered + invoked).
   A future genuinely-proprietary HAS-HEADROOM result re-opens this fork.
4. **Check-design note** (the Ph71 "target the answer, not the explanation" analog): the positive
   control aggregates as `UNSTABLE` under `check.sh --aggregate` because its 5 FAILs split across
   exception-clauses; its control disposition is by PASS-COUNT (0/5 PASS = ≥4/5 FAIL ✓), not the 3-way
   verdict. Recorded so the UNSTABLE label is not misread as a dead instrument.

## Disposition
The capability-crystallization line is closed as DEAD-ON-ARRIVAL on the tested candidates, alongside the
decision-retention line (Ph70 DEGENERATE, Ph71 TERMINATE-by-summary-robustness, Ph77 residual-0
TERMINATE, Ph78 DEGENERATE). The kit's existing knowledge/lifecycle capture routes (wiki, dev-wiki) are
kept on operational grounds; no capability→skill module is built. Apparatus frozen, repo-only
`eval/amplifier/skill-screen/`; subjects (edge-screener + the kit's drift script) byte-identical pre/post.
Anti-retrofit: pre-registration `3f6a0cb` ⊂ HEAD; n=5/threshold=4; NO LLM in the scoring path.
