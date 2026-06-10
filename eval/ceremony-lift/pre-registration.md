# Phase 86 Pre-Registration — Ceremony Lift Measurement

FROZEN at commit time. Byte-unchanged between this file's add-commit and
evidence-table.md's add-commit (spec exit criterion 2). Any mid-phase edit fails the phase.
Spec: specs/phase-86-ceremony-lift-measurement.md (nana:approved 2026-06-10).
Pinned phase-base for the verdicts-only check: commit 5360486.

## Corpus

- Demand-evidence window: **Phases 76–85** (the stable amplifier-era harness shape),
  ending at frozen end-commit **5360486** (HEAD at Phase-86 planning). Dispatches after
  this commit are out of corpus.
- Enumeration is MECHANICAL and COMPLETE: every ceremony dispatch (Step-list classes
  below) in every corpus session is a row, including zero-catch dispatches — the
  denominator is reported per step.
- Session→phase mapping: session transcripts at
  `~/.claude/projects/-Users-jwang-nana-dev-kit/*.jsonl`, assigned to phases by the
  phase-marker content they carry (PLAN/debrief log lines, phase-numbered dispatch
  labels); sessions spanning phases are split at the PLAN entry timestamp.
- Self-feedback exclusion: any session containing the string `ceremony-lift`
  (this measurement's own sessions) is EXCLUDED from the corpus by content-marker
  provenance filter.
- Consumption evidence (uses counters, citation trails, retrieval events) may draw on
  the FULL repo history — capture-step payoff is lagged by design; a forward window
  would mechanically read zero.
- Version-skew handling: the harness evolved within the window; each row carries the
  phase number as its version proxy. No cross-version pooling claims beyond per-step
  totals with the caveat column.
- **Hand-counted anchor: Phase 85 = 8 ceremony dispatches** (method: manual label
  inspection of session `74a6533b-66aa-426d-9da0-b2a6d22a0197.jsonl` Agent-dispatch
  entries — adversarial spec constraints; spec Tier-1 review; dev-plan state loader;
  approach review; plan review; dev-plan artifact writer; Phase-85 review gate;
  debrief executor. The `wiki-add — Analyst phase` dispatch is excluded: not a
  Step-list class). T5's mechanical manifest MUST reproduce 8 for Phase 85 or the
  pipeline is under/over-enumerating (spec exit criterion 6).

## Step list

The canonical ceremony steps (cost table: one row each; demand table: dispatches
classed to these):

1. **dev-plan-orchestration** — state loader + artifact writer dispatches + inline
   orchestration (Steps 3–16).
2. **spec-generation** — /spec --internal: adversarial constraint generator + Tier-1
   reviewer dispatches + drafting.
3. **approach-reviewer** — dev-plan Step 12 dispatch.
4. **plan-reviewer** — dev-plan Step 14 dispatch(es), incl. re-review rounds.
5. **review-gate-reviewer** — dev-debrief size-gated reviewer dispatch.
6. **debrief-capture** — debrief executor dispatch + journal/decision/working-knowledge/
   memory-bridge writing.

## Class membership

Re-presentation-class outputs (consumption-grade evidence CANNOT support keep for
these — the five-amplifier-null class):

- **debrief-capture**: working-knowledge entries, active-knowledge re-presentation,
  journal articles, memory-bridge stores.
- **dev-plan-orchestration's knowledge-injection sub-step**: cross-wiki retrieval
  re-presented as active-knowledge.

NOT re-presentation-class (process/contract outputs, eligible for outcome-grade keep
support): reviewer findings (steps 3–5), spec contracts (constraints/exit criteria),
task plans, assumption-gate surfacing.

## Admissibility

- Agent-authored prose (journals, decision articles, commit messages, reviewer result
  text) is CANDIDATE-GENERATION only — never verdict evidence.
- An **outcome-grade** row requires the orchestrator to re-execute the relevant
  deterministic gate (make test / make eval / exit-criteria runner / named check
  script) against a RECOVERABLE pre-fix state (git ancestor commit, or file state
  reconstructed from transcript tool-calls) and observe pass-where-it-should-fail —
  i.e., the gate demonstrably would NOT have caught the defect the ceremony step caught.
- Re-execution commands + results land in the re-execution log; every outcome-grade
  row carries a pointer.
- **Pinned downgrade direction:** unrecoverable or ambiguous re-execution → the row
  DOWNGRADES to ambiguous. Never upgrade on inference; never discard (the row stays
  in the denominator).
- **Caveat column (every row):** the agent-counterfactual residual — re-execution
  establishes the GATE would have missed it, not that the implementing agent would
  have; this residual is absorbed by the maintainer at the checkpoint, not by the
  tabulator.
- Consumption-grade evidence: working-knowledge `[uses: N]` counters (agent-maintained,
  unknown increment discipline — admissible ONLY because consumption-grade is capped),
  `[[...]]` citation trails, retrieval events in transcripts. Supports cut-candidate
  and trim claims; cannot support keep for re-presentation-class outputs.
- Historical evidence supports COST claims and per-event re-executed marginal catches
  ONLY — never correlational ceremony-on/off lift comparisons (selection bias:
  ceremony-heavy sessions were the riskier phases; the corpus contains zero true
  minimal-arm sessions).

## Token attribution

- Per-message usage fields summed by type: `input_tokens` (fresh), `cache_creation_input_tokens`,
  `cache_read_input_tokens`, `output_tokens`.
- **Raw** = sum of all four. **Cache-adjusted** = input-token-equivalents at API price
  ratios: fresh ×1.0, cache-write ×1.25, cache-read ×0.1, output ×5.0.
- Message→step assignment: a message belongs to a step from its step-boundary marker
  (Skill invocation entry, or Agent dispatch whose label matches a Step-list class)
  until the next boundary; messages outside any ceremony step are "implementation"
  (not a ceremony row, but reported as the phase-total denominator).
- Subagent transcripts (sidechain/agent files) attribute WHOLLY to the dispatching step.
- Wall-clock per step: timestamp delta across the step's message span (subagent spans
  use the dispatch-to-result delta in the parent — concurrent dispatches are not
  double-counted; overlap is collapsed to the union interval).
- Interruptions per step: count of AskUserQuestion tool calls + blocking permission
  prompts attributable to the step's span.
- Validation: the pipeline runs on the hand-labeled session FIRST
  (test-cost-extractor-control.sh); totals must match the hand count before bulk
  processing. Truncated-final-line and empty-file fixtures included (mid-append .jsonl).
- Reporting: BOTH raw and cache-adjusted, per step, plus the phase-total denominator.

## Cost materiality

A step is **immaterial** iff ALL of:
- cache-adjusted cost < 5% of the phase-total cache-adjusted cost (median across
  corpus phases), AND
- wall-clock < 5% of phase wall-clock (median), AND
- adds 0 synchronous interruptions beyond the 2 budgeted boundary gates
  (direction + delivery).

**Keep-by-immateriality early exit** fires only if EVERY Step-list step is immaterial —
then tasks 4–6 are skipped and the checkpoint presents the cost table alone.

## MDE

- Rare-event guard: for each step, expected event count in window = observed events
  (from the evidence table). For any step with < 3 observed events in the window,
  a zero/low count is **statistically uninformative**: "no catches observed" alone is
  an INVALID cut justification.
- For such steps the checkpoint presents **expected-cost arithmetic**: historical
  base rate (events per dispatch, with the window denominator) × maintainer-assessed
  cost-of-missed-defect vs the step's per-phase cost from the cost table. The
  arithmetic is presented; the verdict is the maintainer's.

## Verdict menu

Closed enum for the maintainer's per-step checkpoint positions (stage 1 mints no
verdicts — gate A1 round 2):

`keep` | `trim` (incl. make-conditional / risk-gated via lite/standard dial) | `cut`
(queues to gated follow-on with removal checklist) | `ambiguous→stage-2` |
`underpowered—decide-by-arithmetic` | `keep-by-immateriality` (phase-level early exit).

Evidence-class support constraints: consumption-grade cannot support `keep` for
re-presentation-class outputs; `cut` of a rare-event step (<3 events) requires the
expected-cost arithmetic, not the zero alone.

## Early-exit reporting

If the task-3 early exit fires: run-exit-criteria.sh reports criteria 2, 4, 6 as
`N/A-EARLY-EXIT` with a pointer to the checkpoint record (criteria 1, 3, 5, 7, 8 still
must pass — the runner reports `5/5 + 3 N/A-EARLY-EXIT`). The skip is recorded as a
maintainer decision in the task-7 checkpoint block, never silently.

## Stage-2 parameters

Fires only on checkpoint go; out-of-repo writes via hard checkpoint as ever.

- Arms: A = full ceremony (dev-plan → spec → implement → debrief); B = minimal
  (assumption-approval gate + enforcement hooks, exploratory prompt). Same model,
  same session budget cap.
- Substrate: edge-screener Phase 10 (confirmed burnable), twin worktrees from the
  same git state; per-run snapshot/branch with TESTED restoration before any run.
- Test-access parity: both arms see the same test suite and the same task statement;
  neither arm receives the other's artifacts.
- **Leak canary** (run in arm B before its results count): "What was the DRQ-1
  verdict and which file records it?" — answerable only from kit-internal docs;
  a correct answer = contaminated clean arm, run void.
- **Positive control** (required before any null reads TERMINATE): a seeded task
  whose binding constraint exists only in edge-screener's dev-wiki (the
  settings.local.json single-registration invariant) — ceremony arm must surface it;
  if NEITHER arm surfaces it, the instrument is dead, not null.
- Deterministic ship criteria (twin worktrees, "ship the better"): test count ≥ 390
  baseline AND coverage ≥ 94.44% AND edge-screener exit-criteria runner pass;
  tie-break: fewer post-hoc review defects, then fewer changed lines. No judgment calls.
- Verdict authority: n=1 episode evidence may confirm a `cut`-candidate into a
  REVERSIBLE trim-trial; it may never mint `keep` or `cut` outright.
