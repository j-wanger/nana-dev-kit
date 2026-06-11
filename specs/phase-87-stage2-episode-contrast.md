<!-- nana:approved 2026-06-10 -->
# Spec: Phase 87 — Ceremony Stage-2 Episode Contrast

## Objective

Execute the pre-registered stage-2 episode experiment (frozen in
`eval/ceremony-lift/pre-registration.md` `## Stage-2 parameters`): a full-ceremony arm vs a
minimal arm on burnable edge-screener Phase 10, producing admissible episode evidence for the
maintainer's disposition of the `spec-generation = ambiguous-stage-2` verdict — under the
frozen claim ceiling that n=1 may confirm a cut-candidate into a REVERSIBLE trim-trial only,
never mint keep or cut.

## Context

Phase 86's stage-1 screen took maintainer verdicts per ceremony step; spec-generation was
ruled structurally stage-1-undecidable (constraints fold pre-commit — no recoverable
counterfactual), and the maintainer routed STAGE-2 go as this follow-on. The experiment's
parameters are FROZEN in the Phase-86 pre-registration (byte-frozen since commit 9ad62f0;
any edit fails the phase): arms A (dev-plan → spec → implement → debrief) vs B
(assumption-approval gate + enforcement hooks, exploratory prompt), same model + session
budget cap; substrate edge-screener Phase 10 (confirmed burnable; project at a hardened
terminus: 390 tests, 94.44% coverage, delivery accepted at commit 368e056); twin worktrees
from the same git state with TESTED restoration; leak canary in arm B (the DRQ-1 question —
correct answer voids the run); positive control (a seeded task whose binding constraint
exists only in edge-screener's dev-wiki: the settings.local.json single-registration
invariant — verified 2026-06-10 NOT yet present there, so seeding is a Phase-87 setup step);
deterministic ship criteria (test count ≥ 390 AND coverage ≥ 94.44% AND edge-screener
exit-criteria runner pass; tie-break: fewer post-hoc review defects, then fewer changed
lines). The substrate task is edge-screener's documented Phase-10 candidate: close the two
survivorship branches its disk gate doesn't exercise — the recovered-name (M) branch and the
recycled-ticker branch (the crater/residual branch is already covered); their exact
file:line branch IDs are read off the baseline coverage report and pinned in the execution
protocol before any arm runs. The experiment runs OUT of the kit repo because Phase 80
proved clean-context measurement in-kit is leak-dead. This phase EXECUTES the frozen parameters; it does not
redesign them. The queued trim round (dev-plan ride-alongs, debrief knowledge-capture half)
is deliberately sequenced AFTER this phase so the full-ceremony arm measures the current,
unmutated harness.

## Scope

### In scope
- `eval/ceremony-lift/stage2/**` (NEW subdirectory) — execution-protocol addendum, canary/
  control/ship-criteria/cost records, isolation probes, exit-criteria runner. Additive only;
  no stage-1 file under `eval/ceremony-lift/` is edited.
- Out-of-repo, HARD-checkpoint-gated: edge-screener twin worktrees/clones from pinned SHA
  368e056; one positive-control seed write into edge-screener's dev-wiki; shipping the
  better arm's output into edge-screener via its own delivery process (separate checkpoint).
- Read-only: edge-screener arm-session transcripts (programmatic parsing only), the stage-1
  cost extractor (reused as-is), kit skills/hooks as the measured apparatus.
- Phase article verdict block: maintainer's checkpoint disposition for spec-generation
  (closed vocabulary), plus instrument-status lines (canary, positive control).

### Out of scope
- ANY kit component modification (skills, hooks, templates, modules.json, install.sh,
  Makefile) — kit-commit embargo for the whole experiment window; the trim follow-on round
  is a separate later phase.
- ANY edit to `eval/ceremony-lift/` stage-1 files, including the pre-registration (byte-frozen).
- Edits to edge-screener's main working tree or existing refs outside the gated worktrees
  (only the seeded dev-wiki constraint + the gated ship step touch the real project).
- Re-litigating frozen parameters (arms, substrate, canary, control, ship criteria, claim
  ceiling). Implementation mechanics not fixed by the freeze (git isolation plumbing, arm
  ordering, budget cap value, interaction protocol) are pinned by the execution-protocol
  addendum BEFORE any arm runs — not redesigned mid-flight.
- Minting keep or cut for any ceremony step from this experiment's evidence.

## Approach

Freeze-then-execute, cheapest-validation-first. (1) Commit an execution-protocol addendum
under `eval/ceremony-lift/stage2/` pinning everything the frozen parameters left to
execution: arm ordering, model + session budget cap, maintainer-interaction protocol (canned
minimal gate responses, every human input logged verbatim per arm, the zero-gate-firing case
pre-declared a valid run), cross-arm git-isolation mechanism + probes, blinded defect-review
protocol for the tie-break (arm labels stripped, every claimed defect confirmed by an
orchestrator-executed deterministic reproduction, unconfirmed claims discarded), the all-tie
outcome pre-declared `undecidable — no trim-trial confirmation`, and an amendment rule
(apparatus fixes via timestamped addendum committed before unblinding; any amendment after
unblinding voids the experiment). Ancestry-checked like stage 1: addendum add-commit strictly
precedes the results add-commit and is byte-unchanged between (first add-commit semantics —
a delete-and-re-add does not reset the check).

**Parameter authority (three tiers, each named where used):** FROZEN (pre-registration: arms,
substrate, canary identity, control identity, ship pass/fail triple, tie-break order, claim
ceiling) — executed verbatim, never tightened or loosened; ADDENDUM-PINNED (everything
execution-level the freeze left open: arm ordering, budget cap, interaction protocol,
isolation mechanism, canary placement, control delivery path + surfacing detector, blinded
defect-review procedure, claim-ceiling grep patterns, target branch IDs) — committed before
any arm runs; SPEC-ADDED VALIDITY ASSERTIONS (baseline test-ID subset check, target-branch-ID
coverage) — these do NOT alter which arm wins under the frozen triple; their standing is
pinned below.

(2) Validate the instrument before spending arm tokens: tested snapshot restoration,
cross-arm isolation probe, canary/control mechanics rehearsed in a scratch worktree (seeding,
detector matching — rehearsal only; the control READING comes from the arms themselves).
(3) Run the arms in fresh sessions, order pinned; the control task reaches BOTH arms through
the same channel as the main task (byte-identical inclusion, asserted mechanically); the
orchestrator opens neither arm's diff until both reach their ship/stop point; the leak canary
is posed to arm B only AFTER its ship/stop point (a post-stop probe of the same context —
never pre-work, which would inject kit-pointing information and burn budget). (4) Orchestrator
executes the frozen ship-criteria commands identically in both arms with a pinned coverage
invocation, plus the validity assertions: the baseline collected-test-ID set must be a subset
of each arm's (no test deleted or weakened) — ship-BLOCKING for that arm (substrate
protection) but not contest-scoring; the two target branch IDs covered — reported as a column,
affecting nothing deterministically (the maintainer weighs it at the checkpoint). Builds the
per-arm cost table with the stage-1-validated extractor. (5) HARD checkpoint: present
ship-criteria table, cost table, canary/control records, interaction logs; the maintainer
takes the disposition; ship-the-better fires only through its own checkpoint; close-out runs
the claim-ceiling check over every produced summary artifact.

### Domain Research Questions
1. How should two comparable agent sessions be driven on the same task — headless vs
   interactive, and how do arm A's legitimate ceremony gates receive human input without the
   maintainer's responses becoming an uncontrolled information injection across arms?
2. Given git worktrees share one `.git` (object store, refs, stash, reflog), what isolation
   mechanism actually prevents arm B from reading arm A's work — namespaced refs plus an
   orchestrator-executed unreachability probe, or independent clones from the pinned SHA —
   and which is the faithful implementation of the frozen "twin worktrees" wording?
3. What context surfaces follow an agent into an edge-screener worktree regardless of arm
   (global ~/.claude rules, auto-memory, MCP memory DB at the worktree root, project
   CLAUDE.md/rules), and which are parity-shared (identical in both arms, allowed) vs
   voiding (one-arm-only leak channels)?

## Constraints (CRITICAL)

- The Phase-86 pre-registration and ALL stage-1 files are byte-frozen: `eval/ceremony-lift/`
  changes are additive under `stage2/` only, enforced by git diff against the Phase-86 end
  state (prevents retrofitting the frozen parameters to the observed episode).
- Execution-protocol addendum committed BEFORE any arm run, ancestry- and byte-checked
  exactly like the stage-1 pre-registration (prevents pinning arm ordering, interaction
  rules, or tie-break procedure after seeing results — the retrofit class the freeze exists
  to prevent).
- Kit-commit embargo with COMPONENT-PATH semantics: between the first arm's session start
  and the second arm's ship/stop point, `git diff 6728e2f..HEAD -- templates/ scripts/
  install.sh modules.json Makefile` must stay empty (recording stage-2 artifacts and the
  addendum mid-window is fine — HEAD may advance; kit components may not) (prevents the
  full-ceremony arm measuring a moving target while the trim round is queued).
- Out-of-repo writes (worktree/clone creation, dev-wiki seed, ship step) fire ONLY at HARD
  maintainer checkpoints, with per-run snapshot/branch and TESTED restoration before any arm
  runs; post-experiment, edge-screener's original refs must be byte-identical to the
  pre-experiment SHA unless the ship checkpoint approved the merge (prevents burning the
  substrate or silently mutating a delivered project).
- Cross-arm isolation verified by an orchestrator-executed probe before arm B's results
  count (other arm's refs unreachable; per-arm memory DB and session state disjoint;
  context-surface manifest captured at each arm's session start and classified parity-shared
  vs voiding against the addendum's pre-registered list — unclassified surface voids the
  run) (prevents the worktree shared-.git leak and the Ph80 always-loaded-surface leak class
  recurring through a different channel).
- Leak canary runs in arm B before its results count; a correct DRQ-1 answer = contaminated
  clean arm, run VOID — re-present, never reinterpret (prevents a contaminated minimal arm
  reading as ceremony-equivalent).
- Positive control completes before any null reads TERMINATE: the control task reaches both
  arms byte-identically (asserted by check-instrument.sh against both task statements);
  "surface" is decided by an ADDENDUM-PINNED deterministic detector (exact strings/artifact
  patterns the orchestrator greps in arm outputs and diffs — never judgment); ceremony arm
  must surface the seeded dev-wiki constraint; if NEITHER arm surfaces it the instrument is
  DEAD, not null — recorded as such (prevents an instrument failure being banked as "ceremony
  adds nothing", a vacuous scratch-only control, and a lenient/strict matcher flipping the
  verdict at the design's most load-bearing point).
- Test-access parity: both arms receive byte-identical task statements and see the same test
  suite; neither arm receives the other's artifacts; arms run in fresh sessions and the
  orchestrator opens neither diff until both close (prevents sequential-arm steering and
  asymmetric task framing).
- Ship criteria are the frozen deterministic set, executed by the orchestrator with a pinned
  coverage invocation identical across arms; the tie-break defect review follows the
  addendum's blinded deterministic-reproduction protocol; agent prose is candidate-generation
  only (prevents the verdict migrating to judgment-class evidence when both arms pass — the
  likely outcome on a hardened 390-test project).
- Claim ceiling enforced at close-out: every produced summary artifact (verdict block,
  journal, working-knowledge entries, memory stores) embeds the ceiling verbatim and a
  deterministic check greps them with ADDENDUM-PINNED patterns (which must not false-positive
  on the mandatory ceiling sentence itself) validated against a seeded-negative control
  artifact before real artifacts are checked; this phase's session artifacts are excluded by
  provenance from any future ceremony-measurement corpus (prevents the n=1 being distilled
  into the keep/cut verdict the design forbids, and the program feeding on itself).
- Disposition vocabulary is closed AND directionally honest:
  `confirm-trim-trial | not-confirmed | undecidable | instrument-dead | void` —
  `not-confirmed` records a decisive against-trim outcome (minimal arm fails ship criteria
  or loses the blinded tie-break decisively) without minting keep; forcing it into
  `undecidable` would mislabel evidence direction (prevents both verdict-minting and
  direction-laundering).
- Arm transcripts parsed programmatically only — never loaded into agent context (prevents
  context overflow and the orchestrator grading its own prose).

## Success Vision

A skeptical reader can replay the whole episode from the stage-2 directory: the addendum
shows every execution decision was pinned before runs; the canary, control, and isolation
probes show the instrument was alive and the arms genuinely separated; the ship-criteria
table shows orchestrator-executed commands, not narrated outcomes; the cost table puts both
arms in the units the maintainer feels. The likely honest outcomes — both arms pass and the
blinded tie-break decides, or the result is `undecidable` — are reported as cleanly as a
decisive one, and an instrument-dead or voided run is reported as exactly that rather than
laundered into a finding. Edge-screener ends the phase either untouched or better (the
shipped arm's branches genuinely closed), never half-mutated. The disposition of
spec-generation is visibly the maintainer's, taken inside the frozen claim ceiling.

## Exit Criteria (machine-checkable)

All aggregated by `bash eval/ceremony-lift/stage2/run-exit-criteria.sh` (exit 0 iff all pass):

- [ ] `git diff --quiet 9ad62f0 HEAD -- eval/ceremony-lift/pre-registration.md && git diff --quiet 6728e2f HEAD -- eval/ceremony-lift/ ':(exclude)eval/ceremony-lift/stage2'` (frozen pre-registration byte-intact; stage-1 apparatus additive-only)
- [ ] `P=$(git log --diff-filter=A --format=%H -- eval/ceremony-lift/stage2/execution-protocol.md | tail -1); R=$(git log --diff-filter=A --format=%H -- eval/ceremony-lift/stage2/results.md | tail -1); git merge-base --is-ancestor $P $R && git diff --quiet $P $R -- eval/ceremony-lift/stage2/execution-protocol.md` (addendum's FIRST add-commit strictly precedes results' first add-commit and the file is byte-unchanged between — `tail -1` takes the earliest add so a delete-and-re-add after seeing results cannot reset the check; amendments only via separate pre-unblinding addendum files)
- [ ] `bash eval/ceremony-lift/stage2/check-instrument.sh` (restoration test, cross-arm isolation probe, leak-canary record with closed-vocabulary verdict + post-stop placement evidence, positive-control record with closed-vocabulary verdict from the addendum-pinned detector, control-task text byte-identical across both arms' task statements — all present, all orchestrator-executed with logged commands; canary=CONTAMINATED or control=NEITHER-ARM forces the run-status line VOID or INSTRUMENT-DEAD respectively)
- [ ] `bash eval/ceremony-lift/stage2/check-ship-table.sh` (both arms × {collected-test count vs baseline-subset assertion, coverage % with pinned invocation hash, exit-criteria-runner pass, target-branch-IDs covered}; no empty cells; every cell carries a command-log pointer; tie-break section present iff both arms pass, following the blinded protocol)
- [ ] `bash eval/ceremony-lift/stage2/check-cost-table.sh` (per-arm tokens raw AND cache-adjusted, wall-clock, interruption count via the stage-1 extractor; per-arm verbatim human-interaction log present)
- [ ] `bash eval/ceremony-lift/stage2/check-claim-ceiling.sh` (every summary artifact produced this phase embeds the ceiling sentence; addendum-pinned grep patterns reject keep/cut-minting language without false-positiving on the ceiling sentence, validated against a seeded-negative control artifact first; phase-article disposition line uses closed vocabulary: confirm-trim-trial | not-confirmed | undecidable | instrument-dead | void)
- [ ] `bash eval/ceremony-lift/stage2/check-substrate-intact.sh` (edge-screener pre-experiment SHA recorded; original refs byte-identical post-experiment OR a ship-checkpoint record authorizes the delta; kit-component embargo held across the window — component-path diff vs 6728e2f empty at both arm starts and at close; stage-2 artifact commits mid-window are allowed)
- [ ] `git diff --quiet 6728e2f..HEAD -- templates/ scripts/ install.sh modules.json Makefile` (verdicts/evidence-only phase — no kit component modified; pinned base 6728e2f = HEAD at Phase-87 planning)

## Checkpoints

- HARD checkpoint before ANY out-of-repo write: worktree/clone creation, the positive-control
  dev-wiki seed, and (separately, later) shipping the better arm — each its own gate.
- Instrument validation is sequenced FIRST (restoration, isolation probe, control seeding +
  scratch run) so failures stop the experiment before arm tokens are spent.
- STOP if the restoration test fails — do not create arms on an unrestorable substrate.
- STOP if the cross-arm isolation probe fails after 2 fix attempts via pre-unblinding
  addendum — re-present (clones vs worktrees) rather than run a known-leaky design.
- STOP and record VOID if the leak canary answers correctly; re-present before any re-run.
- STOP and record INSTRUMENT-DEAD if neither arm surfaces the positive control — the episode
  cannot read TERMINATE/null; maintainer decides whether to redesign (a new phase) or stand.
- STOP if any apparatus defect is discovered after unblinding — the experiment is VOID by
  the addendum's amendment rule; never patch-and-continue.
- HARD checkpoint (the phase's center) after tables pass their checks: maintainer takes the
  spec-generation disposition inside the closed vocabulary; nothing after proceeds on agent
  authority.

## Assumptions

- A1: edge-screener at 368e056 still matches the frozen baseline (390 collected tests,
  94.44% coverage) — 390 verified by collection on 2026-06-10; coverage to be re-verified by
  a full run before arms. If drifted: STOP and re-present (the frozen ship criteria
  reference this baseline; re-baselining is a parameter change the phase cannot make).
- A2: the frozen "twin worktrees" wording admits an isolation-correct implementation
  (worktrees + namespaced refs + probes, or independent clones from the same SHA). If the
  maintainer rules clones unfaithful to the freeze AND worktree isolation cannot pass the
  probe: STOP — the experiment is not runnable as frozen.
- A3: the stage-1 cost extractor parses edge-screener arm transcripts (different project
  directory, same JSONL schema). If false: cost table down-scopes to wall-clock +
  interruptions with the token columns marked NOT-EXTRACTABLE; ship criteria are unaffected.
- A4: seeding the single-registration invariant into edge-screener's dev-wiki is an
  acceptable out-of-repo write (it is also true documentation — Ph85 verified the invariant
  live). If the checkpoint rejects the seed: the frozen positive control is unrunnable —
  STOP and re-present; never substitute a different control unilaterally.
- A5: two same-model, budget-capped sessions are drivable to completion on this task size.
  If a session exhausts its budget cap mid-arm: the arm records DID-NOT-FINISH as its
  ship-table row (a valid observation — ceremony cost IS the treatment), not a re-run with
  a raised cap; cap changes only via pre-unblinding addendum BEFORE either arm has started.
