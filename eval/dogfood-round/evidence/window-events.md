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
