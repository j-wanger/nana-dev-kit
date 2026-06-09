# Active Phase Context

Phase: 81 — Assumption-Approval Gate
Status: READY FOR COMPLETION (4/4 tasks [x], all 10 spec exit criteria pass, make test green, make eval
52/52, reviewer 9/10 ACCEPT both findings fixed inline) — delivery gate PENDING.

Objective: the dev-plan direction gate now takes accept/reject/don't-know positions on the plan's
cost-sorted load-bearing assumptions (positions ARE the gate, REPLACING approach-approval), recorded in an
append-only cross-phase ledger whose revisit-status is surfaced at debrief — rubber-stamp → interrogator.
Earned from Phase 80's INSTRUMENT-DEAD: shipped the SIMPLEST gate (frozen NAIVE surfacer), NOT the
scope-anchored machinery. Efficacy UNMEASURABLE in-kit — tests assert MECHANICS only.
Decision [[assumption-approval-gate]] (high); spec nana:approved.

Shipped (all [x]): T1 ledger + `## Ledger schema` source + `scripts/check-assumption-ledger.sh` (4 modes +
--selftest, NO LLM) + RED-first `tests/test_assumption_ledger.sh` (20th make-test script) → T2 dev-plan
assumption-gate.md/-example.md + SKILL Step-13 rewrite (positions REPLACE approval) + Step-15f → T3
dev-debrief Assumption-Ledger Revisit forcing-function at Step 21 (NO new hook) → T4 single-schema-source
consistency + regression.

Key constraints (held):
- NO new hook (debrief-finalization check is the firing point; session-start advisory deferred).
- All-accept → warn + track all_accept:true + restate (NOT a hard block).
- Ledger append-only + per-block monotonic-row guarded; the row is the firing evidence ([[HEU-012]]).
- New gate semantics apply to FUTURE phases (Phase 82 = first live dogfood).

Residual (parked): the accretion/budget class is genuinely unmeasured — needs a CONSUMING-project context
(Ph66/69/80 representativeness). A separate user call.
Abort: if blocked >3 attempts, mark [blocked] + ask user skip/abort.

Gates:
- [x] Direction confirmed by user (assumption positions taken, no unresolved reject — approved 2026-06-09)
- [ ] Delivery accepted
