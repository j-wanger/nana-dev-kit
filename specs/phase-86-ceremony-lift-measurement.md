<!-- nana:approved 2026-06-10 -->
# Spec: Phase 86 — Ceremony Lift Measurement

## Objective

Assemble per-step evidence (cost baseline + admissibility-ruled demand evidence) sufficient
for the maintainer to take keep/trim/cut/ambiguous positions on the kit's ceremony steps
(dev-plan, spec generation, reviewer dispatches, dev-debrief) at a hard checkpoint — with a
conditional stage-2 episode contrast decided there, not presumed.

## Context

Jake asked whether the kit's time-consuming process steps actually provide lift, and whether
to switch to assumption-bounded exploratory development with hooks as guardrails. Five
amplifier nulls (Ph70/71/77/78/80) indict the information-re-presentation class (debrief's
knowledge-capture half; working-knowledge is ~10k tokens loaded every session); the spec
reform measured +1.75 FOR less prescription; but the Phase-85 reviewer caught a real
instrument-dead defect deterministic gates missed. The bundle is heterogeneous — per-step
verdicts will differ. Ceremony cost has never been baselined (IRON-001 violation). The
Ph80 hazard forbids clean-context behavior measurement in-kit; episode experiments must run
in a consuming project (edge-screener; its Phase 10 confirmed burnable). Direction gate
closed 2026-06-10: A1 accept-round-2 (stage 1 mints NO verdicts — maintainer positions at
checkpoint), A2/A4/A5 accept, A3 accept (transcript-extraction spike defended). Design
decision: .dev-wiki/articles/decisions/ceremony-lift-tiered-screen.md.

## Scope

### In scope
- `eval/ceremony-lift/**` — frozen repo-only apparatus: pre-registration, cost extractor,
  evidence tabulators, seeded controls, tables, exit-criteria runner.
- Read-only access to `~/.claude/projects/-Users-jwang-nana-dev-kit/*.jsonl` transcripts
  (programmatic parsing only), git history, dev-wiki artifacts as evidence corpus.
- Hard-checkpoint verdict block recorded in the phase article + ledger linkage.
- Stage-2 design parameters pre-registered (so a "go" can execute without re-litigating).

### Out of scope
- ANY kit component modification (skills, hooks, templates, modules.json, install.sh) —
  verdicts-only phase; cuts/trims route to a gated follow-on with a per-cut removal
  checklist (settings registration is add/update-only; ghost registrations fail silently).
- Stage-2 episode execution (fires only on checkpoint go; out-of-repo writes
  checkpoint-gated as ever).
- Working-knowledge size compression; memory-layer A5 disposition (prune-on-value round 2).

## Approach

Tiered screen, episodes conditional. Stage 1 is deterministic in-repo evidence assembly:
(1) pre-registration committed BEFORE any tabulation; (2) ceremony cost baseline extracted
programmatically from session transcripts; (3) per-step demand-evidence table under a
two-class taxonomy (outcome-grade requires orchestrator re-execution of the deterministic
gate against a recoverable pre-fix state; consumption-grade is retrospective use/retrieval
and is capped — it cannot support keep for re-presentation-class outputs). Stage 1 mints no
verdicts: the maintainer takes positions from a closed enum at the hard checkpoint, with the
agent-counterfactual residual as an explicit caveat column. Stage 2 (bundle-level
full-ceremony vs assumption-gate+hooks contrast on edge-screener Phase 10, twin worktrees,
deterministic ship criteria) fires only if the checkpoint routes ambiguous steps there.

### Domain Research Questions
1. Which JSONL markers most reliably delimit ceremony steps (Skill invocations, sidechain
   agent files, slash-command entries), and how do subagent transcript files link to parent
   sessions so reviewer-dispatch cost is not undercounted?
2. What is the honest token-cost unit given prompt caching — how should cache-read vs
   cache-write vs fresh-input tokens be weighted so the ~10k always-loaded payload is
   neither ignored nor counted at face value per message?
3. What is the right human-interruption unit (AskUserQuestion calls, permission prompts,
   blocking gate waits) — the cost axis the maintainer actually feels?

## Constraints (CRITICAL)

- Pre-registration committed BEFORE evidence tabulation, enforced by git ancestry (prevents
  retrofitting thresholds/taxonomy to observed evidence — anti-retrofit, amplifier convention).
- Corpus definition pre-registered: fixed phase window with a FROZEN end-commit, mechanical
  enumeration of ALL reviewer/spec/debrief dispatches including zero-catch ones (prevents
  prior-driven row selection — the in-repo cousin of the Ph80 leak), and measurement-session
  artifacts excluded by timestamp/provenance (prevents the experiment's own journals feeding
  the corpus it measures).
- Historical evidence supports COST claims and per-event re-executed marginal-catch claims
  ONLY — never correlational ceremony-on/off lift comparisons (prevents selection-bias lift
  claims: ceremony-heavy sessions were systematically the riskier phases; and the corpus
  likely contains zero true minimal-arm sessions, making the historical baseline cell empty
  by construction).
- Admissibility rule: agent-authored prose (journals, commit messages) is candidate-generation
  only, NEVER verdict evidence; an outcome-grade row requires the orchestrator to re-execute
  the deterministic gate against a recoverable pre-fix state and observe pass-where-it-
  should-fail; unrecoverable rows DOWNGRADE to ambiguous (prevents self-credited lift).
- Token attribution scheme pre-registered (cache-read vs cache-write vs fresh weighting;
  message→step assignment rules) and validated against one hand-labeled session whose
  pipeline totals must match the hand count before bulk processing; cost reported BOTH raw
  and cache-adjusted (prevents order-of-magnitude overstatement from always-loaded cache reads).
- Minimum-detectable-effect arithmetic pre-registered for rare-event steps: the verdict menu
  includes "underpowered — decide on expected-cost arithmetic (historical base rate ×
  cost-of-missed-defect vs step cost)"; "no catches observed" alone is an INVALID cut
  justification (prevents cutting rare-event insurance on a guaranteed-zero small-n).
- Controls-first, extended to seeded ARTIFACTS: the scoring pool is salted with a
  known-worthless (plausible but factually inert) and a known-load-bearing artifact plus the
  three seeded row types (known marginal catch, known test-catchable, known consumption-only);
  no real row counts until all seeds classify correctly — else INSTRUMENT-DEAD (prevents
  motivated scoring in either direction; the maintainer is tired of the time tax and the
  agent authored the artifacts).
- Capture-step (debrief/wiki) benefit is measured by RETROSPECTIVE consumption over the full
  corpus (uses counters, citation trails, retrieval events), never a forward window
  (prevents mechanically-zero benefit for lagged-payoff steps).
- Stage 1 mints NO verdicts; the closed enum (keep | trim incl. risk-gated-conditional |
  cut | ambiguous→stage-2) is the maintainer's checkpoint menu (gate A1 round 2).
- Stage 2, if it fires: out-of-repo writes only via hard checkpoint; per-run snapshot/branch
  of edge-screener with TESTED restoration; a leak canary (a question only kit-internal docs
  answer) run in every "clean" condition before its results count; a POSITIVE CONTROL (a task
  where ceremony MUST help) required before any null reads TERMINATE rather than
  instrument-dead; test-access parity across arms; deterministic pre-registered ship criteria;
  n=1 may confirm a cut-candidate into a reversible trim-trial, never mint keep or cut outright.
- Transcripts parsed programmatically (jq/python) only — never loaded into agent context
  (prevents context overflow AND the agent re-reading its own prose as evidence).
- Frozen apparatus: everything under eval/ceremony-lift/, repo-only; harness version under
  test frozen for the corpus window (kit keeps evolving — version skew noted per row if any).

## Success Vision

An evidence table a skeptical reader could audit end-to-end: every outcome-grade row
traceable to a re-executed command on a recoverable state, every denominator visible, every
caveat (agent-counterfactual residual, version skew, cache adjustment) explicit rather than
buried. A cost table in the units the maintainer feels — tokens (raw and cache-adjusted),
wall-clock, and interruptions — that makes the keep-by-immateriality early exit decidable at
a glance. Checkpoint verdicts that are genuinely the maintainer's, with the screen having
narrowed stage 2 to only the steps where episode evidence is worth burning Phase 10. The
apparatus itself cheap enough that the measurement never becomes the process theatre it is
auditing. An honest "underpowered" where the data cannot speak is a success; a confident
wrong verdict is the only failure.

## Exit Criteria (machine-checkable)

All aggregated by `bash eval/ceremony-lift/run-exit-criteria.sh` (exit 0 iff all pass):

- [ ] `test -f eval/ceremony-lift/pre-registration.md && for s in '## Corpus' '## Admissibility' '## Token attribution' '## MDE' '## Verdict menu' '## Stage-2 parameters' '## Step list' '## Class membership'; do grep -q "$s" eval/ceremony-lift/pre-registration.md || exit 1; done` (Step list pins the canonical ceremony-step enumeration — dev-plan incl. state loader, spec incl. adversarial+Tier-1, approach reviewer, plan reviewer, debrief review-gate, debrief capture; Class membership pins which steps' outputs are re-presentation-class)
- [ ] `git merge-base --is-ancestor $(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/pre-registration.md) $(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/evidence-table.md) && git diff --quiet $(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/pre-registration.md) $(git log --diff-filter=A --format=%H -1 -- eval/ceremony-lift/evidence-table.md) -- eval/ceremony-lift/pre-registration.md` (pre-registration strictly precedes evidence AND is byte-unchanged between the two — no stub-then-amend retrofit)
- [ ] `bash eval/ceremony-lift/test-cost-extractor-control.sh` (hand-labeled known-composition session: pipeline totals match hand count)
- [ ] `bash eval/ceremony-lift/test-tabulator-controls.sh` (all five seeds classify correctly — marginal-catch admitted, test-catchable rejected, consumption-only capped, worthless artifact scored inert, load-bearing artifact scored load-bearing — with seed identities held in a separate answer-key file the tabulator never reads: classification is blind, the control script joins against the key)
- [ ] `bash eval/ceremony-lift/check-cost-table.sh` (one row per step in the pre-registered Step list × {tokens-raw, tokens-cache-adjusted, wall-clock, interruptions}; no empty cells)
- [ ] `bash eval/ceremony-lift/check-evidence-table.sh` (row count == enumerated dispatch count from the frozen corpus manifest AND the manifest matches the pre-registered hand-counted dispatch count for the one independently-counted anchor phase; every outcome-grade row has a re-execution log pointer; every row has an evidence-class label and caveat column)
- [ ] `bash eval/ceremony-lift/check-verdict-block.sh` (phase article contains a per-step verdict block with positions from the closed enum only, plus a stage-2 go/no-go line in closed vocabulary)
- [ ] `bash eval/ceremony-lift/check-verdicts-only.sh` (runs `git diff --quiet 5360486..HEAD -- templates/ scripts/ install.sh modules.json Makefile` with eval/, .dev-wiki/, specs/, .claude/rules/ excluded; phase-base PINNED = 5360486, HEAD at Phase-86 planning, also recorded in pre-registration)

## Checkpoints

- Cost extraction is sequenced FIRST (before any demand tabulation) so the
  keep-by-immateriality early exit can fire before tabulation effort is spent.
- HARD checkpoint (the phase's center): after evidence + cost tables pass their checks,
  present both with caveat columns and MDE arithmetic; maintainer takes per-step positions;
  stage-2 go/no-go + routing (in-phase vs follow-on) decided here. Nothing after this point
  proceeds on agent authority.
- STOP if the cost-extractor positive control fails after 2 fix attempts (instrument-dead —
  do not tabulate on a broken instrument; re-present A3).
- STOP and re-present A2 if >50% of marginal-catch candidate rows downgrade for
  unrecoverable pre-fix state (review's column would be ambiguous-by-construction).
- STOP if any seeded control misclassifies after 2 fix attempts (tabulator instrument-dead —
  unbounded fixing against the seeds is the motivated-scoring loop the controls exist to prevent).
- If the cost baseline shows every ceremony step below the pre-registered materiality
  threshold: present keep-by-immateriality early exit at the checkpoint — valid end state.

## Assumptions

- A1 (gate, accept r2): stage-1 evidence suffices for an informed HUMAN disposition; the
  agent-counterfactual residual rides as a caveat column. If false (maintainer finds the
  table undecidable at checkpoint): route undecidable steps to stage 2 or record open
  ledger rows — never force a verdict.
- A2 (gate, accept): pre-fix states are recoverable for enough reviewer findings. If false:
  pinned downgrade direction applies; >50% downgrade triggers the STOP above.
- A3 (gate, accept, spike-defended): per-step cost is extractable from transcripts behind a
  positive control. If false: down-scope to demand-evidence-only and forward-instrument the
  next phases for cost; lift-per-cost framing deferred.
- A4 (gate, accept): in-kit tabulation of historical facts with a pre-registered corpus is
  outside the Ph80 leak class. If false (leak found in tabulation): stage 1 declared
  instrument-dead in-kit; only consuming-project history admissible.
- A5 (gate, accept): the screen narrows stage 2. If false (all-ambiguous): cost table +
  keep-by-immateriality branch are still the deliverable; stage-2 decision proceeds on
  cost grounds alone.
