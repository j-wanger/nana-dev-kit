---
title: "Phase 86: Ceremony Lift Measurement"
aliases: [ceremony-lift, phase-86]
category: phases
tags: [measurement, eval, ceremony, subtraction, amplifier, dev-plan, spec, dev-debrief]
parents: []
created: 2026-06-10
updated: 2026-06-10
source: plan
status: active
scope: ["eval/ceremony-lift/**"]
entry_criteria: "Phase 85 delivery accepted; edge-screener available as consuming-project measurement context"
exit_criteria: "The spec's 8 machine-checkable criteria via eval/ceremony-lift/run-exit-criteria.sh (specs/phase-86-ceremony-lift-measurement.md); criteria 2/4/6 N/A-by-early-exit reporting pre-registered"
---

# Phase 86: Ceremony Lift Measurement

## Objective

Evaluate whether the kit's time-consuming process steps (dev-plan, spec generation, reviewer
dispatches, dev-debrief) provide measurable lift over a minimal alternative (assumption-bounded
exploratory development with hooks as guardrails), and decide keep/trim/cut per step. Extends the
amplifier program (Ph70/71/77/78/80 nulls on information re-presentation) and the prune-on-value
subtraction method (Ph83) from injected knowledge and installed components to the CEREMONY STEPS
themselves.

## Approach (planned 2026-06-10)

Tiered screen, episodes conditional — full design in [[ceremony-lift-tiered-screen]] (high);
spec `specs/phase-86-ceremony-lift-measurement.md` (nana:approved). Stage 1 deterministic
in-repo: pre-registration committed-then-FROZEN (byte-unchanged anti-retrofit), ceremony cost
baseline FIRST (raw + cache-adjusted tokens, wall-clock, interruptions; keep-by-immateriality
early exit), then an admissibility-ruled demand-evidence table (outcome-grade requires
orchestrator re-execution of the deterministic gate against recoverable pre-fix state; agent
prose is candidate-generation only; consumption-grade capped at cut-candidate). Stage 1 mints
NO verdicts (gate A1 round 2): the maintainer takes keep/trim/cut/ambiguous positions at the
HARD checkpoint (task 7), with agent-counterfactual residual caveat column + MDE arithmetic.
Stage 2 (bundle full-ceremony vs assumption-gate+hooks contrast on burnable edge-screener
Phase 10, twin worktrees, leak canary, positive control, deterministic ship criteria; n=1
confirms cut-candidate→trim-trial only) fires only on checkpoint go. VERDICTS-ONLY phase:
no kit component modified (check-verdicts-only.sh vs pinned base 5360486); cuts route to a
gated follow-on with removal checklists. 8 tasks (M/L/M/M/M/M/M/M); the only L is the cost
extractor (task 2).

## Scope

- `eval/ceremony-lift/**` (new measurement apparatus, repo-only, frozen on completion)
- This article's `## Maintainer Verdicts` block (written at the task-7 checkpoint)
- Read-only subjects: `templates/.claude/skills/{dev-plan,spec,dev-debrief}/**`; session
  transcripts (parsed programmatically, never loaded into agent context)
- Stage-2 conditional run context (checkpoint-gated, out-of-repo): `/Users/jwang/edge-screener`

## Exit Criteria

- [ ] The spec's 8 machine-checkable criteria pass via `eval/ceremony-lift/run-exit-criteria.sh`
      (criteria 2/4/6 carry a pre-registered N/A-by-early-exit reporting mode, recorded at the
      checkpoint if the keep-by-immateriality branch fires)

## Constraints

- Pre-registration FROZEN after its task-1 commit — byte-unchanged between its add-commit and
  the evidence-table's add-commit; any mid-phase wording edit fails the phase.
- Phase-80 measurement hazard: clean-context measurement CANNOT run inside nana-dev-kit
  (always-loaded working-knowledge leaks answers) — stage-2 episodes run in edge-screener.
- Historical evidence supports COST claims + per-event re-executed marginal catches only —
  never correlational ceremony-on/off lift comparisons (selection bias; the corpus has zero
  true minimal-arm sessions).
- Controls before evidence: hand-labeled cost-extractor session; 5 blind tabulator seeds
  against a never-read answer key. Control failure after 2 fix attempts = instrument-dead STOP.
- 2-gate ceremony model (Ph39) and assumption-approval direction gate (Ph81) are the
  current-state baseline being measured, not assumed valuable.

## Notes

Stub created 2026-06-10 by dev-plan state loader; populated same day at planning. Direction
gate approved via assumption positions (A1 revised at round 2: stage 1 mints no verdicts) +
two reviewer rounds.

## Maintainer Verdicts

Taken at the task-7 HARD checkpoint, 2026-06-10, on the committed cost table
(12 sessions, control 13/13) + evidence table (44 rows, check ALL PASS) with caveat
columns and MDE arithmetic presented. Closed enum; stage 1 minted no verdicts.

VERDICT: dev-plan-orchestration=trim
VERDICT: spec-generation=ambiguous-stage-2
VERDICT: approach-reviewer=keep
VERDICT: plan-reviewer=keep-by-immateriality
VERDICT: review-gate-reviewer=underpowered-decide-by-arithmetic
VERDICT: debrief-capture=trim
STAGE-2: go
STAGE-2-ROUTING: follow-on

Rationale notes (maintainer positions, agent-recorded):
- dev-plan-orchestration trim: assumption-vote gate untouched (4/4 admitted ledger
  bits — strongest evidence in the table); ride-along trim candidates queued for the
  follow-on: active-knowledge re-presentation (amplifier-null class) + state-loader/
  artifact-writer heft.
- spec-generation ambiguous-stage-2: structurally undecidable in stage 1 (constraints
  fold pre-commit); the episode contrast is its decision instrument.
- approach-reviewer keep: 5.4% adj is cheap for a design-flaw screen; Ph80 candidate
  (4 CRITICAL flaws folded pre-pre-reg) plausibly paid for all 5 dispatches; wall%
  span-inflation noted.
- plan-reviewer keep-by-immateriality: 0.8% adj / 0.4% wall — below every
  pre-registered materiality floor.
- review-gate-reviewer underpowered-decide-by-arithmetic (keep direction): 1 fully
  re-executed marginal catch / 3 dispatches; ~600k adj tokens/phase premium vs the
  instrument-dead defect class (historically 8-33 phases undetected). Zero-alone cut
  barred by pre-registration.
- debrief-capture trim: operational half (state reconciliation, delivery gate) kept;
  knowledge-capture half (working-knowledge seeding ~10k tokens/session, journal
  prose, memory bridge) queued as the follow-on's prime cut candidate — consumption
  evidence cannot support keep for the re-presentation class.
- Stage 2 go as follow-on phase: spec-generation contrast on burnable edge-screener
  Phase 10; twin worktrees, leak canary, positive control, deterministic ship
  criteria, n=1 confirms cut-candidate→reversible trim-trial only.
