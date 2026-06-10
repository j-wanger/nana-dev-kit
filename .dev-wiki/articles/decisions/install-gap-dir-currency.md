---
title: "Install-gap fix: extra_dirs shipping + directory currency"
slug: install-gap-dir-currency
type: decision
status: active
confidence: high
source: plan
created: 2026-06-10
updated: 2026-06-10
phase: 85
tags: [install, hooks, drift, dogfood]
---

# Install-gap fix: extra_dirs shipping + directory currency

## Decision

Fix the structural invariant, not the single instance: every install path that ships a hook script also ships the subdirectories that script consumes (modules.json `project_local.extra_dirs`, list-driven, empty-glob tolerant), and check-install-drift.sh treats "consumer script present, companion directory missing/stale" as drift via consumer-conditioned directory cells. Orphan installed-only files in covered directories are FLAGGED as drift rows (detect-and-warn charter — the checker never adds or removes files). Then migrate edge-screener off its Phase-79 hand-patch (dedupe-by-basename from settings.json + template-sourced `--project-local` install into settings.local.json, after empirically verifying duplicate-registration merge semantics) and run a ≥2-session dogfood round with a liveness-probed memory-layer answer for ledger row A5.

## Stages

- T1 install-path inventory FIRST (spec checkpoint precondition — must complete BEFORE any live write): enumerate every path that ships hook scripts (install.sh global, install.sh --project-local, py-init, ts-init, nana-init, drift-guided resync procedure) with line-cited evidence; verify the leading hypothesis that incident 5's causal path was the Phase-82 drift-guided resync (checker output as shopping list) — a hypothesis the inventory confirms or refutes, not a pre-committed conclusion; if the gap proves to live in py-init/ts-init/nana-init copy logic, those files enter scope per the spec's conditional clause. Record ~/.claude/hooks/session-start.sh consumption status (gathered evidence: registration-dead — zero references in ~/.claude/settings.json; all live registrations project-local). Pin the mode-drift exemption for .d/ files in the artifact (sourced, not executed; cmp -s is content-only) as a reasoned exemption.
- T2 kit fixes test-first: move the consumer→directory mapping to a single declared top-level `hook_dirs` map in modules.json (script → dirs, e.g. "session-start.sh" → ["session-start.d"]), replacing `project_local.extra_dirs` and migrating its 4 consumers (install.sh:72, tests/test_registration.sh:62, tests/test_hook_firing_coverage.sh:40, scripts/harness-audit.sh:385) — a `project_local`-named key driving global-path behavior would be a single-source smell; install.sh global + project-local paths ship hook_dirs alongside any consumer script they ship (empty-glob tolerant under set -e); checker directory cells conditioned on the consumer script being in the comparison set; seeded-control test (deleted dir / stale file / orphan / synced=0; synthetic second dir exercises the declared mapping) registered in the Makefile.
- T3 maintainer root: sandbox rehearsal (pinned real-capture SessionStart fixture exits 0) + live positive control → HARD checkpoint 1 (inventory verdict A1 + ship-vs-dispose decision A3 + rehearsal log + backup/tested restore) → live ~/.claude run; post-install: scope:global set equality, drift 0.
- T4 edge-screener: DRQ-1 empirical verification (duplicate hook entries across settings.json + settings.local.json — double-fire/dedupe/precedence; STOP and re-present if not double-fire) → migration plan (dedupe-by-basename, settings.local.json target per the install.sh:69 convention — keeps kit-owned entries separable from user-owned settings.json; CWD assertion before any --project-local write; explicit .bak disposition — the Phase-79 rollback is poisoned post-migration) → HARD checkpoint 2 → execute + union-uniqueness (basename identity) + single-firing count. Then dogfood: liveness probe FIRST (server-start cmd + exit code + DB row count) so any memory-layer zero counts as demand evidence, ≥2 real-work sessions, pinned evidence schema (hook | event | timestamp | helped/neutral/noise), A5 evidence FILED — evidence, not disposition.
- T5 close-out: finalize the inventory artifact rows (fixed/exempt-with-rationale), eval diff note, spec exit-criteria runner, supersession notes.

## Why

- 5th registered-but-broken incident (2026-06-09): session-start.sh md5-current while session-start.d/ EMPTY at ~/.claude — single-file currency misses directory absence; the drift checker was the resync shopping list and is blind to the directory.
- Phase-82 presence charter: a present installed copy is running code → compared regardless of scope tag; extends naturally to "consumer present ⇒ its .d/ must exist and match".
- register-settings.py is upsert-only — it cannot dedupe edge-screener's hand-patched settings.json; explicit migration required.
- Phase-83 couldnt-fire trap: a memory-layer zero without a liveness probe is not demand evidence.

## Alternatives considered

- Delete the unregistered ~/.claude project-scope hook copies (subtraction-first) instead of keeping them current — rejected this phase: regresses the Phase-82 presence charter, the copies' disposition is a separate prune-on-value question, and the checker blindness needs fixing regardless.
- Treat session-start.sh as scope:global so the global path ships it + its dir — rejected: recreates the ghost class Phase 84 just removed; the fix ships FILES, never registrations.

## Constraints honored

Spec specs/phase-85-install-gap-dogfood.md (nana:approved 2026-06-10): hard checkpoints before any out-of-repo write; seeded negative controls before checker output counts as evidence; ~/.claude/settings.json kit hooks stay == modules.json scope:global set; frozen eval/ + ledger read-only except this phase's own artifacts.

## Gate outcome

Assumption gate 2026-06-10 (ledger block appended to .dev-wiki/assumption-ledger.md + validated; all_accept: false). Survived approach review (7/10 revise → findings incorporated) and plan review (9/10 accept).

- A1 deferred don't-know → **RESOLVED confirmed at checkpoint 1** (2026-06-10): the T1 inventory's machine-checkable verdict line confirmed incident 5's causal path was the Phase-82 drift-guided resync via the dir-blind checker shopping list (py-init/ts-init exempt: recursive copy; nana-init exempt: no-copy). Ledger row now `held`.
- A2 accept — double-fire as the working model for duplicate registrations across settings.json + settings.local.json, with MANDATORY pre-checkpoint-2 empirical verification (DRQ-1; STOP and re-present if contradicted).
- A3 don't-know DOWN-SCOPED with evidence — kit fixes are independent of the dead ~/.claude/hooks/session-start.sh copy's fate (registration-dead evidence gathered at plan time); ship-vs-dispose decided at checkpoint 1.
- A4 accept — "session-start.d is the only extra_dirs entry today" defended by exhaustive grep; the fix is list-driven from modules.json regardless (synthetic second dir exercised in the sandbox test).
