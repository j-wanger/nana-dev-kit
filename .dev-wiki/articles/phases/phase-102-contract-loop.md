---
title: "Phase 102: Pillar 2 — contract-driven downstream-worker LOOP (edge-screener)"
aliases: [phase-102-contract-loop, contract-loop-phase, pillar-2-loop-phase]
category: phases
tags: [contract-fidelity, contract-loop, rung-c, pillar-2, edge-screener, opencode, amplifier-screen, measurement, pre-registration, integrity-invariant, gaming-detection, best-of-n, feedback-vs-resampling, heu-012]
parents: []
created: 2026-06-22
updated: 2026-06-22
source: plan
status: active
scope: ["companion/research/contract-loop/**", ".dev-wiki/**", ".claude/rules/active-phase.md"]
entry_criteria: "Phase 101 delivered + accepted (verdict: contracts help task-specifically on nameable semantic invariants, NOT implementation difficulty; decision-lag a genuine single-shot floor); spec specs/phase-102-contract-loop.md nana:approved 2026-06-22; direction gate closed (ledger Phase-102, all_accept:true); opencode on PATH; /Users/jwang/edge-screener present with its .venv."
exit_criteria: "T1 controls recorded (per task: seeded gamer passes-ALL-visible + fails-held-out, honored passes both, every visible check reds on >=1 seeded defect, held-out not transitively reachable, arm-parity one-line diff); T2 pilot.md (decision-lag single-shot fail-rate >=3 seeds — floor still exists OR no-floor null; pilot-loop iterations confirmed real retries; transcript leak-grep clean); T3 analyze-loop.py --selftest exit 0 + shasum -c .frozen OK BEFORE any scored run; T4 results.md = decision-lag + >=1 task x 4 arms x n>=3 with per-iteration trace + terminal/held-out verdicts + run-status + terminal-failure bucket, transcript leak-grep clean; T5 verdict.md = mechanical per-arm-with-intervals (floor-recovery + feedback lift contract-loop-minus-best-of-N + iterations-to-converge + buckets + gaming rate; below effect floor = directional/underpowered) OR no-floor null, claim scoped + worker pinned; /Users/jwang/edge-screener checksum identical before/after + git clean; nana-dev-kit make test PASS, make eval 50/50, drift 0 (ships nothing); companion/ untracked."
---

## Summary

Rung-C culmination (pillar 2). A MEASUREMENT phase: build a throwaway contract-driven iteration LOOP and measure whether contract-governed **feedback** (beyond mere resampling) recovers the Phase-101 single-shot FLOOR (decision-lag), and whether iteration breeds GAMING (iterate-to-green on the contract's VISIBLE guardrails while failing a HELD-OUT generative integrity test the worker never sees). 4 arms: single-shot / best-of-N (the resampling control, adversarial-added) / contract-loop / bare-loop. Deterministic-primary (held-out = ground truth), controls-first ([[HEU-012]]), byte-frozen pre-registration, real `/Users/jwang/edge-screener` never mutated, SHIPS NOTHING (check-fidelity.py already shipped Ph100). Decision: [[contract-loop]].

## Key constraints

- **Feedback ≠ resampling** — best-of-N (N independent attempts, no feedback) is the resampling control; headline = `contract-loop − best-of-N`, not `− single-shot`. Best-of-N terminal selection pinned in the freeze.
- **Gaming detectable in principle** — a seeded gamer MUST pass-all-visible + fail-held-out per task (else redundant held-out → task dropped); every visible check reds on a seeded defect; all-dead → abort.
- **Held-out never leaks** — separate file-tree, not transitively reachable from the visible-check imports; per-run transcript + shared-prompt grep voids on any held-out name/path/expected-literal hit.
- **Re-verify the single-shot floor exists** (≥3 seeds) before the freeze — no floor → no-floor null.
- **Terminal-failure bucketed** (converging-truncated / stalled / regressing); infra-fail excluded + re-rolled. **Pinned effect floor** → below it = directional/underpowered.
- Byte-frozen before scored runs; real edge-screener never mutated; claim scoped + worker pinned (`opencode/big-pickle`, this held-out probe).

## Outcome

(pending — implementation not started)
