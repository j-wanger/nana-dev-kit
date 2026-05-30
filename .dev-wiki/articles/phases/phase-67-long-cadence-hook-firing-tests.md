---
title: "Phase 67: Long-Cadence Hook Firing Tests + Hook Firing-Coverage Gate"
aliases: ["phase-67-long-cadence-hook-firing-tests"]
category: phases
tags: [hook-firing-tests, functional-smoke-invariant, phase-63-roadmap, long-cadence-hooks, coverage-gate, meta-test]
parents: [phase-63-remediation-roadmap]
created: 2026-05-29
updated: 2026-05-29
source: plan
status: completed
scope: ["tests/test_hook_firing_coverage.sh", "tests/test_long_cadence_hooks.sh", "tests/test_install.sh", "tests/test_firing_log.sh", "Makefile", ".dev-wiki/articles/phase-63-remediation-roadmap.md", ".gitignore"]
entry_criteria: "Phase 66 delivered + accepted; make test 15 green / make eval 52/52 / test_registration + test_settings_template green."
exit_criteria: "test_hook_firing_coverage.sh GREEN (every firing-required hook in the .hooks[]+extra_dirs union has an invocation-anchored firing test or machine-justified exemption; floor + negative control proven); test_long_cadence_hooks.sh asserts a side-effect (not exit-code) for pre/post-compact + session-stop; test_install.sh fires the copied session-start.d chain at a sandbox destination; make test green at the new script count; make eval 52/52; test_registration + test_settings_template green; repo .dev-wiki/.nana clean post-test; roadmap marks the 3 items CLOSED with corrections."
---

# Phase 67: Long-Cadence Hook Firing Tests + Hook Firing-Coverage Gate

## Objective

Make "every registered hook has a real firing test" a machine-checkable invariant — the functional-smoke invariant is currently held only in prose — then fill the firing-test gaps it exposes. Closes three deferred Phase-63 remediation-roadmap items (long-cadence firing tests, session-start.d author-global drift, eval/reasoning `.venv` hygiene). Tests only: no new hooks, no behavior changes.

## Scope

- `tests/test_hook_firing_coverage.sh` (new RED-first coverage meta-test)
- `tests/test_long_cadence_hooks.sh` (new side-effect firing tests)
- `tests/test_install.sh` (extend: sandbox curator-chain fire), `tests/test_firing_log.sh` (check-tests allow-branch)
- `Makefile` (`test:` target — `@bash` lines only)
- `.dev-wiki/articles/phase-63-remediation-roadmap.md`, `.gitignore` (reconcile)

## Exit Criteria

- [x] `bash tests/test_hook_firing_coverage.sh` exits 0 (GREEN) — every firing-required registered hook (union of `.hooks[]` where `(.type//"command")!="prompt"`, plus `extra_dirs/*.sh`) has an invocation-anchored firing test or machine-justified exemption; prompt-type has a structural test; denominator-sanity floor (~21) + negative control proven
- [x] `bash tests/test_long_cadence_hooks.sh` exits 0 — asserts a named side-effect (not exit-code) for pre-compact / post-compact / session-stop + a graceful-skip case each
- [x] `bash tests/test_install.sh` exits 0 with the new assertion: fires the copied `session-start.sh` in a sandbox and asserts a curator effect at the destination
- [x] `make test` green at the new script count (18 scripts); `make eval` 52/52; `test_registration` 41/41 + `test_settings_template` green
- [x] Repo `.dev-wiki`/`.nana` clean after `make test` (tests did not mutate the kit's own state)
- [x] `grep -c 'CLOSED\|closed (Phase 67)' .dev-wiki/articles/phase-63-remediation-roadmap.md` ≥ 3 (= 3)

## Constraints

- Exit-code-only assertions are forbidden for firing tests — a gutted no-op advisory hook still exits 0. Prevents: a broken hook satisfying coverage.
- Denominator must be the UNION of `.hooks[].script` + `extra_dirs/*.sh` — iterating only `.hooks[]` reports 100% while the 3 curators are untested. Prevents: a curator escaping coverage.
- Classify with `(.type//"command")!="prompt"`, never literal `type=="command"` (matches zero, empties the denominator). Prevents: a falsely-green gate.
- The exemption list must be machine-bounded (literal allow-list + membership/size + per-exemption command-justification) — a self-authored gate can "exempt everything". Prevents: an un-falsifiable gate.
- No new hooks ⇒ no manifest/settings churn. Prevents: `test_registration`/`test_settings_template` drift.

## Checkpoints

- After the meta-test RED run (T1): report the authoritative untested-hook count and list. If >6 hooks, report per-hook fire-test feasibility before writing all (some may warrant a justified structural exemption).
- If the meta-test cannot distinguish a genuinely-untested hook from a justified exemption without an unmaintainable allow-list: STOP and reconsider the coverage-signal design.
- If `make eval` drifts off 52 or `test_registration`/`test_settings_template` regresses: STOP and revert.

## Notes

Roadmap corrections recorded at T4: the long-cadence gap is 3 not 4 (`check-tests-were-run` already firing-tested, `test_firing_log.sh:150`); `eval/reasoning/.venv` already gitignored + 0 tracked (verify-and-close); `install.sh --project-local` already copies `session-start.d/*.sh` (lines 89–94) — made durable as a chain-fire regression test. Governed by [[hook-firing-coverage-gate]]. See [[phase-63-remediation-roadmap]] items long-cadence, session-start.d drift, `.venv` hygiene.
