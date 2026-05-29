---
title: "Phase 59: Validate Active-Research Residual Delta"
aliases: ["validate-research-delta", "research-delta-reckoning"]
category: phases
tags: [measurement, eval, residual-delta, llm-as-judge, subtraction-test, keep-trim-cut, dev-plan-step-2-7]
parents: [phase-58-active-domain-research-in-dev-plan]
created: 2026-05-28
updated: 2026-05-28
source: plan
status: completed
scope: ["eval/research-measurement/", "templates/.claude/skills/dev-plan/domain-research-spec.md", "templates/.claude/skills/dev-plan/SKILL.md"]
entry_criteria: "Phase 58 complete + accepted; approved spec specs/phase-59-validate-research-delta.md; Phase 58 left a +0.5 composite n=1 residual delta at the significance threshold with unknown variance; the user chose to strengthen the evidence before the keep/trim/cut call."
exit_criteria: "Phase-59 section appended to eval/research-measurement/results.md (Phase-58 preserved); pre-registration block precedes results; >=3 per-topic numeric deltas with per-topic mean(A)/mean(B); both richness classes present incl. >=1 verified research-poor-but-gate-firing topic; gate-fired evidence (search/fetch counts) + poor-topic retrieval quality + load-bearing-vs-decorative recorded; mechanical keep/trim/cut verdict against pre-registered rule; make test green + make eval 100%; IF trim/cut: domain-research-spec.md/SKILL.md edited with test_templates.sh green and SKILL.md <=350."
---

# Phase 59: Validate Active-Research Residual Delta

## Objective

Turn Phase 58's n=1, threshold-level residual delta (+0.5 composite, reasoning_quality 3→4, on a deliberately research-FAVORABLE topic) into a defensible keep / trim / cut decision for dev-plan's Step 2.7 active domain research. Re-run the same with-vs-without A/B measurement (clean-context baseline vs research-injected, blind judge, decision_quality + reasoning_quality 1–5) on ≥3 wiki-uncovered, domain-diverse topics — including ≥1 deliberately research-POOR-but-gate-firing topic — at ≥3 runs per condition, against a pre-registered decision rule, to resolve whether the feature earns its standing complexity.

## Scope

Files and modules affected:
- `eval/research-measurement/results.md` — primary write target (append a Phase-59 section; preserve the Phase-58 section)
- `templates/.claude/skills/dev-plan/domain-research-spec.md` — read-only UNLESS the decision is trim/cut (then minimal remediation)
- `templates/.claude/skills/dev-plan/SKILL.md` — read-only UNLESS trim/cut touches the Step 2.7 pointer (keep ≤350 lines)

## Exit Criteria

- [ ] Phase-59 section exists in `eval/research-measurement/results.md`; Phase-58 section preserved (appended, not overwritten).
- [ ] A pre-registration block (exact topics, each topic's web-richness classification + falsifiable rationale, runs/condition, full keep/trim/cut rule incl. veto + variance + cost gates) is written and ORDERED BEFORE any results in the artifact.
- [ ] ≥3 per-topic numeric deltas in the Phase-59 section, each with per-topic `mean(A)=` / `mean(B)=` (aggregation over ≥3 runs/condition), within-topic spread reported.
- [ ] Both richness classes present: ≥2 research-RICH (distinct domains, not the "structured outputs" family) + ≥1 research-POOR-but-gate-firing.
- [ ] Per topic: gate-fired evidence (numeric search/fetch counts > 0); poor-topic actual retrieval quality (substantive/primary vs SEO/snippet) recorded; raw query results captured.
- [ ] Per topic: each injected finding recorded as load-bearing (cited at a named decision) vs decorative.
- [ ] A mechanical keep/trim/cut verdict applying the pre-registered rule to the quoted observed numbers, with the poor-topic VETO and the variance gate honored.
- [ ] `make test` exits 0; `make eval` reports 100%.
- [ ] IF (and only if) trim/cut: minimal edit to `domain-research-spec.md` (and/or SKILL.md pointer) with `tests/test_templates.sh` green and SKILL.md ≤350 lines.

## Constraints

- P-hacking via topic selection — Guard: pre-register the exact topic list + richness classification + decision rule BEFORE generating any approach; no post-result topic swaps (a forced swap logs replacement + reason + discarded partial data); topics added after results are exploratory and excluded from the primary n.
- Self-serving "keep" by default — Guard: KEEP requires affirmative satisfaction of every gate; absence of disproof is not keep; the written decision quotes the mean/spread it is keyed to.
- Judge noise mistaken for signal — Guard: ≥3 runs/condition/topic; within-round paired deltas only (never pool cross-round absolute scores); variance is a GATE (spread > |delta| ⇒ indistinguishable-from-zero ⇒ trim/cut).
- Poor-topic VETO — Guard: a negative poor-topic delta forces TRIM/CUT even if rich topics win; it is a veto, not an average term.
- Poor topic SKIPS instead of firing — Guard: confirm search/fetch counts > 0 on the poor topic; if it skips (fail-open), force-fire or swap to a thin-but-fireable topic (skip measures fail-open, out of scope).
- ~0-on-poor read as safe when the judge filtered the junk — Guard: if research fired + injected and Δ≈0, classify the zero's source: gate/distillation produced nothing (keep-compatible) vs judge discarded injected junk (TRIM signal — production has no judge). Record which.
- "Research-poor" asserted not verified — Guard: record actual retrieval; if the "poor" topic surfaced rich sources, relabel/swap — do not proceed on a false premise.
- Length / finding-presence confound — Guard: rely on Phase 50's "filler discarded" baseline defense; record load-bearing vs decorative per finding; on a linchpin rich topic that decides KEEP, run a length-matched-irrelevant control.
- Cost side never entered — Guard: net quality delta against per-fire cost (tool calls, latency, injected tokens); a true +0 on a fired topic is net-negative.
- Trim/cut remediation breaks the shipped feature — Guard: if remediation triggered, test_templates.sh + make test + make eval stay green; SKILL.md ≤350.

## Checkpoints

- After the pre-registration block (topics + falsifiable richness rationale + runs/condition + full decision rule), BEFORE generating any approach: report the design; confirm it answers DRQ 1–3 and is not reverse-engineered.
- After the research-poor topic runs: STOP and report its per-run scores, mean delta, spread, gate-fired evidence, actual retrieval quality, and the diagnosed source of any near-zero (load-bearing result; if spread > |delta|, decide repeats vs swap).
- If the emerging verdict leans KEEP on a research-rich topic's lift: run the length-matched-irrelevant control on that linchpin topic BEFORE finalizing.
- After all topics run, BEFORE the final decision: report the aggregate (per-topic deltas, mean, cross-topic spread, cost ledger) + the mechanical rule application. Final keep/trim/cut call is the user's at the delivery gate.
- If a "poor" topic turns out web-rich, or a topic is silently wiki-covered, or the poor topic SKIPS: note the deviation, swap/relabel/force-fire per the rule; do not proceed on the false premise.

## Assumptions

- The Phase 58 methodology (clean-context A/B subagents, blind judge, two dimensions) is reproducible this round. If false (judge/subagent unavailable): STOP and report — non-comparable methodology invalidates the strengthening.
- `WebSearch`/`WebFetch` are available so research can actually fire. If false: fail-open is NOT acceptable here (the phase measures the fire path) — STOP and report the environment cannot exercise the feature.
- At least one genuinely research-POOR-but-gate-firing, wiki-uncovered topic is findable and verifiable as thin. If false: label the poor-topic conclusion exploratory; do not assert a verified harmless/harmful call.
- The within-round paired delta adequately controls judge baseline variance. If false (spread swamps delta): escalate to more repeats; if still indeterminate, report "variance-dominated, inconclusive ⇒ trim/cut".
- n=3 topics × ≥3 runs/condition suffices for a directional (not publication-grade) decision. If false: report the n reached and offer to extend; do not overclaim significance.

## Notes

- The measurement IS the functional test — there is no binary eval runner for an LLM-executed skill step (per [[measure-residual-research-delta]]). `make eval` (54/54) and `make test` are REGRESSION gates only; they do not score Step 2.7's value.
- Feature under measurement: dev-plan Step 2.7, procedure in `templates/.claude/skills/dev-plan/domain-research-spec.md` (gap-gated wiki-query → bounded web research ≤10 tool-calls → ≤1200-char distilled injection at named Step 6 decisions → provenance-tagged wiki capture; fail-open). See [[domain-research-dev-plan-step-2-7]].
- Phase 58 prior data point (single run, kept): +0.5 composite (decision 4→4, reasoning 3→4) on "structured outputs"; honest standing claim recorded as "promising on research-rich gaps, likely ~0 on research-poor ones." Stands as a single-run prior; NOT pooled into the new n.
- Known judge facts (respect, don't re-derive): inter-run mean ranges 2.97–4.85; within-round paired comparisons valid, cross-round absolute scores diverge (fresh-runs); judge actively discards irrelevant filler (Phase 50 — length alone doesn't inflate). External corroboration (Anthropic "Demystifying evals"): run multiple trials because outputs vary; pairwise comparison + LLM-as-judge need calibration; isolate each trial from a clean environment (= clean-context-per-run). This is convergent with project memory, not a new method.
- Context-injection budget: 1200 chars ≈ 300–400 tokens is the measured dilution threshold ([[wiki:context-injection-budget]]); the ≤1200-char distill cap sits at it, relevant to the length-confound DRQ.
