<!-- nana:approved 2026-06-09 -->
# Spec: Phase 81 — Assumption-Approval Gate

## Objective
Replace the dev-plan direction gate's "approve the approach?" step with the maintainer taking explicit
accept / reject / don't-know positions on the plan's load-bearing assumptions, recorded in an append-only
cross-phase ledger whose unfilled revisit-status is mechanically surfaced at debrief — so the human's role
shifts from rubber-stamp to interrogator.

## Context
nana-dev-kit's dev-plan skill ends planning with a "direction gate" (Step 13): the maintainer approves the
agent's proposed approach before implementation begins. The maintainer is patient-zero — he lacks the
software-engineering floor to evaluate an approach, so he blind-approves ("OK-not-great" outcomes). Phase 80
screened whether an elaborate scope-anchored assumption surfacer beats a naive baseline and returned
`^PROGRAM-VERDICT: INSTRUMENT-DEAD` (the workflow subagents inherited nana-dev-kit's always-loaded
`working-knowledge.md`, which documents the test fixtures' answers — the surfacer *leaked* rather than
surfaced; the amplifier-null caught in the act, a 5th null). The clean signal pointed **DEGENERATE**: a
naive "list the load-bearing assumptions, cost-sorted" prompt recovered 3/4 silent-class assumptions by pure
reasoning. The screen's FORWARD recommendation (`eval/assumption-screen/screen-record.md`) is exactly this
phase: ship the **simplest** gate, NOT the scope-anchored machinery (its only apparent edge was the leak).

The gate's four components were pre-decided by the maintainer's live verdicts when the Phase-80 plan was
itself interrogated through this mechanism (A1 engagement → accept; A2 surfacing-trust → reject, which made
Phase 80 a screen; A3 ledger → accept conditional on a debrief forcing-function; A4 substrate → accept) plus
three direction-gate decisions (positions REPLACE the approval click; all-accept → warn + track +
restate; build the ledger now). See [[assumption-surfacer-completeness-screen]] and [[HEU-012]]
(mandatory-over-advisory: verify a mechanism FIRES, not that its file exists). The frozen naive surfacer
prompt lives in `eval/assumption-screen/surfacer.md` (condition NAIVE).

## Scope
### In scope
- A naive load-bearing-assumption surfacer in the dev-plan direction-gate flow. It is the SINGLE surfacer
  (not a second list parallel to Step 10): the surfacer generates the full 3–6 cost-sorted set, and Step-10
  T0's single "weakest assumption" MUST appear as one member of that set (a consistency check, not a
  separate derivation). If T0's weakest assumption is absent from the surfaced set, the surfacer is
  incomplete and must regenerate.
- The direction gate becomes accept / reject / don't-know positions on the surfaced assumptions (positions
  replace the "approve the approach?" interaction).
- All-accept handling: warn + track the all-yes in the ledger + restate how each accepted assumption shapes
  the approach.
- An append-only cross-phase assumption ledger at `.dev-wiki/assumption-ledger.md` (one entry per phase).
- A deterministic, NO-LLM check (`scripts/check-assumption-ledger.sh`, `--selftest`) validating ledger
  schema + flagging blank revisit-status + flagging an in-implementation phase with no recorded positions,
  enforced at debrief finalization; tolerant of a missing/partial-history ledger.
- A dev-debrief revisit-status forcing-function (fills "did this assumption bite?" for the closing phase
  AND re-scans prior-phase unrevisited rows).
- A single shared ledger-schema source referenced by both skills + the check (no split-brain).
- A frozen with/without example artifact for the gate prompt (the functional test for the LLM-executed step).

### Out of scope
- The elaborate scope-anchored / framing two-pass surfacer (Phase 80 showed no clean value).
- Any claim of a measured quality/efficacy delta — unmeasurable in-kit (Ph66/69/80 representativeness);
  tests assert MECHANICS (gate writes positions, ledger appends, revisit-status enforced), never efficacy.
- A new session-start advisory hook for unrevisited rows (deferred — the debrief-finalization check is the
  firing point; re-trigger: debrief-skip leaves unrevisited rows undetected in real use).
- Auto-mutating a linked decision article's `confidence` when an assumption bites (debrief SURFACES the
  suggestion; the maintainer decides).
- Wiring the surfacer into a measurable eval scenario; re-running the accretion-class residual in a clean
  consuming project (a separate user call per the screen-record).

## Approach
Insert assumption-surfacing + position-taking into the dev-plan direction gate, with the ledger as the
durable record and the debrief as the detect-after backstop. The surfacer is a plain prompt (the proven
NAIVE condition); the engineering substance is the ledger's integrity (append-only, corruption-resistant
inside a skill-managed directory) and the mechanical enforcement points (positions recorded before
implementation; revisit-status filled before a phase closes). Keep skill-file edits to Read-pointers into
companions (the 350-line cap is near on both skills). The gate is an LLM-executed step with no exit code,
so its firing evidence is the ledger row, not the prose — the deterministic check asserts on the row.

### Domain Research Questions
1. How does an append-only ledger survive a directory whose files are skill-managed (dev-plan/dev-debrief
   rewrite sections of `_CURRENT_STATE.md`, `tasks.md`)? What ownership/preservation discipline keeps prior
   phases' rows from being truncated by a later skill run — and what structural test proves it?
2. Where is the mechanically-reliable firing point for "positions were actually taken" given the gate is an
   LLM markdown step — what row/marker must exist before the implementation HARD-GATE lifts, such that a
   transcript that narrated the gate without recording positions fails the check?
3. An assumption recorded in phase N can bite in phase N+k (the project's recurring cascade pattern). What
   revisit window lets the debrief catch a later-phase bite instead of prematurely marking it "didn't bite"?

## Constraints (CRITICAL)
- **All-accept must not silently reproduce blind-approve.** A uniformly-accept position-set must trigger a
  warning + a tracked `all_accept: true` flag in the ledger + a restatement of how each accepted assumption
  shapes the approach. — Guard: the gate companion mandates the restatement as a named, always-fired effect;
  a debrief audit can find an `all_accept: true` entry whose assumption later bit. (Per the maintainer's
  decision this is warn+track+restate, NOT a hard block.)
- **The gate must not degenerate to theatre (narrated, never taken).** — Guard: the ledger row is the firing
  evidence; the deterministic check flags an active/in-implementation phase that has no ledger entry or has
  blank positions, and the implementation HARD-GATE keys on a recorded position-set. A ledger file that
  exists but carries no positions fails the check.
- **The agent must not bury the load-bearing assumption low in its self-chosen cost ranking.** — Guard:
  cost-of-error is an explicit per-assumption logged judgment; the ledger records the FULL surfaced set so a
  debrief revisit can catch an assumption that bit but was ranked low or omitted.
- **The cross-phase ledger must not be silently truncated/overwritten by a later skill run.** — Guard:
  `.dev-wiki/assumption-ledger.md` is append-only and owned by no section-rewriting skill; a structural test
  asserts entry count is monotonic non-decreasing across phases and that no debrief/state rewrite touches it.
- **"Don't-know" must not be treated as equivalent to accept for gate closure.** — Guard: a don't-know is
  either resolved at the gate (agent defends with evidence or down-scopes to drop the dependency, then
  re-presents) or recorded as a deferred don't-know routed to the phase article's Blockers/Open-Questions
  AND flagged must-revisit at debrief. It never closes the gate as a silent pass.
- **Revisit-status must not stay `unrevisited` forever.** — Guard: the deterministic check (run at debrief
  finalization) flags any `unrevisited` row across ALL phases, not just the closing one; debrief finalization
  surfaces them and cannot complete cleanly while the closing phase's rows are blank.
- **No LLM in the deterministic check.** — Guard: `check-assumption-ledger.sh` is bash+grep/awk only, fail
  loud on schema violation, `--selftest` proves it both ways (flags a bad ledger, passes a good one).
- **Skill files stay within the 350-line cap.** — Guard: gate logic and revisit logic live in companions;
  SKILL.md edits are ≤ a few Read-pointer lines; an exit criterion asserts `wc -l ≤ 350`.

## Success Vision
A maintainer planning the next phase is shown 3–6 load-bearing assumptions, worst-if-wrong first, each with
what breaks if it's false, and must take a position on each — the moment that turns blind-approval into
interrogation. A reject sends the agent back to revise; a don't-know forces the agent to defend or
down-scope; an all-accept is allowed but is never silent (it is named, restated, and tracked). Every
position is durably recorded so that months later, when an assumption bites, the debrief can point to the
row where it was accepted. The mechanics are honestly tested as mechanics — the gate provably records
positions, the ledger provably appends, the revisit-status is provably enforced — with the spec stating
plainly that the *efficacy* of the intervention cannot be measured inside the kit and is not claimed.

## Exit Criteria (machine-checkable)
- [ ] `bash scripts/check-assumption-ledger.sh --selftest` exits 0 (deterministic, NO LLM; selftest proves
      it FLAGS a blank-revisit entry, an in-implementation phase with no positions, a non-monotonic ledger,
      and a schema-missing-required-field entry, AND PASSES a complete schema-conformant entry — both
      directions).
- [ ] No LLM invocation in the scoring path (comment lines + the NO-LLM self-reference excluded):
      `grep -niE 'LLM|claude|model|judge' scripts/check-assumption-ledger.sh | grep -vE '^[0-9]+:[[:space:]]*#' | grep -viE 'no[ -]?llm'` returns nothing.
- [ ] `make test` exits 0 with a new test file that pipes a blank-revisit ledger fixture through the check
      and asserts a flag, and a complete fixture and asserts a pass (firing assertion, not presence):
      `bash tests/test_assumption_ledger.sh`.
- [ ] dev-plan wires the gate via a companion and stays within cap:
      `grep -q 'assumption-gate' templates/.claude/skills/dev-plan/SKILL.md && [ "$(wc -l < templates/.claude/skills/dev-plan/SKILL.md)" -le 350 ]`.
- [ ] The gate companion defines the full interaction:
      `f=templates/.claude/skills/dev-plan/assumption-gate.md; grep -qi 'accept' $f && grep -qi 'reject' $f && grep -qi "don't-know\|dont-know\|don.t.know" $f && grep -qi 'all-accept\|all_accept' $f && grep -qi 'restate' $f && grep -qi 'append' $f`.
- [ ] dev-debrief wires the revisit forcing-function within cap:
      `grep -riq 'revisit-status\|revisit_status\|assumption-ledger' templates/.claude/skills/dev-debrief/ && [ "$(wc -l < templates/.claude/skills/dev-debrief/SKILL.md)" -le 350 ]`.
- [ ] The ledger schema has ONE documented source (a `## Ledger schema` block in
      `scripts/check-assumption-ledger.sh` or a dedicated schema companion) that the gate companion and the
      debrief revisit step both reference by path (no inlined divergent copy); proven by a schema-conformance
      assertion, not string-presence:
      `S=$(grep -rl 'check-assumption-ledger\|assumption-ledger-schema' templates/.claude/skills/dev-plan/assumption-gate.md templates/.claude/skills/dev-debrief/ | wc -l); [ "$S" -ge 2 ] && grep -qi 'schema' tests/test_assumption_ledger.sh`.
- [ ] A frozen with/without gate example artifact exists showing both a mixed-positions case AND an
      all-accept case whose restatement-of-consequences is present (not just the label):
      `f=templates/.claude/skills/dev-plan/assumption-gate-example.md; test -f $f && grep -qi 'all-accept\|all_accept' $f && grep -qi 'reject\|don' $f && grep -qi 'restate\|shapes the approach' $f`.
- [ ] `make eval` shows no regression (count is fixed — this feature adds NO eval scenario; assert all 52
      pass, so 51/52 fails the gate): `make eval 2>&1 | grep -qE 'Score: 52/52'`.
- [ ] A decision article records the build + the efficacy-not-claimed disclaimer:
      `f=.dev-wiki/articles/decisions/assumption-approval-gate.md; test -f $f && grep -qi 'unmeasur\|efficacy\|amplifier-null' $f`.

## Checkpoints
- After the ledger + deterministic check + its test are green (the mechanical core): report, then proceed to
  the skill-text gate/debrief wiring.
- After the dev-plan gate companion + SKILL.md pointer: report the gate interaction shape (paste the frozen
  example) before wiring the debrief side.
- If the append-only ledger cannot be made corruption-safe inside the skill-managed `.dev-wiki/` without a
  new hook (Domain Research Q1 fails): STOP and report — the ledger location is load-bearing.
- If a registration/firing-coverage/drift invariant would require a new hook or a settings change beyond the
  approved surface: STOP and surface it (the approved surface adds NO new hook).

## Assumptions
- The dev-plan direction gate (Step 13) is the right insertion point. If false (the surfacing belongs
  upstream at approach-proposal): fold the surfacer into Step 10's T0 output instead and keep Step 13 as the
  position-taking gate only.
- The ledger belongs in `.dev-wiki/` as its own append-only file (like `tasks.md` is skill-managed but
  section-owned). If false (a later skill run truncates it despite the preservation discipline): relocate to
  a non-skill-managed path or add an append-only guard hook.
- The debrief-finalization deterministic check is sufficient mechanical bite for the revisit-status (a
  judgment-laden field). If false (debrief is skipped entirely in real use, leaving unrevisited rows
  undetected): add the deferred session-start advisory backstop ([[HEU-012]] firing point).
- Phase 81 itself is planned/implemented with the PRE-feature installed dev-plan, so it records no ledger
  entry from its own planning; the ledger begins populating from the next phase planned with the new gate.
  If false (a bootstrapping ledger entry is needed): seed Phase 81's row manually from the four live A1–A4
  verdicts (which the decision article already carries).
- The frozen NAIVE surfacer prompt in `eval/assumption-screen/surfacer.md` is the surfacer of record. If it
  is later edited: the gate companion must inline its own frozen copy so the gate prompt cannot drift.
