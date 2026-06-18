# Active Phase Context

Phase: 93 — install.sh Idempotent Update / Consuming-Project Re-sync Mode (BUILD + SANDBOX-VERIFY)
Objective: give install.sh an idempotent `--update` mode reconciling a consumer's project-local hooks +
settings.local.json to the current kit — ADD/UPDATE + dedupe-by-basename + automated cut-hook dereg — BUILT +
SANDBOX-VERIFIED ONLY; ZERO live consumer writes (live application = a gated follow-on, filed in Blockers).
Status: COMPLETE 2026-06-18 — 5/5 tasks [x], 8/8 exit criteria, make test ALL-PASS (28 scripts), git diff KIT-ONLY.
Review gate 8/10 revise → MEDIUM (malformed-settings half-sync) fixed inline. Awaiting delivery acceptance.
Spec: specs/phase-93-install-resync.md (nana:approved). Decisions: [[install-resync-update-mode]], [[deregistration-as-register-settings-subcommands]].
Built: install.sh `--update [--arm]`; register-settings.py `--dedupe` + `deregister` (first dereg mechanism, basename-normalized);
check-install-drift.sh `--consumer`; modules.json `cut_hooks`; tests/test_install_update.sh (37 assertions, controls-first).
Trim-trial disposition (this debrief = window-close authority): ak-ride-along (d43950f) + wk-seeding (df3e623) windows closed
CLEAN — ZERO triggers Phases 88-93 → recommend CONFIRM (not restore) at Phase 95; Blockers entries stay open until then.
Next: delivery gate → Phase 94 (consumer memory re-measure) → Phase 95 (memory-layer shrink + trim confirm).
Live application of --update is DEFERRED (Blockers): dry-run-first, per consumer, arm-separately; NO live consumer write occurred.
Gates:
- [x] Direction confirmed by user (assumption positions 2026-06-18: A1-A5 accept, all_accept:true)
- [x] Delivery accepted (post-implementation report 2026-06-18; commit 5f830dc verified)
