---
title: "Phase 100: Contract-vs-Spec Fidelity Screen (rung-C pillar-1)"
aliases: [phase-100-contract-fidelity-screen, contract-fidelity-screen-phase]
category: phases
tags: [contract-fidelity, fidelity-screen, rung-c, contract-delegation, opencode, amplifier-screen, measurement, pre-registration, heu-012]
parents: []
created: 2026-06-22
updated: 2026-06-22
source: plan
status: active
scope: ["scripts/check-fidelity.py", "tests/test_contract_fidelity.sh", "Makefile", "companion/research/contract-screen/**", ".dev-wiki/**", ".claude/rules/active-phase.md"]
entry_criteria: "Phase 99 delivered + accepted (work commit 46473a7); spec specs/phase-100-contract-fidelity-screen.md nana:approved 2026-06-22; direction gate closed (ledger Phase-100, all_accept:false); opencode v1.17.3 confirmed on PATH."
exit_criteria: "tests/test_contract_fidelity.sh passes (seeded HONORED→0, per-guardrail VIOLATED→non-zero naming the guardrail, malformed contract→non-zero+stderr, determinism, AST no-LLM-import, offline runtime control); pre-registration byte-frozen before runs (sha256==.frozen, gitignored) with an information-parity note; leak-probe within the chance band; gaming control (det PASS, judge flags a citable defect) + judge-repeat-variance recorded; results.md = 3 arms x n>=3 with per-run fields + leak-probe-score (structural scan); verdict.md cites the frozen rule + per-arm distributions + the effect form + the contract-schema disposition; make test ALL-PASS, make eval 50/50, drift 0; companion/ untracked."
---

# Phase 100: Contract-vs-Spec Fidelity Screen (rung-C pillar-1)

## Objective

Measure empirically — not by reasoning — whether a frozen **contract** (outcome objectives + deterministic, machine-checkable guardrails) keeps a real downstream worker (`opencode`) more on-outcome than a prose spec or a bare prompt, and whether a **deterministic** fidelity-check suffices or a **neural judge** catches fidelity failures the guardrails miss. Build the deterministic fidelity-check (the scoring instrument AND the one shippable artifact) and use it — with a marked neural-judge arm — to score a pre-registered, controls-first 3-arm screen on real `opencode` runs. The verdict decides whether a contract artifact ships.

## Scope

Files and modules affected:
- `scripts/check-fidelity.py` — the deterministic fidelity-check (shippable, A4/R3)
- `tests/test_contract_fidelity.sh` + `Makefile` (`check-fidelity` target; registered in `test:`)
- `companion/research/contract-screen/**` — the measurement apparatus (gitignored, like Ph97/98): byte-frozen pre-registration, opencode runner, dual scorer, results, verdict
- `.dev-wiki/**`, `.claude/rules/active-phase.md` — lifecycle artifacts

OUT: the contract-schema's **shipped** shape (an OUTPUT of the verdict — ship in-phase if conclusive, else route to a gated build phase); pillar-2's 24/7 `opencode` worker fleet; any neural judge in the shipped check; refactoring existing scripts/generators; any `modules.json`/hook/settings change; any commit/push of `companion/research/`.

## Exit Criteria

- [ ] `bash tests/test_contract_fidelity.sh` passes: HONORED→exit 0; per guardrail, VIOLATED→non-zero naming the guardrail; malformed contract→non-zero+stderr (clean-on-seed, or any guardrail lacking a failing fixture, fails the test).
- [ ] Check determinism: two runs on the same fixture are byte-identical; AST import scan finds no network/LLM module; runtime offline control passes (no API key / no network).
- [ ] Pre-registration byte-frozen BEFORE runs: `pre-registration.md` + `.frozen` exist, `sha256==`, gitignored; the 3 payloads are at information parity (a diff-able parity note).
- [ ] Leak-probe control: a multi-option (K≥4) probe answerable only from nana docs scores within the chance band (≈1/K); at/above the frozen void threshold → run instrument-dead and void.
- [ ] Gaming control: ≥1 output where the deterministic check PASSED but the judge flagged a citable defect; judge-repeat-variance floor recorded.
- [ ] `results.md` records 3 arms × n≥3 with per-run deterministic + judge scores + run status (infra-failed excluded, not scored 0); structural required-field scan passes.
- [ ] `verdict.md` states the contract-vs-spec call (A1) + deterministic-vs-judge agreement (A2) from the frozen rule, with the contract-schema disposition + the claim scoped to the corpus.
- [ ] `make test` ALL-PASS, `make eval` 50/50, `bash scripts/check-install-drift.sh` drift 0; `git status --porcelain companion/research/` empty.

## Constraints

- **Information parity across arms** — bare/spec/contract convey the same outcome intent and differ only in the structure-under-test; else the screen measures payload size, not contract structure.
- **Non-leaking workspace + leak-probe-at-chance-or-void** — the worker and judge see ONLY the variant input in a workspace outside the repo tree (no symlink/parent-walk); a K≥4 leak-probe at/above the frozen threshold declares the run instrument-dead and void (the Ph80 in-kit leak hazard).
- **Byte-frozen before runs** — the pre-registration is sha256-frozen before the first run; the verdict reads the frozen rule with no post-hoc edits.
- **Controls-first, per-guardrail and per-scorer** ([[HEU-012]]) — a seeded HONORED output all guardrails pass + per guardrail a seeded VIOLATED output it MUST fail; a malformed contract it rejects loud; for the judge, a seeded gaming output (det PASS, judge MUST flag a citable defect) + an honored output it MUST pass.
- **Judge falsifiability** — a judge "catch" counts only when stable across the judge's own repeats AND backed by a citable, human-checkable defect; repeat-variance is reported as a control floor.
- **Infra-fail ≠ fidelity-0** — an errored/rate-limited/no-output run is excluded and re-run, never aggregated as a fidelity zero.
- **Check determinism + no-LLM-import** — same output → same verdict; no timestamp/file-ordering/network/abs-path dependence; the shipped check has no LLM/network dependency (AST scan).
- **Pinned effect floor + min-corpus** — "exceeds within-arm spread" is pinned to a concrete form (non-overlapping per-arm ranges OR delta ≥ k·pooled-SD, k frozen); below the frozen min corpus size the only permissible verdict is "underpowered / pilot-scoped, routed forward".
- **Apparatus gitignored; ship only the deterministic check** — the runner/judge/results/verdict never commit; the judge never enters any shipped path.

## Checkpoints

- After the fidelity-check + controls pass (HONORED / per-guardrail VIOLATED / gaming / malformed): report — instrument-alive gate before any screen run.
- After the pre-registration is frozen and BEFORE the first run: STOP and confirm the freeze (sha) + information parity.
- After a single pilot run per arm (n=1): verify leak-probe-at-chance + a discriminating, sometimes-disagreeing corpus + infra-fail detection. If isolation is unproven or the corpus is non-discriminating, STOP and fix before the full n≥3.
- At the verdict: report the mechanical read; the contract-schema ship/route decision is the maintainer's call.

## Assumptions

- `opencode` is scriptable headless (`opencode run --pure --format json`, v1.17.3 confirmed). If false: STOP — re-scope to a different worker runner.
- Worker isolation is achievable and verifiable (leak-probe at chance). If false: the screen is instrument-dead per Ph80 — STOP; do not report a leaked result as a verdict.
- Fidelity is deterministically scorable on a constructible corpus with ≥1 gaming case. If false: reduce to a judge-only metric, recording that A2 could not be tested deterministically.
- The neural judge can be calibrated to stable, citable agreement. If false: drop the judge arm; A2 stands on the deterministic scorer alone.
- Real-worker runs at n≥3 × 3 arms are affordable. If false: drop n before the bare-baseline arm; scope the claim to the reduced power.
- The corpus is representative enough for the claim. If below the min corpus size: the verdict is pilot-scoped and routed forward — a sub-minimum screen may NOT be reported as a contract-vs-spec conclusion.

## Notes

Reframed at the direction gate from "build the contract spine" because A1 (does a contract artifact earn its complexity over reusing `success:`/`/spec`) and A2 (is a deterministic spine enough) came back don't-know — resolvable only by running real workers. The rung-C analogue of the amplifier-screen lineage (Ph70/71/77/78/80): pre-registered, controls-first, verdict read mechanically, fair baseline arm. Pillar 3 (the dashboard, [[direction-dashboard]]) shipped first; pillar 2 (the worker fleet) is a later phase. Decision [[contract-fidelity-screen]] (medium). A null is a valid success — the controls and the freeze make it trustworthy.
