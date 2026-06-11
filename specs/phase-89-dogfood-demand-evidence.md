<!-- nana:approved 2026-06-11 -->
# Spec: Phase 89 — Post-Trim Dogfood & Demand-Evidence Round

## Objective

Accrue genuine, probative exposure for the two Phase-88 trim-trial observation windows and
produce clean, pre-registered memory-layer demand evidence for the deferred A4/A6 disposition
round — by running real consuming-project work (edge-screener's own Phase-10 agenda) under a
verified post-trim harness. Evidence only; no dispositions.

## Context

Phase 88 shipped two REVERSIBLE trim-trials with pre-stated revert triggers and observation
windows through Phase 93: ak-ride-along (commit d43950f; trigger: a post-compaction recovery or
planning decision demonstrably wrong for lack of phase-pinned knowledge) and wk-seeding (commit
df3e623; trigger: re-deriving a previously-pinned decision ≥2 times in the window; REVERT-COUPLED
with d43950f). It also cut detect-loop.sh (75b48af) and hardened check-tests-were-run.sh
(b8bd416). The maintainer's `~/.claude` was synced 2026-06-11 (install drift 0, verified: no
15f-bis in the installed dev-plan, detect-loop.sh absent) — so the trims only became live today
and the windows have ZERO real exposure. The consuming project `/Users/jwang/edge-screener`
still carries PRE-trim project-local surfaces: `.claude/hooks/detect-loop.sh` exists and is
registered in its `settings.local.json`, and its `check-tests-were-run.sh` predates the b8bd416
harden (its false-positive class demonstrably bit there in Phase 85, session 2). Consuming-project
lag is the documented pin model (Phase-76 deferral), not a Phase-88 defect — but evidence
collected on pre-trim surfaces is invalid as post-trim exposure.

Separately, the kit-side memory-MCP-layer disposition was deferred at the Phase-88 direction
gate: A4 REJECT ruled the Phase-85 dogfood zero (2 real sessions, liveness-probed live layer,
zero voluntary memory-tool use, DB never created) NOT sufficient demand evidence; A6 REJECT kept
the memory-bridge/harvest writer steps alive so a future round gets clean demand evidence.
Phase 89 produces that evidence per a schema pinned BEFORE collection. Dispositions stay where
they belong: trim restore-or-confirm at the Phase-93 debrief; memory-layer keep/cut at a future
prune round.

Precedent: the Phase-85 dogfood protocol (`eval/install-gap/dogfood-evidence.md`) — liveness
probe FIRST so a zero counts as demand rather than couldnt-fire, ≥2 real-work sessions, pinned
observation schema (hook | event | timestamp | helped/neutral/noise), provenance honesty note
(headless maintainer-driven vs user-interactive). Known hazards: enforcement.log has no
run-provenance field (Phase-82 filing — audit/test runs contaminate it); duplicate hook
registrations with different command strings BOTH fire (string-keyed dedupe, verified
2026-06-10); in-kit measurement leaks always-loaded working-knowledge (Phase-80 INSTRUMENT-DEAD
class) — demand measurement happens in the consuming project.

## Scope

### In scope
- `eval/dogfood-round/**` (new): pre-registered schemas, probe records, evidence files,
  window-events protocol, deterministic check scripts with seeded-failure selftests, and an
  exit-criteria runner.
- Edge-screener (out-of-repo, checkpoint-gated): template-sourced project-local re-sync to
  post-trim surfaces (including removal of the cut detect-loop.sh + its registration), then
  ≥3 real-work sessions on edge-screener's own agenda (its Phase-10 planning input is ready).
- Window-events recording for BOTH kit-side and consuming-project sessions during this phase
  (the trim triggers are not project-restricted), with per-session trigger-reachability records.
- `.dev-wiki` lifecycle artifacts: Blockers updates (A4/A6 evidence pointers, filings for any
  surfaced defects), assumption-ledger row appends.

### Out of scope
- Any DISPOSITION: trim restore-or-confirm (Phase-93 debrief authority), memory-layer keep/cut
  and admissibility ruling (future prune round authority).
- Kit component changes: no skill/hook/modules.json/template edits. Defects surfaced by the
  round are FILED, never fixed mid-round — Phase 88's commits are the pinned measurement
  baseline and mid-window kit edits split it.
- Reverting or editing any trim commit or removal-set file (d43950f, df3e623, 75b48af, b8bd416).
- New edge-screener features beyond its own existing agenda; evidence-motivated busywork.
- Maintainer `~/.claude` changes (already synced; a re-sync mid-round opens a new evidence
  section, it is not performed by default).

## Approach

Pre-register before observing; verify the instrument before trusting it; collect on the
consuming project's own agenda. Sequencing principle: (1) a pre-registration commit pins the
evidence schemas, the session minimum bar, the wk-seeding pinned-decision inventory, and the
baseline header (kit HEAD SHA, sync timestamp, hashes of the surfaces sessions will actually
resolve) BEFORE any observation; (2) read-only probes establish liveness and currency; (3) a
HARD maintainer checkpoint gates the only out-of-repo write (edge-screener re-sync); (4) the
sessions run real work; (5) close-out tallies, files the A4/A6 evidence pointer, and proves the
no-disposition property mechanically. The trim windows and the demand evidence are independent
strands sharing the same sessions — a failure in one (e.g., liveness probe fails) blocks that
strand only, recorded explicitly, never a silent zero.

### Domain Research Questions

1. What would the future prune round consider ADMISSIBLE demand evidence beyond "not another
   bare zero" — session diversity, multi-session continuity cases (the layer's stated design
   purpose: session-start search + bridge stores feeding later sessions), nudge follow-through
   distribution? Pin the answer in the pre-registration, citing the A4 reject rationale and the
   Phase-83 keep-with-revisit filing, so admissibility is defined before results exist.
2. Do the A6-kept bridge/harvest writers actually WRITE during real post-trim sessions, and is
   anything they write ever READ back? Write-side liveness vs read-side demand is the
   distinction the disposition round needs — and does edge-screener's ceremony level even reach
   those writer steps?
3. What makes a per-session "no trigger-relevant event" attestation non-vacuous? A headless
   session that never crosses a compaction boundary and never makes a planning/recovery decision
   structurally cannot fire the ak trigger — its zero is non-probative. Trigger-reachability
   must be recordable per session and the probative/non-probative split must survive to the
   Phase-93 input.

## Constraints (CRITICAL)

- Evidence only, never disposition — a deterministic exit check asserts zero Phase-89 commits
  touch trim removal-set files and no `git revert` of d43950f/df3e623/75b48af/b8bd416 exists in
  the phase range; an observed trigger event is FILED verbatim and surfaced to the maintainer
  immediately, never acted on. Prevents mid-window disposition destroying the Phase-93 window.
- Evidence classification is orchestrator-executed and deterministic: the trigger-reachability
  record and the three-class memory-call classification are produced by pinned rules (transcript/
  log greps, marker cross-reference, timestamp windows) committed in the pre-registration —
  never by the measured session agent's self-attestation. Prevents subagent prose becoming
  verdict evidence (the Phase-82 standard).
- The window-events accumulator gets a MANDATORY activation point: at Phase-89 close-out the
  per-session append obligation is written into `.claude/rules/active-phase.md` (always-loaded)
  so Phases 90-93 sessions inherit it mechanically. Prevents the accumulator silently starving
  as a voluntary protocol (the HEU-012 class).
- Kit-side sessions carry a `WK-already-presents-it` non-probative subclass in the reachability
  record: in-kit, always-loaded working-knowledge still presents the pinned decisions, so the
  wk-seeding trigger is structurally suppressed there. Prevents kit-side zeros over-counting as
  confirming exposure.
- Pre-registration before observation: schemas, session bar, admissibility pins, and the
  pinned-decision inventory are committed BEFORE session 1, enforced by a first-add-commit
  ancestry check (the schema commit must be an ancestor of every evidence commit). Prevents
  retrofitting criteria to results.
- A session counts toward window exposure only with a trigger-reachability record (compaction
  occurred? planning/recovery decision made? pinned decision in scope?); failing reachability
  → the session is logged NON-PROBATIVE for that window. Prevents vacuous zeros masquerading
  as confirming exposure.
- Trims must be live at the measurement point: the evidence header records hashes of the hook/
  skill copies the session will actually resolve (project-local first, then `~/.claude`)
  compared against kit HEAD; mismatch = sync-and-document before sessions count. Prevents
  accruing exposure to the OLD harness.
- Memory-tool calls are classified `hook-prompted | rules-instructed | spontaneous` in the
  pinned schema, with enforce-memory marker states recorded in the probe; only spontaneous
  calls count toward voluntary demand. `rules-instructed` covers calls a standing always-loaded
  instruction provokes (e.g., nana-soul.md's "at session start, call memory_search with a broad
  query") — neither hook-coerced nor genuine demand. Prevents coerced or instructed use
  manufacturing the demand signal.
- The liveness probe is READ-ONLY (import check + registration read + row count; never a
  store), and each session records before/after DB row counts and enforcement.log line counts.
  Prevents the observation apparatus writing the rows it later counts.
- Event counting is basename-normalized (different command strings for the same script BOTH
  fire under the verified string-keyed dedupe). Prevents double-counting one firing as two rows.
- Log-based evidence is provenance-filtered (timestamp cross-reference against session windows,
  the Phase-88 method) — enforcement.log has no provenance field. Prevents audit/test
  contamination inflating session deltas.
- Out-of-repo writes (the edge-screener re-sync) happen only behind a HARD maintainer
  checkpoint with a timestamped backup and a tested restore, with `--project-local` CWD
  asserted before writing, and the detect-loop jq deregistration rehearsed on a COPY of the
  actual edge-screener `settings.local.json` (not only the kit fixture) before the checkpoint.
  Prevents the Phase-84-class live-state regression, wrong-root installs, and
  rehearsal-transfer surprises from schema differences.
- Sessions are real work on edge-screener's OWN agenda; the honesty note states driver
  (headless maintainer-agent vs Jake-interactive) AND whose agenda the work served; the
  edge-screener tree is left clean (committed or reverted) at session end. Prevents
  evidence-motivated busywork tainting the demand signal and half-done work littering the
  consuming project.
- Session prompts are measurement-blind: they state only the edge-screener task, never the
  measurement (memory demand, trim windows, observation). Each session's verbatim prompt is
  archived in the evidence file for audit. Prevents an observer effect — a session agent told
  it is being watched for memory use is not a clean demand instrument.
- Phase range is pinned as `<pre-registration first-add commit>..HEAD` and used identically by
  the ancestry check and the no-disposition check. Prevents two checkers disagreeing on what
  "this phase's commits" means.
- Zero observed trigger events is a VALID outcome for the window strand; zero spontaneous
  memory calls is a VALID outcome for the demand strand (with the probe excluding couldnt-fire).
  Prevents pressure to manufacture findings.
- Check scripts count as evidence only after seeded-failure selftests pass (a seeded bad
  evidence row / missing section must turn the checker RED). Prevents clean-on-seed
  instrument-dead checkers vouching for the round.
- Frozen surfaces stay frozen: prior eval apparatus and the assumption ledger are read-only
  except this phase's own new artifacts and ledger-block appends; supersession notes, never
  history rewrites.

## Success Vision

The Phase-93 debrief opens to a window-events file it can actually rule on: every Phase-89
session attested with its trigger-reachability, probative exposure separated from vacuous
exposure, any trigger-relevant event quoted against the verbatim trigger text — and the trims
demonstrably live for every counted session. The future prune round opens to memory-layer
evidence that is finally admissible on its own pre-registered terms: spontaneous demand
separated from hook-coerced use, writer liveness separated from read-back demand, zeros backed
by a read-only liveness probe — whatever direction it points. Edge-screener comes out ahead on
its own agenda (Phase 10 advanced by real sessions), its surfaces current with the post-trim
kit, its tree clean. Nothing was disposed, re-graded, or fixed mid-window; everything surfaced
was filed with a re-trigger.

## Exit Criteria (machine-checkable)

All via `bash eval/dogfood-round/run-exit-criteria.sh` (ALL-PASS only on a full run; the runner
itself carries a seeded-failure control proving partial runs cannot print ALL-PASS):

- [ ] `bash eval/dogfood-round/check-preregistration.sh` — the pre-registration file's
      first-add commit is an ancestor of every commit touching evidence files; pinned sections
      present (schemas, session bar, admissibility pins, pinned-decision inventory).
- [ ] `bash eval/dogfood-round/check-evidence-content.sh` — section-anchored content checks
      with seeded-failure selftests: evidence header pins kit HEAD SHA, sync timestamp, and
      per-surface hash comparison results; liveness-probe record carries the server import
      exit-code line (or an explicit couldnt-fire record) inside its own section; memory-demand
      close-out carries non-stub tallies for all three call classes. A seeded stub row, a
      misplaced exit-code line, and a missing header field must each turn it RED.
- [ ] `bash eval/dogfood-round/check-currency.sh` — post-resync edge-screener assertion:
      detect-loop.sh absent AND deregistered from both settings surfaces; check-tests-were-run.sh
      hash equals the kit template's; kit hooks union-unique by basename across
      settings.json + settings.local.json.
- [ ] Liveness-probe record exists at `eval/dogfood-round/evidence/liveness-probe.md` with
      server import exit code, enforce-memory marker states, and before-round DB row count —
      content-validated by `check-evidence-content.sh` above (read-only probe; never a store).
- [ ] `bash eval/dogfood-round/check-evidence-format.sh` — ≥3 session blocks in the pinned
      schema, each with ≥1 SessionStart, ≥1 PreToolUse, ≥1 Stop row, a trigger-reachability
      record, before/after row+line snapshots, and a driver+agenda provenance line; selftest
      catches a seeded malformed block.
- [ ] Memory-demand close-out exists at `eval/dogfood-round/evidence/memory-demand.md` with
      per-class call tallies (`hook-prompted | rules-instructed | spontaneous`), writer
      write/read-back counts, and end-of-round DB row count — content-validated by
      `check-evidence-content.sh` above.
- [ ] `bash eval/dogfood-round/check-window-events.sh` — window-events file carries the two
      verbatim trigger texts, one probative/non-probative attestation per session per window,
      and zero unfiled trigger events; selftest catches a seeded unattested session.
- [ ] `bash eval/dogfood-round/check-no-disposition.sh` — over the pinned phase range
      (`<pre-registration first-add commit>..HEAD`): the diff touches only
      `eval/dogfood-round/**`, `.dev-wiki/**`, `specs/**`, `.claude/rules/active-phase.md`, and
      `.claude/rules/working-knowledge.md` (lifecycle/curator writes — supersession appends
      only); `templates/**`, `modules.json`, and `MANIFEST` are byte-untouched; no revert of
      d43950f/df3e623/75b48af/b8bd416 exists in the range.
- [ ] `make test` green; `make eval` denominator 50 with any flip explained in a committed
      diff note at `eval/dogfood-round/eval-diff.md` (absent = no flips).
- [ ] `## Blockers and Open Questions` in `.dev-wiki/_CURRENT_STATE.md` carries the A4/A6
      evidence-pointer update (a line citing `eval/dogfood-round/evidence/memory-demand.md`) —
      asserted by `check-evidence-content.sh`, seeded-control-verified. Per-defect filings are
      also required in Blockers but are review-gate-verified, not checker-asserted.

## Checkpoints

- After pre-registration + read-only probes, BEFORE the edge-screener re-sync: HARD maintainer
  checkpoint presenting probe results, the re-sync plan (what changes, backup, tested restore),
  and the pinned-decision inventory. Wait for approval.
- If a trim-trial trigger-relevant event is observed in any session: file it verbatim in
  window-events and surface it to the maintainer immediately (the revert decision is theirs;
  default is record-and-continue).
- If the liveness probe fails: record couldnt-fire, mark the demand strand BLOCKED (never a
  silent zero), continue the window strand.
- If edge-screener turns out to lack real work for ≥3 sessions: STOP and ask — the downgrade
  protocol (scripted harness-exercise, recorded as weaker evidence) needs explicit approval.
- If >2 distinct post-trim harness defects surface during sessions: pause the round and present
  the filings before continuing (the harness may need a fix round before more evidence accrues).

## Assumptions

- Edge-screener's Phase-10 agenda constitutes ≥3 sessions of real work. If false: STOP at the
  checkpoint; any downgrade to scripted exercise is approved explicitly and recorded as weaker
  evidence.
- Headless maintainer-driven sessions are acceptable provenance for demand evidence (the
  Phase-85 precedent, stated plainly). If false: the round waits for Jake-interactive sessions
  and the phase timeline extends.
- Kit-side sessions count toward window exposure (the triggers are not project-restricted).
  If false: window-events is restricted to consuming-project sessions and the restriction is
  noted in the Phase-93 input.
- `install.sh --project-local` from edge-screener CWD produces post-trim surfaces. If false:
  STOP and file an install-gap defect — do not hand-patch (the Phase-79 hand-patch era is
  closed).
- The wk-seeding pinned-decision inventory is non-empty for the sessions' actual scope.
  If false: record UNFALSIFIABLE-IN-THIS-CONTEXT for that window in those sessions — never a
  confirming zero.
- The memory MCP server starts inside edge-screener sessions. If false: couldnt-fire recorded
  with probe output; the demand strand is BLOCKED, never zeroed.
