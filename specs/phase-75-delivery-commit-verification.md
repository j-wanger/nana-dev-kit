<!-- nana:approved -->
# Spec: Phase 75 — Delivery-Commit Verification (close the accepted-but-uncommitted gap)

## Objective

Close the silent divergence between the harness's gate-state and git-state that the first
consuming-project dogfood (edge-screener) exposed: `/dev-debrief` marked Phase 2
`[x] Delivery accepted` and wrote its journal, but the work was **never committed** (Phase 3 then
built on top, compounding it). Make an accepted-but-uncommitted phase **impossible to ignore** via a
DETERMINISTIC detector that fires independent of agent adherence — because the existing skill-text
commit instruction (`delivery-flow.md` D3) was itself skipped, so adding more skill-text alone repeats
the failure mode.

## Success Vision

A phase whose delivery gate is marked accepted but whose work is not committed is caught **loudly at the
next session boundary** by a fail-open deterministic check — not by a human noticing two uncommitted
phases later. The delivery gate (`[x] Delivery accepted` / gate-log `delivery=accepted`) can no longer
be written before the commit verifiably lands. nana-dev-kit's own `make test` stays green throughout
(firing-coverage, registration, settings-drift, README count).

## Scope

IN:
- `templates/.claude/hooks/session-start.sh` — NEW divergence detector, a sibling to the existing
  crash-recovery block (lines 44-54): if `active-phase.md` shows `- [x] Delivery accepted` for "Phase N"
  but `git log` has no commit referencing "Phase N", emit `[nana:recovery] ...`. Fail-open, advisory
  (exit 0), never blocks a session start.
- `templates/.claude/skills/dev-debrief/delivery-flow.md` — D3: assert the commit's exit status; if a
  pre-commit hook aborts the commit, surface loudly and do NOT push or mark the gate accepted.
- Gate-after-commit ordering: the delivery gate is written accepted only AFTER D3's commit verifies.
  Today `executor-prompt.md` #11 / `SKILL.md` Step 18 write `active-phase.md` BEFORE `delivery-flow.md`
  D3 runs — the executor must write the delivery gate UNCHECKED, and D3 flips it post-verified-commit.
- `tests/test_harden.sh` — extend the existing session-start firing test (already `# fires:`-anchored)
  with a behavioral assertion for the detector (emits on divergence, silent when committed, fail-open).

OUT (deferred, documented in T3):
- Same-session Stop-time catch (`session-stop.sh`) — session-start (compaction-surviving) is the
  load-bearing point; a Stop-time nudge is marginal (the agent that just skipped the commit is unlikely
  to heed a self-generated nudge). Add only if it recurs.
- The broader state-store drift (active-phase.md never advanced to Phase 3 in edge-screener) — separate
  symptom, YAGNI.
- A lifecycle eval scenario — the firing test is the gate; eval is nice-to-have.
- Retroactively fixing edge-screener's current state — manual, out-of-band.

## Constraints

- DETERMINISTIC-FIRST: the detector is the PRIMARY fix and must fire independent of agent adherence (the
  skill-text D3 it backstops was already skipped — more skill-text alone repeats the failure).
  Per [[decision:memory-architecture-classification]]: strengthen always-loaded activation points, don't
  add unwireable instructions.
- The detector must be FAIL-OPEN (exit 0, no crash on missing/garbled files) — like every other recovery
  check in `session-start.sh`.
- `session-start.sh` is ALREADY in the firing-coverage denominator (EXEMPT=0, floor 21) — extending it
  does NOT change `REQUIRED_FLOOR`/`EXEMPT`; the new branch still needs a functional assertion
  (the functional-smoke invariant — [[decision:functional-smoke-invariant-rule]]).
- Predicate must not false-positive on a correctly-committed phase: match "Phase N" case-insensitively as
  a word in `git log` (edge-screener's real commits say "Phase 1", not "Phase 1:"), checking only the
  single phase `active-phase.md` describes.
- Surgical: every changed line traces to the gate/divergence fix. Respect the `session-start.sh`
  line-cap discipline (the Phase-55 erosion scar). No unrelated cleanup.

## Assumptions

- The failure can arise two ways — the agent skipped D3, OR a pre-commit hook aborted the commit. The
  detector covers BOTH (it checks the end state); the D3 self-assert specifically covers the hook-abort
  branch. The exact Phase-2 mechanism is unknown (no transcript) and the fix is robust to that.
- `active-phase.md` reliably carries the gate state across boundaries (it is a compaction anchor) — the
  detector reads it, not transient session memory.

## Exit Criteria

- [ ] Detector emits `[nana:recovery] ...` when `active-phase.md` shows delivery accepted for Phase N and
      no git commit references "Phase N"; stays SILENT when a Phase-N commit exists. (firing test, RED-first,
      both directions.)
- [ ] Detector is fail-open: errors / missing files / no git → exit 0, no output, session start proceeds.
- [ ] `delivery-flow.md` D3 asserts commit success and does not push or mark the gate on a failed
      (e.g. hook-aborted) commit.
- [ ] The delivery gate is written accepted only after the commit verifies (executor writes it unchecked;
      D3 flips it).
- [ ] `make test` green (firing-coverage incl. the extended session-start assertion, registration,
      settings-template no-drift, README count). `make eval` unchanged (no eval surface touched).
- [ ] Deferred items (Stop-time catch, state-store drift, eval scenario) recorded in state/roadmap.
