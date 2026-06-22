---
title: "Phase 100: reframe rung-C pillar-1 from build-the-spine to a contract-vs-spec fidelity SCREEN"
aliases: [contract-fidelity-screen, contract-vs-spec-screen, fidelity-screen]
category: decisions
tags: [contract-fidelity, fidelity-screen, rung-c, contract-delegation, opencode, amplifier-screen, heu-012, measurement, pre-registration]
parents: [phase-100-contract-fidelity-screen]
created: 2026-06-22
updated: 2026-06-22
source: plan
confidence: medium
---

## Context

Phase 99 ([[direction-dashboard]]) shipped pillar 3 (the dashboard) of the rung-C contract-driven-delegation program first; pillar 1 was framed as "build the contract spine" (a contract schema + a fidelity acceptance-check). At the Phase-100 direction gate (2026-06-22, ledger Phase-100, all_accept:false) the maintainer refused to build the spine on faith: **A1** — does a new contract artifact earn its complexity over reusing the existing `success:`/`/spec` criteria (the subtraction-test fork) — and **A2** — is a deterministic spine enough — both came back **don't-know, resolvable only by running real workers** ("need to run actual test scenarios with opencode workers using different contract vs spec variants"). That converts pillar 1 from a build into a **measurement** — the rung-C analogue of the amplifier-screen lineage (Ph70/71/77/78/80): pre-registered, controls-first, verdict read mechanically.

## Decision

Phase 100 is a **measurement phase**. Build the deterministic fidelity-check (`scripts/check-fidelity.py` — the scoring instrument AND the one shippable artifact), then use it plus a calibrated, marked neural-judge arm to score a pre-registered, controls-first **3-arm screen** (bare-prompt / spec / contract) on **real `opencode` workers** (`opencode run --pure --format json`, v1.17.3 confirmed) in a non-leaking workspace outside the repo tree. The verdict decides whether a contract artifact ships.

- **Dual-use deterministic check** (A4 accept / R3 accept): the check is needed under *either* A1 outcome (Option A's contract or Option B's runner-only), so building it precommits to neither — the no-precommitment build. It ships to `scripts/` + `make` + `tests/`; the contract-schema *shape* defers to the verdict.
- **Real worker, not seeded-only** (A3 reject): a real `opencode` worker IS the instrument — seeded outputs cannot answer contract-vs-spec. A minimal slice of pillar-2 (real worker execution) merges in for the measurement only; the 24/7 fleet stays a later phase.
- **Deterministic + a marked neural-judge arm** (R1 reject of deterministic-only): every run scored twice; deterministic-vs-judge agreement (A2) measures whether a judge catches fidelity violations the guardrails miss.
- **3 arms + a frozen decision rule** (R2 accept): the bare-prompt arm is the amplifier-null guard (caught every prior null); the freeze is anti-retrofit (Ph87/97 three-tier authority).

## Why

A **null is a valid success**: "contract adds nothing over spec → collapse to runner-only" (A1) or "deterministic suffices → drop the judge" (A2) are real results because the controls and the freeze make them trustworthy. Controls-first + frozen + non-leaking per the amplifier-screen lineage: information-parity across arms (else the screen measures payload size, not contract structure); a leak-probe K≥4 arm that must score at chance or the run is instrument-dead/void (the Ph80 in-kit leak hazard — [[can't-measure-clean-context-in-kit]]); per-guardrail seeded negatives + a gaming fixture (deterministic PASSES, judge MUST flag); judge falsifiability (stable-across-repeats + citable defect, against Ph44-50 self-grading inflation); infra-fail ≠ fidelity-0; check determinism + an AST no-LLM-import gate; a pinned effect floor + a min-corpus pilot rule; byte-frozen pre-registration before runs (Ph97/98 gitignored `companion/research/` + sha256 `.frozen`). The shipped check reuses the existing `success:`-criterion shape (command + expected), not a new parallel format.

## Alternatives considered

- **Build-first / seed-test / ship the contract spine now** — rejected: ships before measuring and presupposes A1's answer (the subtraction-test fork the maintainer refused to assume).
- **Measurement-only, ship-nothing (Ph97/98-style)** — rejected: A4 ships the dual-use deterministic check (it has a shippable form independent of the schema).
- **Seeded-only validation, no real worker** (A3) — rejected: seeded outputs cannot answer contract-vs-spec; the real worker is the instrument.

## Consequences

`scripts/check-fidelity.py` + `tests/test_contract_fidelity.sh` (registered in `make test`) + a `make check-fidelity` target ship to the kit; the opencode runner, dual scorer, frozen pre-registration, results, and verdict live entirely in gitignored `companion/research/contract-screen/`. The contract-schema disposition (ship in-phase | route to a gated build phase) is an OUTPUT of the verdict. No `modules.json`/hook/settings change; the judge never enters any shipped path. Ledger Phase-100 (all_accept:false).

## Source

Phase 100 direction gate 2026-06-22 (ledger Phase-100; A1/A2 don't-know→measure, A3 reject, A4 accept, R1 reject, R2/R3 accept). Spec `specs/phase-100-contract-fidelity-screen.md` (nana:approved). Relates to [[direction-dashboard]] (Ph99, pillar 3), [[frontier-positioning-sweep]] (Ph97, rung-C named), [[can't-measure-clean-context-in-kit]] (the leak hazard), [[HEU-012]] (controls-first).
