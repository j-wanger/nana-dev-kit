---
title: "Phase 85: Install-Gap Fix + Edge-Screener Dogfood"
aliases: [install-gap-dogfood, phase-85]
category: phases
tags: [install, extra-dirs, drift, dogfood, edge-screener, memory-mcp, a5]
parents: []
created: 2026-06-10
updated: 2026-06-10
source: plan
status: active
scope: ["install.sh", "scripts/check-install-drift.sh", "modules.json", "templates/.claude/hooks/session-start.sh", "templates/.claude/hooks/session-start.d/*", "tests/**", "eval/install-gap/**", "templates/.claude/skills/{py-init,ts-init,nana-init}/** (conditional, inventory-confirmed)"]
entry_criteria: "Phase 84 delivery accepted (gate flipped, commit e894dff); spec specs/phase-85-install-gap-dogfood.md nana:approved 2026-06-10"
exit_criteria: "Spec's 9 machine-checkable criteria: make test green incl. dir-currency + extra_dirs tests; seeded-control drift test; sandbox rehearsal log with real-capture SessionStart fixture exiting 0; global-set assertion script; edge-screener union-uniqueness assertion + single-firing; live drift 0; make eval 52 denominator; dogfood evidence artifact with A5 liveness probe; install-path inventory with every row fixed|exempt"
---

# Phase 85: Install-Gap Fix + Edge-Screener Dogfood

## Objective

Close the extra_dirs install gap (no install path ships `hooks/session-start.d/` to a root that holds `session-start.sh`; `check-install-drift.sh` is blind to directory contents), then replace edge-screener's hand-patched hook registration with a durable template-sourced install and run a real consuming-project dogfood round capturing usage evidence — including a verified-live answer to whether the memory MCP layer is ever touched (feeds ledger row A5).

## Scope

Files and modules affected:
- `install.sh` — extra_dirs shipped wherever hook scripts ship; set -euo pipefail robustness
- `scripts/check-install-drift.sh` — directory-currency coverage, consumer-conditioned presence expectation
- `tests/**` — new deterministic tests with seeded negative controls
- `eval/install-gap/**` — inventory, rehearsal log, dogfood evidence, A5 probe record
- Conditional: `templates/.claude/skills/{py-init,ts-init,nana-init}/**` if inventory confirms causal path
- Out-of-repo, checkpoint-gated: `~/.claude` (session-start.d reconcile), `/Users/jwang/edge-screener` (migration + dogfood)

## Exit Criteria

See spec `specs/phase-85-install-gap-dogfood.md` — 9 machine-checkable criteria (make test, seeded-control drift test, rehearsal log, two assertion scripts, live drift 0, make eval, dogfood evidence artifact, install-path inventory).

## Constraints

See spec Constraints section. Headlines: out-of-repo writes only behind HARD checkpoints with backup + tested restore; fix ships FILES never registrations (post-fix ~/.claude/settings.json must still equal modules.json scope:global set); checker output is evidence only after seeded negative controls pass; edge-screener hook identity = script basename across settings.json + settings.local.json union; memory-layer zero counts only with a recorded liveness probe; frozen surfaces stay frozen.

## Approach

Fix the structural invariant, not the single instance (decision [[install-gap-dir-currency]], high). Five serialized stages, 8 tasks:

- **T1** install-path inventory FIRST (spec checkpoint precondition): line-cited enumeration of every hook-shipping path; verify (not assume) the hypothesis that incident 5's causal path was the Phase-82 drift-guided resync — machine-checkable verdict line; record `~/.claude/hooks/session-start.sh` consumption status (registration-dead evidence); pin the mode-drift exemption for sourced .d/ files.
- **T2** kit fixes test-first: modules.json `project_local.extra_dirs` → declared top-level `hook_dirs` map (script → dirs; 4 verified consumers migrated: install.sh:72, tests/test_registration.sh:62, tests/test_hook_firing_coverage.sh:40, scripts/harness-audit.sh:385); install.sh ships hook_dirs alongside any consumer script on BOTH paths (empty-glob tolerant under set -e); check-install-drift.sh consumer-conditioned directory cells; seeded-control test (deleted dir / stale file / orphan-flag / synced-0 + synthetic second dir) registered in Makefile.
- **T3** maintainer root: sandbox rehearsal + live positive control → HARD checkpoint 1 (inventory verdict A1 + ship-vs-dispose decision A3 + rehearsal log + backup/tested restore) → live ~/.claude run; post: scope:global set equality + drift 0.
- **T4** edge-screener: DRQ-1 empirical verification (duplicate registrations across settings.json + settings.local.json: double-fire/dedupe/precedence; STOP if not double-fire) → migration plan (dedupe-by-basename, settings.local.json target, CWD assertion, .bak disposition) → HARD checkpoint 2 → execute + union-uniqueness + single-firing count. Then dogfood: liveness probe FIRST, ≥2 real-work sessions, pinned evidence schema (hook | event | timestamp | helped/neutral/noise), A5 evidence filed (evidence, not disposition).
- **T5** close-out: finalize inventory rows, eval diff note, spec exit-criteria runner (9 criteria), supersession notes.

## Gate outcome

Direction confirmed via assumption gate 2026-06-10 (ledger block appended + validated; all_accept: false):

- A1 deferred don't-know (revisit-status: open — checkpoint 1 decides with the inventory)
- A2 accept (double-fire working model; mandatory pre-checkpoint-2 empirical verification)
- A3 don't-know down-scoped with evidence (kit fixes independent of the dead copy's fate; ship-vs-dispose at checkpoint 1)
- A4 accept (exhaustive grep defense)

## Notes

Spec approved 2026-06-10. Three Domain Research Questions open at plan time: (1) settings.json/settings.local.json merge semantics for duplicate hooks — resolved empirically in task 6 with STOP-and-re-present; (2) which install path performed the 2026-06-09 refresh — T1 inventory verdict; (3) orphan-file semantics for directory currency — decided: flag as drift row, never remove.
