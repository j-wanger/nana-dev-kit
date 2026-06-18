<!-- nana:approved 2026-06-18 -->
# Spec: Phase 93 — install.sh Idempotent Update / Consuming-Project Re-sync Mode (BUILD + SANDBOX-VERIFY)

## Objective

Give `install.sh` an idempotent `--update` mode that reconciles an already-installed consuming project's project-local hooks + `settings.local.json` registrations to the current kit — ADD/UPDATE changed hooks, dedupe registrations by basename, and automatically deregister cut hooks — **built and sandbox-verified only this phase, with ZERO live consumer writes.** Live application (signal-watch onboarding + the 4 staged-gate backfills) defers to a gated follow-on.

## Context

Consuming projects drift from the kit: `--project-local` cp-overwrites hook files and upserts registrations, but it (1) never REMOVES cut hooks (the Phase-88 `detect-loop` lingers → the observed 17/18/19-hook spread across edge-screener/edge-analyst/ai-game/fate/aml-substrate), (2) can't dedupe Phase-79-style hand-patched duplicate registrations because `register-settings.py` is upsert-only (DRQ-1, [[drq-1-settings-merge-semantics-are-string-keyed]]), and (3) `touch`es `.claude/enforce`, which would ARM the 4 consumers Phase 91 deliberately left un-armed. signal-watch has NO kit hooks at all. There is no idempotent "bring this consumer up to current kit" command. The kit has deliberately never shipped a deregistration mechanism (`register-settings.py` merges, never removes — [[prune-on-value-subtraction]]); every cut to date used manual sandbox-rehearsed jq surgery, and the registered-but-broken class has bitten 5× ([[HEU-012]]). This phase is the unbuilt original Phase-91 scope, re-sequenced by the Phase-92 product-for-consumers frame ([[strategic-inflection-review]]).

## Scope

### In scope
- `install.sh --update` mode: reconcile project-local hooks to the current kit (refresh changed, add new), dedupe registrations by script basename, automated basename-normalized deregistration of cut hooks, `--dry-run` reconciliation diff, hook-refresh decoupled from arming (`--arm` opt-in for `.claude/enforce`), never-installed case (signal-watch) routed through the existing `--project-local` path.
- Safety rails for the destructive dereg: `--dry-run`, timestamped backup of `settings.local.json`, tested restore, survivor functional smoke (a kept enforce hook still fires allow+block), revert-on-failure.
- A controls-first `tests/test_install_update.sh` over mktemp consumer fixtures (3 drift classes: no-hooks / staged+detect-loop-ghost / Phase-79 duplicate-registration) + seeded controls (a synthetic cut-hook + a synthetic duplicate registration the dereg/dedupe MUST catch; clean-on-seed = instrument-dead).
- `check-install-drift.sh` extended to detect the consumer drift classes `--update` reconciles (detect-and-warn complements the destructive op).
- Idempotency (re-run = no-op) + don't-clobber (preserve non-kit `settings.local.json` entries, `.dev-wiki`, project `.gitignore`).
- Makefile/MANIFEST registration of the new test; docs (install.sh header, README, AGENTS pointer).

### Out of scope
- ANY live consumer write (no external repo touched — signal-watch/edge-screener/edge-analyst/ai-game/fate/aml-substrate all untouched). The dereg path is exercised ONLY in mktemp sandboxes.
- The live application itself (signal-watch onboarding + 4 staged-gate backfills) — deferred to a gated follow-on, FILED in Blockers with a per-consumer checklist.
- Memory-layer changes (Phase 95); the memory MCP env already reaches consumers globally (Ph91).
- Reverting/editing d43950f / df3e623 / 75b48af / b8bd416.

## Approach

Extend `install.sh` (reuse cp/register/`ship_hook_dirs`, single source — NOT a separate `scripts/resync.sh`; subtraction test). Controls-first: build the mktemp consumer-fixture harness + seeded defect controls (T1) BEFORE the mode, so the destructive dereg is proven to catch a seeded cut-hook and a seeded duplicate registration before it is ever trusted. Then the `--update` reconciliation (T2: ADD/UPDATE + dedupe + decoupled arming), then the gated dereg (T3: backup + tested restore + survivor smoke + revert-on-failure), then idempotency + don't-clobber + drift-comparator integration (T4), then close-out + the deferred-application filing (T5). Every dereg/dedupe assertion runs against a fixture, never live state.

## Constraints
- BUILD + SANDBOX-VERIFY ONLY — no live consumer write under any escape hatch this phase (prevents the multi-repo registered-but-broken blast).
- Controls-first: a checker/path vouching for a clean reconcile must FIRST catch a seeded defect; clean-on-seed = instrument-dead (prevents shipping a dereg that silently no-ops).
- Destructive dereg NEVER runs without a timestamped backup + a tested restore (prevents irreversible consumer-settings corruption).
- Hook-refresh decoupled from arming — `.claude/enforce` is never touched unless `--arm` (prevents silently arming staged consumers).
- Idempotent — a second `--update` run must produce no change (prevents drift-on-re-run).
- Sandbox-first for any settings surgery (mktemp -d, never live), assert allow AND block survivor paths before trusting (HEU-012).

## Checkpoints
- After T1: the fixture harness must FLAG both seeded controls (cut-hook + duplicate registration) before any reconcile logic is written — if it does not, STOP (instrument-dead).
- After T3: report the dereg dry-run diff + backup/restore round-trip + survivor smoke result before T4.
- If a real consumer is found to hold a drift class not modeled by the fixtures: record it for the deferred follow-on (do NOT touch the consumer this phase).

## Assumptions
- Automated basename-normalized dereg can be made safe behind the rails (ledger A1). If a rail proves insufficient, the seeded-control sandbox catches it before any live use.
- The drift classes are enumerable + fixture-reproducible (ledger A5). If a real consumer holds an unmodeled class, the dry-run-first follow-on catches it.
- Build-only does not block Phase 94 — consumer memory already FIRES globally via the Ph91 PYTHONPATH env (ledger A2).

## Exit Criteria
- [ ] `bash tests/test_install_update.sh` passes, including both seeded controls (cut-hook removed+deregistered; duplicate registration deduped) and the 3 drift-class fixtures
- [ ] `install.sh --update --dry-run` on a staged fixture prints a correct reconciliation diff (adds enforce-assumption-gate, flags detect-loop for dereg, dedupes duplicates) and writes nothing
- [ ] `install.sh --update` on a staged fixture yields the current-kit project-hook set, deduped registrations, `.claude/enforce` UNCHANGED; a second run is a no-op (idempotency)
- [ ] destructive dereg produces a timestamped backup and the tested restore round-trips; survivor functional smoke (a kept enforce hook) fires exit-2-on-block and exit-0-on-allow after dereg
- [ ] non-kit `settings.local.json` entries + `.dev-wiki` + project `.gitignore` are preserved across `--update`
- [ ] `make test` ALL-PASS (new test registered); `git diff` touches ONLY kit files (no consumer repo modified)
- [ ] deferred live-application follow-on FILED in `_CURRENT_STATE` Blockers (per-consumer checklist + arm-separately note + dry-run-first)
