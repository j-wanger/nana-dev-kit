---
title: "Phase 57 complete — Hook Consolidation and Enforcement Activation"
date: 2026-05-28
category: journal
tags: [phase-57, hook-registration, enforcement, single-source-of-truth, cascade-failure, verify-firing]
phase: 57
---

# Phase 57 — Hook Consolidation and Enforcement Activation (Fix 1)

## What happened

Fix 1 of the Phase 57+ harness-activation roadmap. The C/D stock-screener experiment proved enforcement never fired; root cause was registration fragility. Implemented the structural fix: collapsed the three disagreeing hook-registration sources into one scope-tagged `hooks` array in `modules.json`, made the per-project template a generated artifact, and made the enforce opt-in marker project-reachable. Verified enforce-spec actually FIRES (exit 2) in a fresh scaffold.

5 tasks, all TDD, all verified:
1. modules.json → one canonical scope-tagged `hooks` array (17 project + 1 global = context-size-check). Removed per-module `hooks` and `project_local.hooks`; preserved markers/extra_dirs/ghost_cleanup.
2. register-settings.py → scope-aware filtering + `--regenerate` (clean rebuild for deterministic template generation).
3. `make template` target + `tests/test_settings_template.sh` drift test (regenerate-to-temp, diff committed). Template regenerated (18 entries incl. enforce-spec/loop/memory).
4. Marker model → `.claude/enforce` (project) OR `$HOME/.claude/enforce` (global), additive/backward-compatible. Marker shipped in `templates/.claude/enforce`; install.sh --project-local creates it.
5. Headline firing test: scaffold-from-template makes enforce-spec exit 2 in an EMPTY HOME with only the project marker. + backward-compat (global-only marker still fires) + no-false-positive (allowlisted writes pass).

## Investigation findings (beyond the handover audit)

- The handover named 2 disagreeing sources; there were **three** (template, project_local.hooks, dev-wiki module.hooks), plus a **4th activation axis the audit missed**: the enforce opt-in marker is GLOBAL (`$HOME/.claude/enforce`), checked by all three enforce hooks. Per-project hook *registration* alone is insufficient — the marker had to be made project-reachable too, or a fresh scaffold registers-but-never-fires.
- Live evidence the premise holds: this session's `.dev-wiki/enforcement.log` logged 23 `block` + 182 `allow` events — the kit's own enforcement is firing (answers the handover's verification step 3, "block events or all allow?").

## Decisions

- [[single-source-scope-tagged-hook-registration]] — one scope-tagged `hooks` list in modules.json; template generated + drift-tested; marker project-reachable (project OR global). confidence: high. Chose "full single-source" over "pragmatic additive" (which would re-create the duplication this phase kills). Scope rule: project if it reads/writes project state; global if session/user ergonomics.

## Escape hatches used

- **DISCOVERY:** enforce marker is global — folded the marker-reachability fix into Fix 1 (required for the verification "does it block?" to pass via py-init alone).
- **DISCOVERY:** py-init/ts-init copied settings.json + hooks but NOT the marker — a scaffold would have registered enforce-spec yet never fired. Fixed both scaffolders + added a guard test. This is the exact "registered vs fires" pattern the phase targets, caught one level deeper by the post-implementation self-check.

## Health Delta

- Tests: +`tests/test_settings_template.sh` (drift + firing + backward-compat + scaffolder-marker guard). +1 assertion in test_registration (Direction D: scope validity). test_install.sh register-settings + functional-hook + project-local assertions updated to the new model. README test-script count 9→10.
- 10/10 test scripts green under CI-equivalent conditions.
- No type/lint changes (JSON/shell/python-config only). Memory subsystem untouched.

## Review Gate

Independent reviewer on the diff: **7/10**, core mechanism verified clean (scope filtering, marker OR-logic with fail-open preserved, `--regenerate` byte-deterministic, drift + firing tests sound, no stray readers of the old schema). Three findings, all resolved:
- **[MAJOR]** enforce-memory is registered in every scaffold but its marker (`.claude/enforce-memory`) was never shipped/created project-locally → it could never fire; my spec text overclaimed ("marker file(s)"; success vision listed enforce-memory as self-enforcing). Resolved by making the opt-in **explicit in the spec** rather than shipping the marker — shipping it would block every write in a memory-less scaffold (no `mcpServers` in the template → no way to satisfy the `.memory-consulted` gate). enforce-memory stays registered + opt-in (`touch .claude/enforce-memory`).
- **[MINOR]** Two zombie tests in test_install.sh (686–710) read the removed jq paths → vacuous pass + jq error leak. Consolidated to one canonical `.hooks[]` check with an empty-list regression guard.
- **[MINOR]** Stale "5 global enforcement hooks" strings in generate-workflow.py / generate-report.py → updated to the project-scoped model.

## Gate Compliance

Direction gate approved (Step 7, user "yes"). Delivery gate: pending acceptance of this debrief's delivery report.

## Soft Observations / Phase N+1 Candidates

- **Broken local memory venv:** `make test` halts locally at `test_memory.sh` because the memory venv exists but `sqlite-vec` is absent (documented blocker). CI skips it (venv absent → green). Candidate maintenance phase: repair the venv OR make test_memory guard `sqlite-vec` availability (it currently assumes venv-present ⟹ sqlite-vec-present). Evidence: `test_memory` fails locally, skips in CI.
- **Kit self-enforcement migration (deferred):** the kit still dogfoods via global wiring; it has no committed `.claude/settings.json`. A future deliberate step should give the kit its own per-project settings + marker to fully adopt the new model. Deferred this phase to avoid self-lockout mid-implementation.
- **Roadmap Fixes 2–5 remain:** domain research in dev-plan (highest impact, +1.75), AGENTS.md reshape (quality-not-architecture), cognitive-readiness actionable, nana-init discoverability. Sequencing: Fix 5 (nana-init) is the other "plumbing" item; Fix 2 is the high-value one.
- **Heuristic candidate:** "Verify firing, not presence" / "an opt-in marker must be reachable from wherever the hook that reads it is registered" — transferable reasoning pattern reinforced twice this phase. Capture candidate for wiki/heuristics/ (the handover's "Mandatory Over Advisory" lesson, sharpened).

## Activation Quality

Phase 57 active-knowledge.md was authored and used throughout this session (planning + implementation). Carry-forward to working-knowledge handled at phase-completion transition.
