---
title: "Hook firing-coverage gate — make the functional-smoke invariant machine-checkable (RED-first, un-gameable)"
aliases: [hook-firing-coverage-gate, firing-coverage-gate]
category: decisions
tags: [functional-smoke-invariant, hook-firing-tests, meta-test, phase-67, unguarded-convention]
parents: [phase-67-long-cadence-hook-firing-tests]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

The **functional-smoke invariant** ([[decision:functional-smoke-invariant-rule]], Phase 41; [[HEU-012]]: verify firing, not presence) requires that every registered component have ≥1 functional test that pipes a real event through it and asserts behavior — established after 4 silent breakages each lasting 8–33 phases (a registered-but-broken hook passes a file-existence test while doing nothing). But the invariant is held only in PROSE — nothing *enforces* that each registered hook actually has a firing test. This is the same unguarded-convention class that let the `session-start.sh` line-cap erode 70→137 lines over 30+ phases with no test catching it: a cap (or invariant) documented but not asserted will drift. The Phase-63 harness assessment left three remediation-roadmap items that all concern exactly this gap (long-cadence firing tests, session-start.d author-global drift, eval/reasoning `.venv` hygiene).

## Decision

Fix the GENERATOR, not the three symptoms: build a **RED-first coverage meta-test** (`tests/test_hook_firing_coverage.sh`) that makes "every registered hook has a real firing test" machine-checkable, then fill the gaps it surfaces.

- **Denominator = the UNION** of `jq -r '.hooks[] | select((.type // "command") != "prompt") | .script'` (command hooks have NO `type` field — only `py-review-stop-prompt.md` carries `type:"prompt"`; a literal `select(.type=="command")` matches zero hooks and falsely greens the gate) **PLUS** every `*.sh` under each `project_local.extra_dirs` entry (the 3 `session-start.d/` curators are registered via `extra_dirs`, NOT `.hooks[]`, and must not escape coverage). Expected total: 17 command + 1 prompt + 3 curators = **21**.
- **Coverage is invocation-anchored, NOT bare-filename grep** — empirically useless here (3 probes confirmed every hook name appears in `test_registration.sh` / `test_settings_template.sh`, and invocation uses `HOOK="…"; bash "$HOOK"` indirection). The signal must prove a test *fires* the hook and cannot be satisfied by an incidental mention or comment.
- **The gate is un-gameable** (it is self-authored, so "exempt everything" must fail it): (a) a literal exemption allow-list asserted by exact membership + size; (b) each exemption proves its reason by command — `prompt`-type via `jq '.type=="prompt"'`, transitive-fire via the covering test's declared marker; (c) a **denominator-sanity floor** (~21) so a classifier bug that empties the set fails loudly instead of reporting 100%; (d) a **negative control** — a bogus uncovered hook must make the gate FAIL.
- **Firing tests assert load-bearing SIDE-EFFECTS, not exit-code-only** — a gutted no-op advisory hook still exits 0. They run in `mktemp -d` + `HOME`-override isolation so they can't mutate the kit's own `.dev-wiki/`/`.nana/`.

Alternatives rejected: (a) patch only the 3 known holes — leaves the generator unguarded, recurrence guaranteed (the very pattern that produced 4 prior silent breakages); (b) grep-based coverage — empirically useless (the 3 probes above).

## Consequences

A new contributor who adds a hook and forgets its firing test sees `make test` fail with a message naming the uncovered hook and what to do — the silent-breakage class becomes impossible to merge. The phase is tests-only: NO `modules.json` / `settings.json` / `make template` change (no new hooks), so `test_registration.sh` (bidirectional) and `test_settings_template.sh` (drift) stay green untouched, and `make eval` stays at its dynamic 52. Closes 3 Phase-63 roadmap items with corrections: the long-cadence gap was 3 not 4 (`check-tests-were-run` already firing-tested at `test_firing_log.sh:150`); `eval/reasoning/.venv` already gitignored + 0 tracked (verify-and-close); `install.sh --project-local` already copies `session-start.d/*.sh` (lines 89–94) — made durable as a chain-fire regression test. Cross-links: [[decision:functional-smoke-invariant-rule]], [[HEU-012]], [[decision:bidirectional-registration-invariant]], [[phase-63-remediation-roadmap]].

## Consequences (as-built)

The RED-first gate did its job: the authoritative untested set it emitted was **10 hooks, not the roadmap's 3** — pre/post-compact, session-stop, scan-secrets, block-dangerous-bash, auto-ruff-format, stale-queue, post-commit, context-size-check, memory-nudge. All 10 now have side-effect-asserting firing tests (`test_long_cadence_hooks.sh`, `test_tooluse_hooks.sh`, memory-nudge direct-fire in `test_harden.sh`), via 6 retrofitted `# fires: <hook>` declarations. The coverage signal landed as a `# fires: <hook>` declaration anchored to a non-comment reference — bare grep-for-filename was proven useless across 3 probes (every hook name appears in the enumerating registration tests). `make test` grew **15 → 18 scripts** (~390 → ~420 tests); `make eval` held at 52/52; `test_registration` (41/41) and `test_settings_template` stayed green untouched (confirming no manifest/settings drift). The reviewer **adversarially confirmed the gate fails closed** — both on a collapsed-classifier bug (denominator-sanity floor catches it) and on a genuinely uncovered hook (negative control). The denominator is the union of command `.hooks[]` + every `extra_dirs` curator; the exemption allow-list is bounded by exact count; a permanent negative-control self-test is baked in. Reviewer verdict 9/10, accepted. Confidence unchanged (high). Surfaced-but-unfixed: `memory-nudge`'s >500-entries path depends on `timeout` (absent on stock macOS) — a latent portability gap filed as a Phase-N+1 candidate, NOT in scope here.
