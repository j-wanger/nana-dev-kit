---
title: "Phase 93: install.sh Idempotent Update / Consuming-Project Re-sync Mode"
aliases: [phase-93-install-resync, install-resync, install-update-mode]
category: phases
tags: [install, consuming-projects, hooks, registration, deregistration, idempotency, build-only]
parents: []
created: 2026-06-18
updated: 2026-06-18
source: plan
status: active
scope: ["install.sh", "scripts/register-settings.py", "scripts/check-install-drift.sh", "modules.json", "tests/test_install_update.sh", "eval/install-update/fixtures/**", "Makefile", "MANIFEST", "README.md", "docs/", ".dev-wiki/**"]
entry_criteria: "Phase 92 delivered (1dc1d80); spec specs/phase-93-install-resync.md nana:approved; direction gate closed (A1-A5 accept, all_accept:true)"
exit_criteria: "the spec's 7 machine-checkable criteria — fixture+controls test green, dry-run diff correct, --update reconciles + idempotent, dereg backup/restore + survivor smoke, non-kit-state preserved, make test ALL-PASS + git diff kit-only, deferred-application Blocker filed"
---

# Phase 93: install.sh Idempotent Update / Consuming-Project Re-sync Mode

## Objective

Give `install.sh` an idempotent `--update` mode that reconciles an already-installed consuming
project's project-local hooks + `settings.local.json` registrations to the current kit — ADD/UPDATE
changed hooks, dedupe registrations by basename, and automatically deregister cut hooks — **built and
sandbox-verified only this phase, with ZERO live consumer writes.** Live application (signal-watch
onboarding + the 4 staged-gate backfills) defers to a gated follow-on.

## Scope

In scope:
- `install.sh --update` mode: reconcile project-local hooks to the current kit (refresh changed, add
  new), dedupe registrations by script basename, automated basename-normalized deregistration of cut
  hooks, `--dry-run` reconciliation diff, hook-refresh decoupled from arming (`--arm` opt-in for
  `.claude/enforce`), never-installed case (signal-watch) via the existing `--project-local` path.
- Safety rails for the destructive dereg: `--dry-run`, timestamped backup, tested restore, survivor
  functional smoke (a kept enforce hook still fires allow+block), revert-on-failure.
- `tests/test_install_update.sh` over mktemp consumer fixtures (3 drift classes) + seeded controls.
- `check-install-drift.sh` extended to detect the consumer drift classes `--update` reconciles.
- Idempotency + don't-clobber; Makefile/MANIFEST registration; docs.

OUT: ANY live consumer write (mktemp sandboxes only); the live application itself (deferred,
Blockers-filed); memory-layer changes (Phase 95; memory already reaches consumers globally via Ph91);
reverting/editing d43950f / df3e623 / 75b48af / b8bd416.

## Exit Criteria

- [ ] `bash tests/test_install_update.sh` passes — both seeded controls (cut-hook removed+deregistered; duplicate registration deduped) + the 3 drift-class fixtures
- [ ] `install.sh --update --dry-run` on a staged fixture prints a correct reconciliation diff (adds enforce-assumption-gate, flags detect-loop for dereg, dedupes duplicates) and writes nothing
- [ ] `install.sh --update` on a staged fixture yields the current-kit project-hook set, deduped registrations, `.claude/enforce` UNCHANGED; a second run is a no-op
- [ ] destructive dereg produces a timestamped backup and the tested restore round-trips; survivor functional smoke fires exit-2-on-block and exit-0-on-allow after dereg
- [ ] non-kit `settings.local.json` entries + `.dev-wiki` + project `.gitignore` preserved across `--update`
- [ ] `make test` ALL-PASS (new test registered); `git diff` touches ONLY kit files
- [ ] deferred live-application follow-on FILED in `_CURRENT_STATE` Blockers (per-consumer checklist + arm-separately note + dry-run-first)

## Constraints

- BUILD + SANDBOX-VERIFY ONLY — no live consumer write under any escape hatch (prevents the multi-repo registered-but-broken blast).
- Controls-first — a checker/path vouching for a clean reconcile must FIRST catch a seeded defect; clean-on-seed = instrument-dead (prevents shipping a dereg that silently no-ops).
- Destructive dereg NEVER runs without a timestamped backup + tested restore (prevents irreversible consumer-settings corruption).
- Hook-refresh decoupled from arming — `.claude/enforce` is never touched unless `--arm` (prevents silently arming staged consumers).
- Idempotent — a second `--update` run must produce no change.
- Sandbox-first for any settings surgery (mktemp -d, never live); assert allow AND block survivor paths before trusting (HEU-012).

## Checkpoints

- After T1: the fixture harness must FLAG both seeded controls before any reconcile logic is written — if it does not, STOP (instrument-dead).
- After T3: report the dereg dry-run diff + backup/restore round-trip + survivor smoke result before T4.
- If a real consumer is found to hold a drift class not modeled by the fixtures: record it for the deferred follow-on (do NOT touch the consumer this phase).

## Notes

Re-sequenced from the Phase-92 [[strategic-inflection-review]] (product-for-consumers frame) as the
unbuilt original Phase-91 scope and the prerequisite-shaped first move of the consumer-serving roadmap
(93 re-sync → 94 consumer memory re-measure → 95 memory-layer shrink). Decision article:
[[install-resync-update-mode]] (high). Spec: `specs/phase-93-install-resync.md` (nana:approved).
