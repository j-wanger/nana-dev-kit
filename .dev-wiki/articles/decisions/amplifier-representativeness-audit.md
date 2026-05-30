---
title: "Amplifier Representativeness Audit — the ruler is non-representative on real data and the anchor is degenerate; ship a measurability gate, defer the live run"
aliases: [amplifier-representativeness-audit, anchor-validity-verdict, measurability-gate, phase-69-audit]
category: decisions
tags: [eval-validity, amplifier-vision, measurement, representativeness, anchor-validity, phase-69]
parents: [phase-69-amplifier-representativeness-audit]
created: 2026-05-29
updated: 2026-05-29
source: plan
confidence: high
---

## Context

Phase 68 built and control-validated the ruler (`eval/amplifier/emit-proxy-vector.sh`) against PLANTED ground-truth fixtures (n=1) and deferred everything representativeness-dependent to Phase 69: the live off/on run, n>1, the harness verdict, the `eval/comparison`+`eval/reasoning` apparatus disposition, and Frontier 1. The strategic handover framed Phase 69 as "use the ruler, run the live off/on experiment, declare the verdict."

A read-only reconnaissance THIS session falsified that plan before any spend. Running the ruler across all 8 real consuming-project transcripts (the top-level `*.jsonl` of `~/.claude/projects/-Users-jwang-ab-test` [2], `…-ab-test-stock-screener` [3], `…-ab-test-condition-c-stock-screener` [3]) produced:

1. **`ground_truth.surfaced == false` on all 8**, and **AUQ-scoped phrase hits == 0 on all 8** — while the same-day-close / look-ahead phrase appears 8–50× in raw assistant text/code per transcript. The v1 AskUserQuestion-only escalation predicate is a **structural false-negative on real provenance**: the decision surfaces in reasoning / eval-frameworks / code, never inside an AskUserQuestion event. (This is exactly the "revisit in Phase 69" caveat at `SCHEMA-NOTES.md` line 50.)
2. The look-ahead concept appears substantively even in the **harness-OFF baseline** transcripts ("checking look-ahead bias tests", "tracing data flow for look-ahead bias, entry timing") — it is a textbook stock-screener concern the base model handles unprompted. So there is **no harness gap to detect on this anchor** (mirrors the Phase-59 commodity-knowledge lesson: retrieval doesn't pay when parametric knowledge is already strong).
3. The existing transcripts are **not a clean off/on experiment** (`ab-test` = evaluation sessions, `stock-screener` = build, `condition-c` = full-harness build); the interaction-proxy deltas (escalation_count 0→0.7→4.0 across conditions) are confounded by task-type + the known Phase-42/43 subagent gap and are direction-ambiguous.

Charging into the live run would spend an expensive experiment around a degenerate, detector-invisible anchor and harvest direction-ambiguous proxies. The cheap probe falsified the expensive plan — which is the point.

## Decision

**Approach A — turn the recon into the deliverable.** User-approved via AskUserQuestion on 2026-05-29 (forks B "push the live run anyway" and C "repair the predicate + hunt a valid anchor + gated mini-run" rejected as premature). Phase 69 delivers the honest answer the live run cannot yet give and ships the runnable gate that must flip before any future live run. NO live run. Audit-only — do **not** patch the emitter or its frozen predicate (predicate repair is the deferred Approach-C work, gated by the measurability predicate). Five sub-decisions:

1. **Audit, don't measure.** The deliverable is the instrument/anchor verdict, not a harness verdict. The recon is the evidence; Phase 69 freezes it as a committed, re-runnable record (`survey-real-transcripts.sh` → `real-transcript-survey.md`) with input shasums + sourced OFF/ON provenance labels + a positive-control row that RUNS the ruler on the planted `surfaced.jsonl` fixture (proving 8/8-false is attributable to DATA, not a dead detector branch).

2. **Verdict-as-runnable-predicate (the Phase-66 idiom).** Ship `measurability-gate.sh` — a deterministic MEASURABLE / NOT-MEASURABLE / NO-DATA classifier over a transcript set, encoding the conditions a VALID off/on measurement requires (a non-commodity, detector-visible, harness-attributable anchor present across a PINNED threshold of distinct real transcripts — ≥2 ON ∧ ≥2 OFF — with an OFF-vs-ON differential; planted-fixture shasums excluded). It runs NOW and evaluates **NOT-MEASURABLE** (in-boundary count is 0, under threshold), proving it is wired and currently blocking. A `--selftest` exercises both a would-be-MEASURABLE and a correctly-NOT-MEASURABLE constructed scenario, so the gate is falsifiable in both directions (not vacuously RED forever, not trivially GREEN). This gate is the load-bearing **Phase-70 trigger**.

3. **Operational degeneracy criterion.** `VALID-MEASUREMENT.md` defines an anchor as degenerate-for-lift iff the base model produces the correct behavior unprompted in the harness-OFF baseline (zero headroom), cites the specific OFF-baseline transcripts where the look-ahead concept already appears, states the positive requirement a non-degenerate anchor must meet, and generalizes it as a reusable **anchor-headroom screen** for all future amplifier anchor selection.

4. **Honest apparatus disposition (no overclaim).** The non-blind ruler now EXISTS but Phase 69 proves it is **not yet a validated feature-gate** (NOT-MEASURABLE). So the disposition does NOT advance to "retired-for-good because the ruler supersedes": `eval/comparison/` stays the Phase-65 tombstone, `eval/reasoning/` stays calibration-only, and the **binary corpus (`make eval`) remains the sole trusted gate**. The roadmap item's decidable-when ("the real-agentic eval lands as the replacement feature-gate") becomes met only when `measurability-gate.sh` flips MEASURABLE — recorded, not pre-claimed. No CODE edits under `eval/comparison|corpus|reasoning`.

5. **Deterministic only; read-only; no harness-value claim.** No LLM/embedding/fuzzy in any path. The survey shasum-proves it does not mutate inputs; the emitter is git-diff-empty. The audit docs carry an explicit no-harness-value-claim disclaimer and contain no machine verdict token (`VERDICT: harness`, `harness_lift=`). `make eval` frozen at 52; the two probes self-test and are NOT wired as make-test gates (no README script-count bump).

## Consequences

- **Phase 69 is tooling/docs only** under `eval/amplifier/**` + `specs/` + `.dev-wiki/articles/**`. No live run, no new fixtures, no detector reimplementation, no apparatus CODE edits, no hooks/modules.json/settings.json/install.sh.
- **The honest negative is the result.** Phase 69 says precisely what is and isn't measurable and refuses any claim about whether the harness helps. This is the same burden-of-proof-on-the-feature discipline that turned the Phase-59 active-research false-positive into an honest cut.
- **The measurability gate is the Phase-70 contract.** A future phase that repairs the AUQ-only predicate (broaden to where decisions actually surface WITHOUT collapsing into raw-text matching — the `buried_phrase_outside_escalation` failure) or finds a non-commodity anchor re-runs the gate; only a flip to MEASURABLE unblocks the expensive live run.
- **Generalizable methodology lesson:** candidate anchors must pass an OFF-baseline headroom screen before any off/on measurement is designed — anchor SELECTION is upstream of measurement. Captured in working knowledge for future anchor choice, not relitigated.

## Phase-70 Handoff

Phase 70 (all gated on `measurability-gate.sh` flipping MEASURABLE, in this order): (1) **predicate repair** — broaden the escalation/`surfaced` boundary to where real decisions surface (assistant reasoning / plan-prose / ExitPlanMode), validated against the real transcripts without collapsing into raw-text matching; (2) **valid non-commodity anchor** — find/construct a decision the base model FAILS unprompted in the OFF baseline (real headroom), passing the anchor-headroom screen; (3) **the gated live off/on run** — only once (1)+(2) make the gate MEASURABLE, run the controlled harness-off vs harness-on experiment (n>1) and emit the first defensible harness verdict; (4) Frontier 1 (the escalation layer the ruler measures) remains downstream of a working measurement.

Related: [[amplifier-measurement-instrument]] (Phase 68 — the ruler this audits), [[eval-validity-verdict]], [[phase-63-remediation-roadmap]], [[park-enforcement-scorer-signal-insufficient]] (the verdict-as-runnable-probe idiom), [[cut-active-research-step-2-7]] (the commodity-knowledge / no-headroom precedent).
