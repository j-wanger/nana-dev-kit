# Window Events — Cross-Phase Accumulator, Phases 89–93 (VALID fixture)

Verbatim triggers (pinned in eval/dogfood-round/pre-registration.md "## Window-events format"):

- ak-ride-along (d43950f): "Trigger: a post-compaction recovery or planning decision
  demonstrably wrong for lack of phase-pinned knowledge."
- wk-seeding (df3e623): "Trigger: re-deriving a decision working-knowledge previously pinned,
  ≥2 times." (REVERT-COUPLED with d43950f.)

## Phase 89

kit-side sessions: kit-plan-1, kit-close-1

| date | session-id | window (ak/wk) | reachability | probative? (y/n + reason) | event |
|------|------------|----------------|--------------|---------------------------|-------|
| 2026-06-12 | session-1 | ak | compaction=n planning=y | y — planning session, trigger-reachable | none |
| 2026-06-12 | session-1 | wk | pinned_decision_in_scope=y | y — own pre-trim wk file loaded | none |
| 2026-06-12 | session-2 | ak | compaction=n planning=n | n — no recovery/planning decision | none |
| 2026-06-12 | session-2 | wk | pinned_decision_in_scope=n | n — UNFALSIFIABLE-IN-THIS-CONTEXT | none |
| 2026-06-13 | session-3 | ak | compaction=y planning=y | y — post-compaction recovery occurred | none |
| 2026-06-13 | session-3 | wk | pinned_decision_in_scope=y | y — task overlaps inventory | re-derivation of crash-recovery-dual-condition observed; filed verbatim, surfaced to maintainer |
| 2026-06-12 | kit-plan-1 | ak | planning=y | n — WK-already-presents-it | none |
| 2026-06-12 | kit-plan-1 | wk | planning=y | n — WK-already-presents-it | none |
| 2026-06-13 | kit-close-1 | ak | planning=y | n — WK-already-presents-it | none |
| 2026-06-13 | kit-close-1 | wk | planning=y | n — WK-already-presents-it | none |
