# Active Phase Context

Phase: 85 — Install-Gap Fix + Edge-Screener Dogfood (READY FOR COMPLETION — delivery gate pending)
Objective: DONE — installer ships consumer-adjacent hook_dirs on every path; drift checker gained
consumer-conditioned directory currency (7 seeded controls); edge-screener migrated to a
template-sourced single-registration install (checkpoint 2; DRQ-1 verdict: string-keyed dedupe);
dogfood round complete (2 real sessions; A5 demand evidence: zero memory use, liveness-probed).
Scope: install.sh, scripts/check-install-drift.sh, modules.json, tests/**, eval/install-gap/**;
checkpoint-approved out-of-repo: ~/.claude (live run, drift 0), /Users/jwang/edge-screener.
Constraints honored: inventory before checkpoint 1; files-never-registrations (scope:global set
preserved); seeded controls before evidence; hard checkpoints + tested backups; couldnt-fire
probe before the memory zero counted; frozen apparatus + ledger read-only.
Exit: 9/9 via eval/install-gap/run-exit-criteria.sh (specs/phase-85-install-gap-dogfood.md).
Next: accept delivery → gate flip + commit/push; then next direction (prune-on-value round 2 /
edge-screener Phase 10 — analysis input at its .dev-wiki/phase-10-candidate-analysis.md).
Gates:
- [x] Direction confirmed by user (assumption positions A1 defer-to-checkpoint-1, A2 accept, A3 down-scoped, A4 accept — 2026-06-10)
- [x] Delivery accepted (post-implementation report 2026-06-10, commit verified)
