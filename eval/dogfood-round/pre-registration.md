# Phase 89 Pre-Registration — Post-Trim Dogfood & Demand-Evidence Round

Committed BEFORE any observation (first-add-commit ancestry enforced by
`check-preregistration.sh`; the Phase-87 anti-retrofit method). Post-commit amendment of any
pinned rule below is VOID for evidence already collected. Spec:
`specs/phase-89-dogfood-demand-evidence.md` (nana:approved 2026-06-11).

## Baseline

- kit HEAD at pre-registration: 3b36d37 (Phase 88 delivery-accepted commit).
- Maintainer `~/.claude` synced 2026-06-11 (install drift 0; verified: installed dev-plan has
  no 15f-bis, `~/.claude/hooks/detect-loop.sh` absent) — the trim-trial windows are LIVE on
  the maintainer machine from this date.
- Edge-screener at pre-registration: PRE-trim (`.claude/hooks/detect-loop.sh` present +
  registered in `settings.local.json`; `check-tests-were-run.sh` hash ≠ kit template).
  Re-synced behind the T4 HARD checkpoint BEFORE any session counts.
- Edge-screener also carries pre-trim `.claude/rules/working-knowledge.md` and
  `.claude/rules/active-knowledge.md` (decay-in-place residue per the trim design; the
  active-knowledge file is the trimmed artifact class — its content is frozen residue, noted
  for the suppression rules below).
- Phase range for all range-scoped checks: `<first-add commit of this file>..HEAD`, resolved
  as `git log --diff-filter=A --format=%H -- eval/dogfood-round/pre-registration.md | tail -1`.

## Session universe

A "session" for attestation purposes is:

1. Each of the ≥3 edge-screener EVIDENCE sessions (T5), identified by their transcript JSONL
   under `~/.claude/projects/-Users-jwang-edge-screener/` with mtime inside the session's
   recorded start/end window.
2. Each kit-side Phase-89 WORKING session (including the planning session that produced this
   file and the T6 close-out session), identified by transcript JSONLs under
   `~/.claude/projects/-Users-jwang-nana-dev-kit/` with mtime inside the phase range's
   commit-time span.

Every universe member gets one attestation row per window (ak, wk) in
`evidence/window-events.md`. Kit-side sessions are expected NON-PROBATIVE for the wk window
via the `WK-already-presents-it` subclass (see Classification rules). The T6 close-out session
self-attests BEFORE the final checker run.

## Session evidence schema

Per edge-screener evidence session, one block in `evidence/sessions.md`:

```
### Session <n> — <date> <start>–<end>Z — <task title>
driver: headless-maintainer-agent | jake-interactive
agenda: <whose agenda the work served — must be edge-screener's own>
prompt: archived at evidence/prompts/session-<n>.txt (measurement-blind)
snapshots: db_rows before=<n> after=<n>; enforcement_log_lines before=<n> after=<n>
| hook | event | timestamp | judgment (helped/neutral/noise) |
| memory-call | class (hook-prompted/rules-instructed/spontaneous) | timestamp | evidence (rule that classified it) |
reachability: compaction=<y/n> planning_or_recovery_decision=<y/n> pinned_decision_in_scope=<y/n>
```

Reachability fields are computed by the orchestrator from the transcript (rules below), never
self-reported by the session agent.

## Classification rules

Orchestrator-executed, deterministic; the measured session agent's prose is NEVER evidence
(Phase-82 standard). Source of record: the session's transcript JSONL.

- A memory call = a `tool_use` block whose name matches `mcp__memory__`.
- **hook-prompted**: an enforce-memory nudge string (`[nana:enforce-memory]` or
  `memory_search detected`/`No memory_search detected`) appears in the transcript BEFORE the
  call and within the same session. Marker states (`~/.claude/enforce-memory`,
  `<project>/.claude/enforce-memory`) recorded by the T4 probe give the arming context.
- **rules-instructed**: no preceding hook nudge, AND the call is a `memory_search` that is the
  session's FIRST memory call occurring before any file-modifying tool call (the
  nana-soul.md "at session start, call memory_search with a broad query" pattern).
- **spontaneous**: neither rule matches.
- Tie-break: most-coercive-wins (hook-prompted > rules-instructed > spontaneous).
- **Blind boundary ruling (pinned now, before any session):** a rules-instructed
  `memory_search` whose returned content is subsequently USED in the session (the orchestrator
  can point to a later message that quotes or acts on a returned entry) is tallied separately
  as `instructed-with-readback`. It is NOT spontaneous demand. It IS admissible read-side
  value evidence for the disposition round, reported in its own column.
- Trigger-reachability rules (window strand): `compaction` = transcript contains a
  compaction/summary boundary record; `planning_or_recovery_decision` = the session invoked
  dev-plan/dev-debrief Skill or wrote a decision/state artifact; `pinned_decision_in_scope` =
  the session's task overlaps an inventory entry (below).

## Window-events format

`evidence/window-events.md` is a CROSS-PHASE accumulator: per-phase H2 sections; Phases 90-93
sessions keep appending until the Phase-93 disposition (mandatory activation: T6 writes the
per-session append obligation into `.claude/rules/active-phase.md`). Verbatim triggers
(from the Phase-88 Blockers filings — disposition vocabulary belongs to Phase 93, not here):

- ak-ride-along (d43950f): "Trigger: a post-compaction recovery or planning decision
  demonstrably wrong for lack of phase-pinned knowledge."
- wk-seeding (df3e623): "Trigger: re-deriving a decision working-knowledge previously pinned,
  ≥2 times." (REVERT-COUPLED with d43950f.)

Row format:
`| date | session-id | window (ak|wk) | reachability | probative? (y/n + reason) | event (none | verbatim-trigger match + description) |`

A trigger-matching event is FILED in the row verbatim and surfaced to the maintainer
immediately; it is never acted on within this phase. Zero events across all rows is a VALID
outcome.

## Pinned-decision inventory

The wk-seeding trigger surface ("a decision working-knowledge previously pinned"), constructed
BEFORE sessions:

1. **Removed class (the live trigger surface):** entries previously pinned and since pruned —
   enumerated from `.dev-wiki/.stale-queue` (5 entries as of 2026-06-11: hook-prefix-nana-
   namespace, status-in-install-sh, MANIFEST-descriptions, memory-supersede-harness-layer,
   crash-recovery-dual-condition). Re-deriving one of these in a session is a
   trigger-relevant event (counts toward the ≥2).
2. **Suppressed class (`WK-already-presents-it`):** entries still present in the loaded
   working-knowledge.md of the session's project (kit: ~90 entries; edge-screener: its own
   pre-trim file). Re-derivation of a still-present entry is recorded as DECAY evidence
   (the agent didn't read what was in context), NOT a trigger event — the trim didn't remove
   it. Kit-side sessions are non-probative for the wk window by this subclass.
3. **Prospective class:** decisions made during Phases 89-93 that meet the old seeding bar
   (cross-phase + multi-turn + non-obvious). Enumerated at each debrief into this file's
   per-phase addendum (append-only). Re-deriving one ≥2 times after it would have been seeded
   is trigger-relevant — this is the class the trim actually exposes.

Edge-screener Phase-10 scope intersects the inventory ONLY via its own project-local
working-knowledge file (suppressed class) and the prospective class; if a session's task
overlaps neither, its wk-window zero is recorded UNFALSIFIABLE-IN-THIS-CONTEXT, never
confirming.

## Admissibility pins

What this round asserts the future prune round may treat as admissible demand evidence
(citing the A4 reject: "the dogfood zero is NOT demand evidence"; and the Phase-83
keep-with-revisit filing: revisit with the post-restoration firing distribution — allow/block
ratio, block follow-through):

1. Only `spontaneous` calls count toward voluntary demand. `hook-prompted` calls feed the
   enforce-memory follow-through distribution (Phase-83 filing), reported separately.
   `rules-instructed` and `instructed-with-readback` are reported separately as
   instruction-driven use / read-side value.
2. ≥3 sessions with ≥1 multi-session continuity case (session N's task genuinely depends on
   something session N-1 produced — the layer's stated design purpose). A demand zero without
   a continuity case is admissible only as "no demand observed in independent-task sessions"
   (weaker, stated).
3. Every zero carries the read-only liveness probe (couldnt-fire excluded) and the
   deferred-tool caveat: a headless agent may fail to FIND the deferred memory tool (observed
   at gate time 2026-06-11: a scratch probe declared memory_stats unavailable rather than
   ToolSearch-ing). Tool-discovery failure rows are tallied as `couldnt-find`, distinct from
   no-demand.
4. Writer liveness vs read-back demand reported as separate counts (bridge/harvest writes vs
   any session reading a written entry back).
5. Headless rows carry `driver: headless-maintainer-agent` and are admissible per the gate's
   A5 accept; if the disposition round disputes headless provenance, it discards rows by the
   driver column, not the round.

## Session bar

≥3 real edge-screener sessions on edge-screener's own agenda. Session 1 = a real `/dev-plan`
Phase-10 planning session (trigger-reachable by nature). Sessions count only after the T4
re-sync (post-trim surfaces verified by `check-currency.sh`). The edge-screener tree is left
clean (committed or reverted) at each session's end.

## Measurement-blind prompt rule

Session prompts state ONLY the edge-screener task — never the measurement (memory demand,
trim windows, observation, evidence). Each verbatim prompt is archived at
`evidence/prompts/session-<n>.txt` before the session runs; the archived text is what the
session received (byte-identical).

## Header deferral

The pinned-sections list of this file EXCLUDES evidence/header.md: the baseline header (kit
HEAD SHA, sync timestamp, resolved-surface hash comparison) is written at T4 because final
resolved-surface hashes exist only AFTER the checkpoint-gated edge-screener re-sync.
`check-preregistration.sh` must not expect a header section here; `check-evidence-content.sh`
asserts the header at T4+. Pre-registration-before-observation still holds: no session runs
before T4 completes.

## Addendum 1 — removed-class enumeration correction (2026-06-11, post-T6 review gate; append-only)

The "## Pinned-decision inventory" removed-class enumeration above is FACTUALLY WRONG against
the committed `.dev-wiki/.stale-queue` at the T1 anchor (45460bc) — it was read from the
working tree, which carried today's not-yet-committed curator prune. Correction (the rules
themselves are unchanged; this re-enumerates the surface version-pinned):

- Removed class at 45460bc (7 committed entries): spec-provenance-html-comment,
  dev-plan-scope-extraction, nana-skill-manifest (journal phase-29), skill-based-memory-
  consolidation, hook-prefix-nana-namespace, status-in-install-sh, MANIFEST-descriptions
  (journal phase-28).
- Added by the 2026-06-11 curator prune (committed alongside this addendum): memory-supersede-
  harness-layer, crash-recovery-dual-condition. Removed class for Phases 90-93 attestations:
  all 9.
- Impact on Phase-89 rows: NONE re-graded — every wk-window row was recorded non-probative /
  UNFALSIFIABLE-IN-THIS-CONTEXT, so no probative claim rested on the mis-enumeration; rows
  stand as written.
