---
title: "Ceremony Lift: Tiered Screen Before Episode Experiment"
aliases: [ceremony-lift-tiered-screen, ceremony-lift-measurement-design]
category: decisions
tags: [eval-methodology, ceremony, subtraction, demand-evidence, amplifier]
parents: [phase-86-ceremony-lift-measurement]
created: 2026-06-10
updated: 2026-06-10
source: plan
confidence: high
---

## Context

Jake asked whether the kit's time-consuming process steps (dev-plan, spec generation,
reviewer dispatches, dev-debrief) actually provide lift, and whether the kit should
switch to assumption-bounded exploratory development with hooks as guardrails.

Priors constrain the design hard:
- Five amplifier nulls (Ph70/71/77/78/80): re-presenting recoverable information is
  null — directly indicts debrief's knowledge-capture half (working-knowledge is
  ~10k tokens loaded every session).
- Spec reform (+1.75 for open-ended over prescriptive, Ph55) is measured evidence that
  LESS prescription can outperform more — the minimal arm has a head start in one regime.
- But the Phase-85 reviewer caught a real instrument-dead class (stale 4b predicates)
  that make test did NOT catch — outcome-grade evidence FOR the review step.
- Ph80 hazard: clean-context comparison cannot run inside nana-dev-kit (working-knowledge
  leaks answers) — episodes must run in a consuming project.
- Episode experiments are expensive (n≥3 per arm = 6+ full dev episodes) and Ph45-49 LOO
  prior art says per-component attribution stays noisy even then.
- IRON-001: the ceremony's own cost (tokens/wall-clock per step per phase) has NEVER been
  baselined — the lift-per-cost question is not yet well-posed.

The bundle is heterogeneous; "switch wholesale vs keep everything" is a false binary.

## Decision

Phase 86 runs a TIERED SCREEN, episodes conditional (Jake confirmed 2026-06-10; also
confirmed edge-screener Phase 10 is burnable as the stage-2 anchor episode if it fires).

Stage 1 (deterministic, in-repo, frozen apparatus at eval/ceremony-lift/):
1. Pre-registration committed BEFORE any evidence tabulation (anti-retrofit ancestor
   guard, amplifier convention): per-step verdict thresholds; cost-materiality threshold
   in the units transcripts yield (tokens AND wall-clock AND synchronous human-interrupt
   count — gate interruptions are the cost the maintainer feels); evidence taxonomy incl.
   the [uses:N] caveat (agent-maintained counters, unknown increment discipline —
   admissible only because consumption-grade is capped at cut-candidate); closed verdict
   enum; CORPUS definition (fixed phase window + mechanical enumeration of ALL reviewer/
   spec/debrief dispatches including zero-catch ones — the denominator; guards prior-
   leakage from always-loaded working-knowledge into row selection); the ADMISSIBILITY
   rule (below); stage-2 verdict-transition authority (below).
2. Ceremony cost baseline per step (dev-plan, spec, approach/plan/review-gate reviewers,
   debrief) from session transcripts (~80 .jsonl with per-message usage + timestamps;
   step boundaries via Skill-invocation entries) — IRON-001 precondition. SEQUENCED AS
   TASK 1 so the keep-by-immateriality early exit can fire before tabulation effort.
3. Per-step demand-evidence verdict table with a TWO-CLASS evidence taxonomy:
   - outcome-grade: marginal catches — findings no downstream deterministic gate
     (make test, make eval, exit-criteria runner) would have caught; spec exit-criteria
     failures that changed implementation. ADMISSIBILITY: a marginal catch counts
     outcome-grade ONLY if the orchestrator re-executes the deterministic gate against a
     recoverable pre-fix state (git ancestor or transcript-extracted file state) and it
     passes-where-it-should-fail; otherwise the row DOWNGRADES to ambiguous (downgrade
     direction pinned in pre-registration). Agent-authored prose (journal articles,
     commit messages) is candidate-generation only, never verdict evidence — the
     qa-sweep standard applied to historical evidence.
   - consumption-grade: working-knowledge [uses:N] counters, retrieval hits, artifact
     reads. Consumption-grade can mint cut-candidates but can NEVER mint a definitive
     KEEP for re-presentation-class outputs (the amplifier-null class).
   VERDICT AUTHORITY (revised at gate, A1 round 2): stage 1 mints NO verdicts. The
   deliverable is the evidence table (per-step rows, evidence class labeled, agent-
   counterfactual residual as an explicit caveat column) + the cost table. The
   maintainer takes keep | trim (incl. make-conditional/risk-gated) | cut | ambiguous→
   stage-2 positions at the hard checkpoint — the closed enum is the maintainer's menu,
   not the tabulator's output. Pre-registration constrains which evidence class can
   SUPPORT which claim (consumption-grade cannot support keep for re-presentation-class
   outputs), not what the verdict is.
4. Controls-first: tabulators must classify seeded synthetic rows (one known marginal
   catch, one known test-catchable finding, one known consumption-only use) correctly
   before real rows count — else INSTRUMENT-DEAD. Extends to the cost-extraction script:
   positive control on one session of known step composition before any cost row counts
   (Ph84 positive-control-before-matrix-output standard).

Hard checkpoint (go/no-go): evidence table + cost table presented; the MAINTAINER takes
per-step positions from the closed enum; positioned cuts/trims queue for a FOLLOW-ON cut
phase (evidence phase ≠ cut phase, prune-on-value pattern); ambiguous steps decide
whether stage 2 fires.

Stage 2 (conditional, out-of-repo via hard checkpoint): bundle-level full-ceremony vs
assumption-gate+hooks contrast; edge-screener Phase 10 as the burnable anchor episode
(twice from same git state in isolated worktrees, ship the better; n=1 informs, never
proves); deterministic outcome metrics first; test-access parity across arms (swe-bench
confound); fresh-runs same round; positive control (a task where ceremony MUST help)
required before any null reads TERMINATE. VERDICT AUTHORITY pre-registered: stage-2
evidence may confirm a cut-candidate into a reversible trim-trial; it may NEVER mint
keep or cut outright at n=1. The "ship the better" decision uses pre-registered
deterministic criteria (tests/exit-criteria/defect counts), never judgment — else
self-grading bias re-enters, contradicting two-phase-eval-methodology.

Alternatives rejected: full episode experiment now (cost without screen; attribution
noisy per LOO prior art); judgment cut without measurement (priors never directly
tested review/spec; Phase-85 reviewer catch is live counter-evidence).

## Consequences

- Phase 86 produces VERDICTS ONLY — no kit component is modified; cuts route to a
  follow-on (prune-on-value round 2 can absorb them). Keeps blast radius zero while
  the evidence is gathered.
- Demand evidence is accepted as a SCREEN, not proof of lift: keep-verdicts on
  consumption-grade evidence alone are disallowed by pre-registration.
- The risk-gated-dial reframing (ceremony cost proportional to phase blast radius via
  the existing lite/standard mechanism) is an allowed trim verdict shape.
- If the cost baseline shows ceremony cost is immaterial (below pre-registered
  threshold), the subtraction premise dies and the phase ends early with a
  keep-by-immateriality outcome — that is a valid, cheap result.
- Stage 2 (if it fires) consumes edge-screener Phase 10 as measurement substrate.
