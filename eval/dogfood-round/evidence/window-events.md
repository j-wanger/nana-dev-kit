# Window Events — Cross-Phase Accumulator (Phase-88 trim-trial observation windows)

Accumulates through Phase 93 (per-phase sections below; Phases 90-93 sessions append per the
obligation in `.claude/rules/active-phase.md`). Disposition vocabulary belongs to the Phase-93
debrief, never to this file. Verbatim triggers (from the Phase-88 Blockers filings):

- ak-ride-along (d43950f): "Trigger: a post-compaction recovery or planning decision
  demonstrably wrong for lack of phase-pinned knowledge."
- wk-seeding (df3e623): "Trigger: re-deriving a decision working-knowledge previously pinned,
  ≥2 times." (REVERT-COUPLED with d43950f.)

A trigger-matching event row must be marked `filed` (and surfaced to the maintainer
immediately). Zero events is a VALID outcome. Probative/non-probative per the pinned
reachability rules; kit-side wk rows are non-probative via `WK-already-presents-it`.

## Phase 89

kit-side sessions: ef772719

| date | session-id | window | reachability | probative? | event |
|---|---|---|---|---|---|
| 2026-06-11 | session-1 | ak | compaction=n planning=y | y (real planning decisions made post-trim; incl. correct self-recovery from a stale premise without phase-pinned knowledge) | none |
| 2026-06-11 | session-1 | wk | pinned_decision_in_scope=n | n (UNFALSIFIABLE-IN-THIS-CONTEXT — task overlaps neither removed nor prospective inventory class) | none |
| 2026-06-11 | session-2 | ak | compaction=n planning=y | y (planning-relevant conclusion reached from session-1 state) | none |
| 2026-06-11 | session-2 | wk | pinned_decision_in_scope=n | n (UNFALSIFIABLE-IN-THIS-CONTEXT) | none |
| 2026-06-11 | session-3 | ak | compaction=n planning=n | n (maintenance only — no planning/recovery decision; vacuous zero, recorded as such) | none |
| 2026-06-11 | session-3 | wk | pinned_decision_in_scope=n | n (UNFALSIFIABLE-IN-THIS-CONTEXT) | none |
| 2026-06-11 | ef772719 | ak | compaction=n planning=y | y (kit-side Phase-89 planning session: full dev-plan run, spec, gate — planning decisions correct without active-knowledge re-presentation) | none |
| 2026-06-11 | ef772719 | wk | WK-already-presents-it | n (kit-side suppression: always-loaded working-knowledge still presents pinned decisions; no removed-class entry was re-derived) | none |

Close-out self-attestation: the T6 close-out session IS ef772719 (same session as the kit-side
planning rows above — both roles covered by its rows; attested before the final checker run per
the pinned universe).

Phase-89 probative exposure: ak window 3 probative sessions (2 consuming-project + 1 kit-side),
zero trigger events; wk window 0 probative sessions (suppression + inventory non-overlap —
recorded honestly; the wk trigger's live surface is the removed/prospective inventory classes,
which this phase's session tasks did not intersect).

## Phase 90

No per-session attestation rows were appended during the Phase-90 working sessions (the standing
obligation was added to active-phase.md at the Phase-89 close-out but Phase-90 sessions did not
self-attest). Recorded here as a known gap, not back-filled (no reliable post-hoc session
reconstruction). The trim-trial windows remain open through Phase 93; the Phase-90 omission does
not change any disposition (that authority is the Phase-93 debrief).

## Phase 91

kit-side sessions: phase-91-impl+debrief

| date | session-id | window | reachability | probative? | event |
|---|---|---|---|---|---|
| 2026-06-14 | p91-session | ak | compaction=n planning=y | y (kit-side Phase-91 planning + implementation: dev-plan run, gate narrowing, memory root-cause — planning/implementation decisions reached correctly without active-knowledge re-presentation) | none |
| 2026-06-14 | p91-session | wk | WK-already-presents-it | n (kit-side suppression: always-loaded working-knowledge still presents pinned decisions; no removed-class entry was re-derived) | none |

Phase-91 probative exposure: ak window 1 probative session (kit-side), zero trigger events; wk
window 0 probative sessions (kit-side suppression). Recorded honestly per the pinned reachability
rules; disposition authority unchanged (Phase-93 debrief).

## Phase 92

kit-side session: phase-92-strategic-inflection-review (this /dev-plan session)

| date | session-id | window | reachability | probative? | event |
|---|---|---|---|---|---|
| 2026-06-18 | p92-session | ak | compaction=n planning=y | y (kit-side Phase-92 strategic review + roadmap re-sequencing: dev-plan run, frame/direction gate, det-vs-LLM boundary decision reached correctly without active-knowledge re-presentation) | none |
| 2026-06-18 | p92-session | wk | WK-already-presents-it | n (kit-side suppression: always-loaded working-knowledge still presents the pinned decisions; no removed-class entry was re-derived) | none |

Phase-92 probative exposure: ak window 1 probative session (kit-side), zero trigger events; wk
window 0 probative sessions (kit-side suppression). Disposition authority unchanged (Phase-93 debrief).

## Phase 93

kit-side session: phase-93-install-resync (build + sandbox-verify + this debrief)

| date | session-id | window | reachability | probative? | event |
|---|---|---|---|---|---|
| 2026-06-18 | p93-session | ak | compaction=n planning=y | y (kit-side Phase-93 implementation: post-compaction task resume + controls-first TDD decisions reached correctly without active-knowledge re-presentation) | none |
| 2026-06-18 | p93-session | wk | WK-already-presents-it | n (kit-side suppression: always-loaded working-knowledge still presents the pinned decisions; no removed-class entry was re-derived) | none |

Phase-93 probative exposure: ak window 1 probative session (kit-side), zero trigger events; wk
window 0 probative sessions (kit-side suppression).

## Window close — disposition (Phase-93 debrief, 2026-06-18)

The 5-phase observation windows for both trim-trials close at this debrief. **Across the full window
(Phases 88, 89, 90, 91, 92, 93): ZERO trigger-matching events.** No `event: filed` row exists; every
section reads `none`. ak saw probative kit-side planning/recovery sessions (Ph89/91/92/93) that reached
correct decisions WITHOUT active-knowledge re-presentation; wk was kit-side-suppressed throughout
(always-loaded working-knowledge still presents the pinned decisions, so no removed-class entry was
re-derivable to count — recorded honestly, never back-filled; the Phase-90 self-attestation gap is
noted in that section). Windows closed CLEAN.

Disposition recommendation (authority = maintainer, executed at Phase 95 per the roadmap "make the
Ph88 trim-trials permanent if windows close clean"): **CONFIRM both ak-ride-along (d43950f) and
wk-seeding (df3e623) — not restore.** The trim-trial Blockers entries stay open until Phase 95 records
the confirm; this file is frozen at window close.

## Phase 95 — trim-trial disposition EXECUTED (2026-06-21)

Per the roadmap ("make the Ph88 trim-trials permanent if their windows close clean") and the clean
window close above (ZERO trigger-matching events Phases 88-93), the Phase-95 Memory-Layer Disposition
round records the maintainer-authority disposition:

- **CONFIRM ak-ride-along (d43950f)** — the active-knowledge re-presentation trim is permanent. Window
  closed clean; no recovery/planning decision in the window was wrong for lack of phase-pinned knowledge.
- **CONFIRM wk-seeding (df3e623)** — the debrief-side WK-seeding trim is permanent (REVERT-COUPLED with
  ak-ride-along; a restore would have taken both reverts atomically + re-run test_companions.sh — not
  triggered). Window closed clean.

Neither is restored; no revert of d43950f / df3e623. The trim-trial Blockers re-trigger entries are closed
by this disposition (see _CURRENT_STATE Blockers). Verdict recorded in
`eval/memory-disposition/verdict-table.md` (ak-ride-along=confirm, wk-seeding=confirm). Re-trigger standing
(should a future phase surface a window trigger): the trims remain git-revertible.

## Phase 96 — Consumer Re-sync Rollout (2026-06-21)

No trim-trial observation windows are open in this phase. The ak-ride-along (d43950f) + wk-seeding
(df3e623) trims were CONFIRMED permanent at Phase 95 (windows closed clean); Phase 96 introduces NO new
reversible trim-trials — it is a forward live rollout (install.sh --update / --migrate-to-local across the
7 consumers), not a removal-pending-confirmation. Reversibility of the rollout itself is carried by the
per-consumer timestamped `.claude/.migrate-backup.<ts>/` dirs (Group-B) + the pre-state WIP commits, not by
a trim-trial window. Nothing to attest against the trim accumulator this phase.
