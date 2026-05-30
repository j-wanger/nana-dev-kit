---
title: "Phase 67 complete — Long-Cadence Hook Firing Tests + Hook Firing-Coverage Gate"
aliases: ["2026-05-29-phase-67-hook-firing-coverage-gate-complete"]
category: journal
tags: [hook-firing-tests, functional-smoke-invariant, coverage-gate, meta-test, long-cadence-hooks, phase-63-roadmap, phase-67]
parents: [phase-67-long-cadence-hook-firing-tests]
created: 2026-05-29
updated: 2026-05-29
source: debrief
duration: unknown
---

# Phase 67 complete — Long-Cadence Hook Firing Tests + Hook Firing-Coverage Gate

## What Happened

Made the **functional-smoke invariant machine-checkable**. For ~26 phases "every registered hook has a real firing test" lived only in PROSE ([[functional-smoke-invariant-rule]]; [[HEU-012]] verify-firing-not-presence) — the same unguarded-convention class that eroded the session-start.sh line-cap 70→137 over 30+ phases and produced 4 silent breakages (8–33 phases each). The fix targeted the GENERATOR, not the symptom holes.

- **T1 — built the gate RED-first** (`tests/test_hook_firing_coverage.sh`). Denominator = the UNION of `jq '.hooks[]|select((.type//"command")!="prompt")|.script'` (command hooks carry NO `type` field; a literal `type=="command"` matches zero and falsely greens) PLUS every `extra_dirs/*.sh` curator (the 3 session-start.d curators register via `extra_dirs`, not `.hooks[]`). Un-gameable: pinned exemption allow-list asserted by exact membership+size, each exemption machine-justified by command, a denominator-sanity floor (~21), and a permanent negative control (a bogus uncovered hook must make it FAIL). Ran it RED to emit the **authoritative untested set**.
- **The RED run was the headline finding: the true gap was 10 hooks, not the roadmap's 3** — pre/post-compact, session-stop, scan-secrets, block-dangerous-bash, auto-ruff-format, stale-queue, post-commit, context-size-check, memory-nudge. The roadmap had only flagged the 3 long-cadence advisory hooks.
- **T2 — filled the gap to GREEN.** `test_long_cadence_hooks.sh` (pre/post-compact, session-stop, check-tests allow/skip — 8 tests, side-effect-asserting in mktemp-d + HOME-override isolation), `test_tooluse_hooks.sh` (scan-secrets, block-dangerous-bash, auto-ruff-format, stale-queue, post-commit, context-size-check — 12 tests), memory-nudge direct-fire added to `test_harden.sh`. Coverage signal landed as a `# fires: <hook>` declaration anchored to a non-comment reference — bare grep-for-filename was proven useless across 3 probes (every hook name appears in the enumerating registration tests). 6 `# fires:` declarations retrofitted. Gate GREEN 20/20.
- **T3 — sandbox curator-chain regression test** (`test_install.sh`): a `--project-local` install into a mktemp-d, then FIRE the copied `session-start.sh` and assert the session-start.d curator chain executes end-to-end at the destination (not just that bytes landed) + full-set copy + executable entry point.
- **T4 — full regression + roadmap reconcile.** `make test` 18 green / `make eval` 52/52 / `test_registration` 41/41 / `test_settings_template` clean; `phase-63-remediation-roadmap.md` marks the 3 items CLOSED (Phase 67) with corrections; `eval/reasoning/.venv` hygiene verified (0 tracked, gitignored).

Reviewer 9/10, accept — all findings incorporated. Net: tests-only, no new hooks, no modules.json/settings.json change (test_registration + test_settings_template stayed green untouched, confirming no drift). `make test` grew 15→18 scripts (~390→~420 tests).

## Decisions Made

- [[hook-firing-coverage-gate|Hook firing-coverage gate — make the functional-smoke invariant machine-checkable]] — finalized this session (created at plan time, source: plan; appended a "## Consequences (as-built)": the RED gate revealed the true 10-hook gap, all 10 now firing-tested, reviewer adversarially confirmed fail-closed on a collapsed-classifier bug and on an uncovered hook).

## Problems Solved

- **Roadmap undercounted the gap (3 vs 10)** — the RED-first design surfaced 7 more untested hooks than planned. Resolved by expanding T2 to a new `test_tooluse_hooks.sh` + memory-nudge fire + 5 declaration retrofits; every change traces to the approved "Both: tests + coverage gate" direction (fix every gap the gate exposes).
- **Wrong +x assertion in the curator-chain test** — corrected: the session-start.d curators are SOURCED by session-start.sh, not executed, so they need no +x bit; changed the assertion to verify the executed entry point (session-start.sh) is +x.

## Open Questions

- None new this phase.

## Artifacts Changed

- `tests/test_hook_firing_coverage.sh` (NEW — the RED-first coverage meta-test / gate)
- `tests/test_long_cadence_hooks.sh` (NEW — pre/post-compact, session-stop, check-tests allow/skip side-effect firing tests)
- `tests/test_tooluse_hooks.sh` (NEW — scan-secrets, block-dangerous-bash, auto-ruff-format, stale-queue, post-commit, context-size-check firing tests)
- `tests/test_harden.sh` (memory-nudge direct-fire test added)
- `tests/test_install.sh` (sandbox `--project-local` curator-chain fire regression)
- `tests/test_{firing_log,cognitive_readiness,enforce,audit_log,working_knowledge_curation}.sh` (`# fires:` declaration retrofits)
- `Makefile` (test target — 3 new `@bash` lines, 15→18 scripts)
- `README.md` (script-count 15→18, ~390→~420 tests)
- `.dev-wiki/articles/phase-63-remediation-roadmap.md` (3 items CLOSED with corrections)
- `.dev-wiki/articles/decisions/hook-firing-coverage-gate.md` (Consequences as-built appended)

## Related

- [[phase-67-long-cadence-hook-firing-tests|Phase 67: Long-Cadence Hook Firing Tests + Hook Firing-Coverage Gate]] — parent phase
- [[phase-63-remediation-roadmap|Phase-63 Remediation Roadmap]] — 3 items closed (long-cadence, session-start.d drift, .venv hygiene)

## Soft Observations / Phase N+1 Candidates

- **memory-nudge.sh `timeout` portability bug** | the >500-active-entries consolidation nudge depends on `timeout` (GNU coreutils, ABSENT on stock macOS → `timeout 2 sqlite3 … || echo 0` silently yields 0 → never nudges); replace with a portable guard or document the dependency | evidence: `tests/test_harden.sh` timeout-guarded memory-nudge test + the hook ~line 29. Small fresh Phase-N+1 candidate.
- **auto-ruff-format format side-effect unasserted where ruff is absent** | env-conditional in `test_tooluse_hooks.sh`; candidate: a ruff-present CI lane, or accept the conditional | evidence: `tests/test_tooluse_hooks.sh`.
- **Coverage-gate pattern generalizes** | the "functional-smoke invariant made machine-checkable" meta-gate could extend beyond hooks to skills and eval scenarios — a "every registered component has a functional test" meta-gate | evidence: this phase's `test_hook_firing_coverage.sh`. Phase-N+1 candidate.
- **install.sh copies session-start.d/*.sh without chmod +x** (lines 89–94) unlike the main-hook loop (line 87); harmless (curators are sourced) but a one-line consistency fix someday | evidence: `install.sh:87` vs `:89-94`.

### Activation Quality

Active-knowledge had **3 entries**, all referencing [[hook-firing-coverage-gate]] / [[HEU-012]] / [[phase-63-remediation-roadmap]] — every one directly drove this session's substance (the un-gameable gate design, the union-denominator + `# fires:` signal gotchas, the 3 roadmap corrections). Hit rate **3/3 (100%)** — the plan-time distillation was load-bearing and accurate; the RED run extended (not contradicted) it by revealing the gap was 10 not 3.
