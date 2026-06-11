<!-- nana:approved 2026-06-11 -->
# Spec: Phase 88 — Trim Follow-On Round

## Objective

Execute the stage-1-authorized ceremony trims (dev-plan ride-alongs, dev-debrief
knowledge-capture half) as REVERSIBLE trim-trials with per-candidate revert triggers, dispose
of the four evidence-armed prune-on-value leftovers via verdict-gated serialized
cuts/keeps/hardens, and tighten the three Phase-87-routed stage-2 checker holes — all under
the claim ceiling that stage-1 verdicts authorize trim-trials and dispositions, never
permanent cuts or keeps minted by this phase.

## Context

Phase 86's stage-1 ceremony-lift screen took maintainer verdicts per ceremony step
(recorded in the Phase-86 phase article verdict block; decision `ceremony-step-verdicts`,
confidence high): **dev-plan-orchestration = trim** — targets are the ride-alongs (the
active-knowledge re-presentation file written at planning time [amplifier-null class] and
the state-loader/artifact-writer subagent heft); the assumption-vote direction gate is
untouched — and **debrief-capture = trim** — the knowledge-capture half (working-knowledge
seeding ~10k tokens/session, journal prose, memory bridge stores) is the prime cut
candidate; the operational half (state reconciliation, delivery gate) is kept. Phase 87's
episode disposition was **spec-generation = undecidable** (nothing minted), so this round
proceeds on stage-1 evidence alone.

Four prune-on-value leftovers are evidence-armed in `_CURRENT_STATE.md` Blockers:
(1) the kit-side memory-MCP-layer demand question (Phase-83 A5 must-revisit): the layer is
live and import-probed healthy, yet edge-screener never voluntarily called any memory tool
across 2 real work sessions + 1 probe session and its DB was never created
(`eval/install-gap/dogfood-evidence.md`); (2) enforce-memory.sh demand revisit: kept on
couldnt-fire evidence in Phase 83, now has ~69 post-restoration firing records in
`.dev-wiki/enforcement.log`; (3) detect-loop.sh: its consecutive-failure counter is
structurally unimplementable hook-side — the platform delivers no exit-code field and no
event at all for failing Bash calls (Phase-84 platform filing); (4) check-tests-were-run.sh:
confirmed false-positive class — fires on Read of .py files during read-only analysis,
forcing pointless test re-runs (Phase-85 dogfood filing; harden candidate, not cut).

Phase 87's review gate routed three stage-2 checker tightenings here, barred in-phase by the
post-unblinding amendment rule. The three routed edit targets, by path: (a)
`eval/ceremony-lift/stage2/run-exit-criteria.sh` — the c2 check is a function INSIDE the
runner (line 31), so the single-touch-through-HEAD tightening edits the runner itself, not a
separate check-*.sh; (b) `eval/ceremony-lift/stage2/check-instrument.sh` — the instrument
byte-comparison currently uses grep instead of cmp; (c)
`eval/ceremony-lift/stage2/check-ship-table.sh` — the DNF-grep hole. The surrounding
apparatus (`eval/ceremony-lift/**` stage-1 files, the pre-registration, all other stage-2
files including `test-stage2-checkers.sh`) is byte-frozen.

Why this is the highest-risk class of phase: the kit has 4+ historical instances of
registered-but-dormant silent breakage, and the registration mechanism is add/update-only —
no deregistration exists. Every cut must remove its own installed settings entries on the
surfaces it actually breaks: `~/.claude` global registrations always; consuming-project
registrations point at local point-in-time script copies that a kit-side cut does NOT delete,
so they produce no ghost and are filed, not edited — UNLESS a registration there references a
path the cut deletes, in which case that entry joins the cut's own removal set. Prior phases (83, 84) established the method:
per-candidate verdict tables, couldnt-fire vs didnt-fire zero-classification, removal-set-first
liveness greps, serialized per-candidate commits, sandbox-rehearsed deregistration, survivor
functional smoke.

## Scope

### In scope
- The kit's dev-plan and dev-debrief skill sources in this repo (SKILL.md + companion files)
  — ride-along trims (active-knowledge re-presentation, state-loader/artifact-writer heft)
  and the GATE-NARROWED knowledge-capture trims (working-knowledge seeding, journal prose
  ONLY — the memory bridge/harvest writers are out, per gate A6), shipped as reversible
  trim-trials.
- Verdict-gated dispositions for: enforce-memory.sh, detect-loop.sh,
  check-tests-were-run.sh (harden).
- The full registration chain per cut: modules.json edit + `make template` regeneration +
  MANIFEST regen, with regenerated-diff ⊆ the candidate's removal set; sandbox-rehearsed
  deregistration of each cut's OWN installed entries (basename-normalized) on all discovered
  surfaces.
- `eval/ceremony-lift/stage2/`: ONLY the three routed files may change —
  `run-exit-criteria.sh` (the c2 function), `check-instrument.sh`, `check-ship-table.sh`.
  Their seeded-defect fixtures and the fixture runner live OUTSIDE the frozen tree, under
  `eval/trim-round/` (the frozen `test-stage2-checkers.sh` is not edited).
- New phase apparatus under `eval/trim-round/`: verdict table, removal sets, rehearsal logs,
  ghost-registration sweep, exit-criteria runner.
- Working-knowledge superseded entries for any trimmed/cut component (never rewrites of
  historical entries).
- Reference-surface enumeration for the memory-layer disposition (instruction files, probes,
  skills); user-owned surfaces produce filings, not edits.

### Out of scope
- The kit-side memory MCP layer disposition — REMOVED at the direction gate (A4 reject,
  2026-06-11: the dogfood zero is not demand evidence); defers to a future round with
  better evidence, Blockers filing updated. The 20-surface reference enumeration and the
  vendoring-contract menu defer with it.
- The memory-bridge/harvest writer trims (debrief memory-harvest, dev-plan Step 15a-bis) —
  deferred at the gate (A6 reject): the writers stay alive so the future layer round gets
  clean demand evidence.
- The assumption-approval gate (untouched per the Phase-86 verdict).
- The debrief operational half (state reconciliation, delivery gate, exit-criteria
  enforcement).
- approach-reviewer, plan-reviewer, review-gate-reviewer dispatches (keep verdicts stand).
- ANY edit to frozen apparatus beyond the three routed checker files:
  `eval/ceremony-lift/` stage-1 files and pre-registration (byte-frozen),
  `eval/ceremony-lift/stage2/` everything else, `eval/amplifier/**`,
  `eval/assumption-screen/**`, `.dev-wiki/assumption-ledger.md` (append-only via the gate
  only).
- Re-running tightened checkers against the Phase-87 episode record for grading — Phase-87
  verdicts stand as recorded under the checker versions that graded them.
- User-owned `~/.claude/rules/` files (soul, personal) — even where they mandate memory-tool
  use; findings are filed for the user.
- Ghost global registrations beyond each cut's own (the Phase-82 drift filing stands).
- Synchronized uninstall sweeps in consuming projects (point-in-time copies are filed, not
  chased), unless a cut creates an active session-breaking hazard there.
- Edge-screener Phase-87 session transcripts as trim-trial evidence (provenance-excluded).

## Approach

Verdict-table-first, serialized, Phase-83 method extended with trim-trial reversibility.

Build the complete per-candidate verdict table BEFORE touching anything: every candidate
(2 trim strands decomposed into their separable sub-targets, 4 leftovers, 3 checker
tightenings) gets an evidence citation, a couldnt-fire vs didnt-fire classification wherever
a zero is load-bearing, a removal set, and — for trims — a pre-stated revert trigger
("what evidence, observed by when, triggers restoration") plus observation window. A trim
with no written revert trigger is not a trial and may not execute. The table's header
records the phase-base SHA (the commit this phase starts from), which the stage-2 allowlist
check reads as its diff base. Verdicts use closed enums per candidate class: trim strands
`trim-trial | no-trim`; leftover components `keep | cut | harden | disable-at-boundary`
(the memory MCP layer additionally honors its vendoring-contract menu
`keep | disable-at-boundary | cut-with-regenerated-patch`); checker tightenings
`tightened | instrument-dead`. Each executed trim-trial row spawns a Blockers filing in
`_CURRENT_STATE.md` with re-trigger = end of its observation window — the follow-up is
mechanical, not implied.

The coupled memory verdicts were resolved at the direction gate rather than left to
execution ordering: the layer disposition is deferred (A4 reject) and the bridge/harvest
writers stay alive with it (A6 reject — clean future demand evidence beats trimming the
writer now). enforce-memory's own disposition proceeds against a live layer, with the A3
attempt+fallback evidence path.

One unconditional HARD checkpoint: the full verdict table goes to the maintainer before any
trim/cut/harden executes. Cuts and trims then execute serially, one commit per candidate,
each with: sandbox-rehearsed revert (`git revert` + survivor smoke in a scratch clone, revert
SHA recorded), regenerated-diff ⊆ removal set, deregistration rehearsed in `mktemp -d` with a
positive control (register dummy → deregister → assert absent → assert survivors still fire
via a piped real event), and a post-removal ghost sweep asserting no settings entry on any
discovered surface references a nonexistent script. Surface discovery is mechanical, never
assumed (Phase-83/84 kit-marker-scan method): `~/.claude/settings.json` plus every discovered
root's `.claude/settings.json` AND `.claude/settings.local.json` (the latter is gitignored in
consuming projects — a repo-side grep cannot see it).

Checker tightening is controls-first: each tightened checker must FAIL on a seeded synthetic
defect fixture (a double-touch history for c2; a byte-differing-but-grep-matching instrument
pair; a DNF row the old grep missed) and PASS on a clean fixture, before it replaces the old
version. The fixture set includes the boundary semantics cases: trailing-newline-only diff,
empty-file pair (`cmp -s` of two empty files succeeds), empty/absent ship table (must fail
or error, never vacuous-pass), and the c2 history shapes (zero touches, one, one-via-merge,
two). "Identical" is pinned per file class (bytes-only vs bytes+mode) before editing.

### Domain Research Questions
1. Of the ~69 enforce-memory firing records, how many blocks were followed by an actual
   `memory_store` call? Blocks with no follow-through are friction evidence, not demand
   evidence — the answer determines which verdict the data supports.
2. (Deferred with the memory-layer disposition at the gate — retained for the future round:)
   What are ALL reference surfaces of the kit-side memory MCP layer, and which would emit
   errors or dead mandates every session if the layer were disabled at the boundary?
3. Does detect-loop.sh share state files, log paths, or seeded data with enforce-loop.sh or
   any kept hook — i.e., is its removal set actually severable?

## Constraints (CRITICAL)

- Every trim/cut is one serialized commit containing ONLY that candidate's removal, with the
  revert rehearsed in a sandbox clone and the revert SHA + revert trigger + observation
  window recorded in the verdict table BEFORE the commit ships — prevents the trial silently
  becoming a permanent cut when later phases build on the deletion.
- Deregistration is basename-normalized (Claude Code's settings dedupe is string-keyed —
  different command strings invoking the same script BOTH fire), rehearsed in `mktemp -d`
  with a positive control, and followed by a ghost sweep asserting zero
  nonexistent-path registrations on every discovered surface — prevents a 5th
  registered-but-dormant instance, self-inflicted.
- Won't-fire-when-armed = DEFECT finding, never a demand-evidence cut; every load-bearing
  zero gets the couldnt-fire vs didnt-fire classification in a sandbox before its verdict —
  prevents cutting components whose zeros measure broken plumbing (4 of 6 Phase-82 zeros
  were measurement artifacts).
- The enforce-memory verdict must classify the firing records (which project, context,
  follow-through to an actual store) before keep/cut is argued — prevents conflating "fired
  69 times" (nagging) with "earned its keep" (demand).
- The memory-bridge trim may not execute before the memory-layer demand disposition is
  recorded, and the disposition cites only pre-trim evidence — prevents laundering the trim
  as demand evidence ("no writes" after removing the writer).
- A stage-2 diff allowlist is enforced: `git diff --name-only <phase-base>..HEAD --
  eval/ceremony-lift/stage2/` may contain only the three routed checker files, and the
  pre-registration plus every other stage-2 file is verified byte-identical (`cmp`, not
  grep) — prevents freeze erosion under cover of the routed fix.
- Tightened checkers are validated against seeded-defect + clean fixtures only and are never
  re-run against the Phase-87 record for grading; the tightening commit message states that
  Phase-87 verdicts stand as recorded — prevents retroactive re-grading of frozen evidence.
- Each tightened checker must catch its seeded defect before replacing the old version; a
  checker that passes on its seed is instrument-dead and may not ship — prevents
  tightening-in-name-only.
- The check-tests-were-run harden ships only with a PAIRED functional smoke in `mktemp -d`
  (real Edit-on-.py event with no test run → block exit 2; real Read-of-.py event → allow
  exit 0), never tested against live state — prevents overcorrecting the false positive into
  a dormant hook, and prevents the Phase-82-class self-lockout.
- Working-knowledge entries naming trimmed/cut components get superseded entries, never
  rewrites; historical dev-wiki records are never edited — preserves the audit trail.
- If a disposition contradicts a standing decision article (e.g. memory-architecture-
  classification), the contradiction is surfaced at the checkpoint and the article is
  explicitly superseded by maintainer call — never silently bypassed.
- Deregistration assumes no live Claude Code session is mid-flight on the affected surface;
  if quiescence is unverifiable, the ghost sweep re-runs after sessions cycle and the gap is
  recorded — prevents a straddling session invoking deleted scripts unobserved.
- Zero cuts/trims on any strand is a valid outcome — prevents manufacturing removals to
  justify the phase.

## Success Vision

Every candidate ends the phase with a verdict traceable to firing or consumption evidence —
verified-kept, hardened-with-smoke, or trimmed-with-a-working-revert-path — and nothing ends
it in the registered-but-dormant state. The always-loaded and per-session ceremony surface
measurably shrinks (planning ride-alongs, debrief capture tokens) while the direction gate
and delivery gate are untouched. The three checker holes demonstrably catch the defects they
previously missed, proven by seeded controls, without disturbing one byte of frozen evidence.
The trim-trials carry honest restoration triggers a future phase can actually evaluate, and
whatever this phase could not decide is filed with a named re-trigger rather than quietly
dropped. Future ceremony measurements know the trim commits are the new harness baseline.

## Exit Criteria (machine-checkable)

All aggregated by `eval/trim-round/run-exit-criteria.sh` (each line is also independently
runnable):

- [ ] `test -f eval/trim-round/verdict-table.md && bash eval/trim-round/check-verdict-table.sh`
      — table exists with the phase-base SHA in its header; every candidate row has verdict
      (the closed enum for its candidate class), evidence citation, and (for trims) revert
      SHA + revert trigger + observation window + the spawned Blockers-filing reference;
      checker validated against a seeded bad-row fixture first.
- [ ] `bash eval/trim-round/check-ghost-registrations.sh` — zero settings entries on any
      discovered surface reference a nonexistent script; validated against a seeded ghost
      fixture first.
- [ ] `bash eval/trim-round/check-stage2-allowlist.sh` — stage-2 diff vs the phase-base SHA
      (read from the verdict-table header) contains only the three routed files
      (`run-exit-criteria.sh`, `check-instrument.sh`, `check-ship-table.sh`);
      pre-registration and all other stage-2 files byte-identical via `cmp`.
- [ ] `bash eval/trim-round/run-seeded-controls.sh` — each tightened checker FAILS on its
      seeded-defect fixture and PASSES on its clean fixture, including the boundary cases
      (empty table, empty-file pair, trailing-newline diff, c2 history shapes).
- [ ] Paired smoke for the check-tests-were-run harden passes (block AND allow paths), wired
      into `make test`.
- [ ] `make test` — full suite green, including test_settings_template.sh drift check and
      test_registration.sh bidirectional invariant after every registration-chain edit.
- [ ] `make eval` — 52/52, or an explained denominator change recorded in the verdict table
      if a cut removes corpus scenarios.
- [ ] `grep -q 'Phase-87 verdicts stand' eval/trim-round/verdict-table.md` — the
      no-retroactive-re-grade pin is recorded.
- [ ] Per-cut revert rehearsal logged: every trim/cut row's rehearsal log exists under
      `eval/trim-round/rehearsals/` (checked by check-verdict-table.sh).
- [ ] `bash eval/trim-round/run-exit-criteria.sh` reports ALL-PASS.

## Checkpoints

- HARD checkpoint (unconditional): the complete verdict table — all candidates, evidence,
  classifications, removal sets, revert triggers — goes to the maintainer BEFORE any
  trim/cut/harden executes. Couldnt-fire candidates are presented as defects with no cut
  offered.
- Before each deregistration executes on a live surface: sandbox rehearsal evidence (positive
  control + survivor fire) is in hand; absent rehearsal, the candidate does not execute.
- After each serialized candidate commit: survivor functional smoke + `make test`; on any
  failure, revert immediately and re-present rather than stacking further candidates.
- If any tightened checker passes on its seeded defect: STOP that strand (instrument-dead),
  ship nothing for it, file.
- If any stage-2 criterion OTHER than the three routed targets breaks on the routed edits
  (the c2 edit is inside `run-exit-criteria.sh` itself, so runner changes scoped to c2 are
  expected): STOP, file, do not widen the edit set.
- If a coupled dependency surfaces that forces scope beyond a candidate's removal set
  (e.g. detect-loop state shared with a kept hook): STOP and ask before widening.

## Assumptions

- The Phase-86 stage-1 trim verdicts still stand (no contrary evidence has emerged since
  2026-06-10). If false: re-present to the maintainer at the HARD checkpoint before any
  execution.
- The three routed checker files are severable from the freeze, on the authority of the
  Phase-87 review-gate routing. If any frozen-apparatus integrity check cannot be satisfied
  while editing only those three files: STOP and file — do not touch a fourth file.
- Edge-screener's zero voluntary memory-tool use measures absent demand, not broken plumbing
  (the layer was liveness-probed healthy during the dogfood). If a couldnt-fire cause is
  found during classification: the zero becomes a DEFECT finding and supports no cut.
- Consuming-project point-in-time hook copies need no synchronized uninstall this phase. If a
  cut is found to actively break sessions in edge-screener (errors, not dormancy): a gated
  per-project sweep becomes in-scope via checkpoint, not silently.
- `make template` regeneration is sufficient to keep templates/MANIFEST in sync per cut. If a
  regenerated diff exceeds the candidate's removal set: STOP, revert the candidate, re-derive
  the removal set.
- The deregistration window is quiescent (no live session mid-flight on the edited surface).
  If unverifiable: re-run the ghost sweep after sessions cycle and record the gap in the
  verdict table.
