---
title: "Skill-Crystallization Headroom Screen (Phase 78)"
aliases: ["skill-crystallization-headroom-screen", "phase-78-skill-screen", "skill-screen"]
category: decisions
tags: [eval-validity, amplifier-vision, measurement, headroom, skills, crystallization, tooling, verifier-independence, edge-screener]
parents: [[[cross-session-retention-headroom-screen]]]
created: 2026-06-04
updated: 2026-06-04
source: plan
confidence: high
status: active
---

# Skill-Crystallization Headroom Screen (Phase 78)

## Decision
Before building any capability→skill route (a module that crystallizes a phase's tooling into a reusable project-level skill), run a cheap, deterministic, verifier-independent SCREEN that answers the go/no-go: **does a candidate tooling artifact embed correctness a bare frontier model cannot re-derive from the artifact's own brief?** If yes for ≥1 real candidate → building is justified (Phase 79+). If no across all real candidates (controls validating) → the module is dead-on-arrival; record the null and subtract the idea.

This is the successor to the decision-retention line (Ph70/71/77, all null). Those measured re-presenting *decisions the model recovers*; this measures the *capability/correctness boundary* — the avenue the campaign repeatedly pointed at but never tested. Burden-of-proof-on-the-feature + subtraction test (Phase 64/72 lineage): a new capture module must clear a screen before it ships.

## Why this framing
- **Tooling, not prose.** Crystallizing procedure-prose is the amplifier null in new clothes (the model re-derives procedures unprompted — Ph70 DEGENERATE 5/5). The only value-bearing case is tooling that embeds correctness the model reproduces *plausibly-but-wrongly* one-shot. The screen tests exactly that and nothing softer.
- **Verifier-independent, applied reflexively.** The screen uses the report's own central principle on itself: OFF (bare re-derivation) never sees the artifact or its hidden tests. Scoring runs the artifact's hidden test suite against the OFF output — deterministic, NO LLM.
- **Split prior is the interesting outcome.** General tooling (`check-install-drift.sh`) likely DEGENERATE; domain tooling (edge-screener point-in-time survivorship / no-look-ahead — the textbook silently-wrong-on-re-derivation class) likely HAS-HEADROOM. A SPLIT verdict scopes any future module to domain/correctness tooling, which is itself a sharp finding ("crystallize domain-tooling, not general-tooling").
- **Consuming-project representativeness.** The observed gap is that crystallization happens only inside nana-dev-kit (skills are the product) and never in consuming projects (tooling is a byproduct). Including a real edge-screener artifact as a read-only fixture (Ph77 pattern) tests the gap where it actually lives.

## Method (verifier-independent screen; repo-only `eval/amplifier/skill-screen/`)
> Hardened by an agent-internal adversarial review (2026-06-04) that read the candidate artifacts directly; findings C1–C4/M1–M5 folded in.
- **OFF** = clean subagent given the candidate's **recoverable corpus** `R_A` (public interface/signature + docstring + real call sites + task — NOT the implementation body, NOT the tests), the same recoverable-inputs bar the prior screens used; **n=5** samples. Crucially NOT a lossy hand-brief (review C2 — a brief would measure summary information-loss, biasing toward false HAS-HEADROOM). **Scoring** = run the artifact's HIDDEN spec-implied tests against each OFF output (`check.sh`, NO-LLM, `--selftest` flips both ways, n=5/threshold=4 cloned from `anchor-screen/`).
- **Leak guard** (review C4/M5): `leak-check.sh` + per-candidate `.offleak` (the answer-tokens the spec-implied tests assert ∪ the tests' fixture literals) — `R_A` must contain none of them. Brackets the corpus into the legitimate band: rich enough to be a fair counterfactual, not stating the answer (prevents both false TERMINATE-by-leak and copy-passing).
- **Spec-implied partition, mechanized** (review C3): a test is spec-implied iff its behavior is ENTAILED by `R_A`, and the pre-registration QUOTES the entailing corpus sentence per test; un-citable tests are unstated-edge BY RULE (failure → SPEC-INCOMPLETE, never headroom). Resolves the false-HAS-HEADROOM-from-spec-incompleteness confound without a free human call — the Ph77 token-cherry-pick hazard, closed.
- **Four controls** (review M3 added the symmetric one): negative (trivial — OFF must pass; else lobotomized), positive-unknowable (project value absent/unguessable from `R_A` — OFF must fail; else corpus leaking), recoverable-fully-specified (correctness fully entailed by `R_A` — OFF must pass; else corpora systematically too thin and every HAS-HEADROOM suspect), plus the per-candidate `.offleak`. Any violation ⇒ `INSTRUMENT-DEAD`.
- **Candidate selection by criterion, not prose** (review C1): each candidate must have a locatable `T_A` test function encoding its non-obvious correctness, QUOTED in the prereg — no pinning a property absent from the test file (the `check-install-drift.sh` "/var symlink" claim was wrong; its real embedded correctness is the bounded exclusion allow-list + fail-open + not-installed-skip).
- **Verdict ladder:** per-candidate DEGENERATE / HAS-HEADROOM / UNSTABLE (+ orthogonal SPEC-INCOMPLETE flag); UNSTABLE counts as not-measurable and never votes toward TERMINATE (review M2). Program `^PROGRAM-VERDICT: (TERMINATE|HAS-HEADROOM|INSTRUMENT-DEAD|INCONCLUSIVE)`. Cost-delta recorded-only, no verdict logic reads it (review M4). Pre-registration (quoted candidate tests, shasum-pinned `R_A`, entailment-cited partition, controls, n=5/threshold=4) committed BEFORE runs, ancestor-guarded.

## Live alternative (the router reframe — recorded, not pre-decided)
A HAS-HEADROOM artifact does not auto-imply "build a skill module." A "never reintroduce this bug" correctness may be better preserved as a regression TEST or lint rule (fires automatically) than as a skill (must be remembered + invoked). If the screen shows headroom, the Phase-79 deliverable may be a *correctness-preservation router* (test / lint / skill per artifact), not a skill-crystallization module. The screen result feeds that fork; it does not foreclose it.

## Rejected alternatives
- **Build the module, then measure.** Reverses the campaign's burden-of-proof discipline; risks shipping capture machinery the screen would have killed (Phase 64/72 cut exactly this class).
- **End-to-end downstream-task ablation as the primary test (framing B).** Realistic but fuzzy (needs a downstream task + softer success judgment). Folded in as the expensive follow-on, gated on this cheap necessary-condition screen showing headroom (gate-before-spend, Ph77 lineage).
- **Crystallize procedure-prose too.** Predicted DEGENERATE by Ph70; excluded from the candidate set to keep the screen pointed at the only value-bearing case.
- **nana-dev-kit-only candidates.** Less representative — crystallization already happens here; the gap lives in consuming projects, so ≥1 edge-screener candidate is required.

## Caveats
- A candidate's own test suite is the correctness oracle; if a test is itself tautological/weak (the TTDD anti-pattern the screen is about), it is excluded from the spec-implied subset — the screen must not inherit the very flaw it measures.
- The `R_A` band is the load-bearing judgment: too rich (states the answer) → false TERMINATE; too thin (starved) → false HAS-HEADROOM. The `.offleak` guard + the recoverable-fully-specified control + the per-candidate inclusion log keep it auditable, but the band itself is the thing a reviewer should check hardest.
- A TERMINATE here closes the capability-crystallization line as DEAD-ON-ARRIVAL the same way Ph70/71/77 closed decision-retention; the kit's existing knowledge/lifecycle capture routes are kept on operational grounds.

## Result
**PROGRAM-VERDICT: TERMINATE** (2026-06-04). Both real candidates DEGENERATE; do NOT build a capability→skill module.
- **edge-eligibility** (domain — PIT survivorship; prior HAS-HEADROOM): **DEGENERATE 4/5**. Given the explicit-goal corpus (book the delisting crater + the `members_on(d)`-drops-at-`d` dependency fact), the bare model DERIVED the inclusive-through-`d` survivorship add-back in 4/5 closed-book samples — independent variable names/structures, verified not copied. The one failure (#5) was on a basic `re-added` assertion, not the survivorship crux.
- **nana-drift** (general — drift-comparator core; prior DEGENERATE): **DEGENERATE 5/5**, as predicted.
- Controls valid (negative 5/5 PASS; positive-unknowable 0/5 PASS — the bare model REFUSED to invent the unknowable project token, raising rather than hallucinating; recoverable-fully-specified 5/5 PASS) ⇒ instrument LIVE, not INSTRUMENT-DEAD.
- **Headline:** a tooling artifact's correctness IS in the goal that motivated it — when the goal is stated, the model re-derives the implementation. Extends the amplifier finding from decisions (Ph70/71/77) to capability: harness headroom does not live in re-presenting what the model can recover.
- **Scope condition (load-bearing):** conditional on the explicit-goal `R_A` framing (Jake's choice). Under a goal-only corpus that did not name the crater, the survivorship boundary might have shown headroom. The surviving untested avenue stays the Ph70 one — genuinely PROPRIETARY/POST-CUTOFF correctness the model cannot derive from ANY fair corpus (the positive-unknowable control proves the instrument WOULD flag such a case as headroom; these candidates were not such).
- Apparatus frozen repo-only `eval/amplifier/skill-screen/`; subjects byte-identical pre/post; prereg `3f6a0cb` ⊂ HEAD; NO LLM in scoring; make test + make eval 52/52 green at unchanged surface. Confidence raised to high. See `screen-record.md` + `classification.md`.

## Source
Phase 78 plan (2026-06-04). Direction approved by Jake across the post-Phase-77 planning thread ("plan Phase 78 as that screen"). Successor to [[cross-session-retention-headroom-screen]]; applies the verifier-independence principle surfaced in the domain-harness-engineering thought-exercise to the kit's own capability-capture question.
