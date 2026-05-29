---
title: "Phase 59: validate active-research residual delta → VERDICT CUT"
aliases: ["phase-59-cut", "research-delta-cut"]
category: journal
tags: [measurement, eval, residual-delta, llm-as-judge, subtraction-test, keep-trim-cut, dev-plan-step-2-7, negative-result, workflow-fan-out]
parents: [phase-59-validate-research-delta]
created: 2026-05-28
updated: 2026-05-28
source: debrief
duration: unknown
---

# Phase 59: Validate Active-Research Residual Delta → CUT

## What Happened

- Turned Phase 58's n=1, threshold-level +0.5 (research-favorable topic, reasoning-only) into a
  defensible keep/trim/cut decision against a pre-registered rule. T1 wrote the pre-registration
  block to `results.md` ordered BEFORE any results (machine-checked grep gate, anti p-hacking),
  reported at Checkpoint 1; T2 verified + locked 3 wiki-uncovered, domain-diverse topics (2 rich,
  1 verified research-poor-but-gate-firing).
- Ran the A/B/judge fan-out via the Workflow tool (per [[measurement-fan-out-as-workflow]]):
  per topic, clean-context baseline A (objective only) vs research-injected B (objective + ≤2
  distilled web findings), blind paired judge (reasoning-judge-v2), within-round paired deltas,
  Sonnet held constant. Findings gathered once/topic, reused across B-runs.
- T3 ran the POOR topic FIRST behind Checkpoint 2 (it's the VETO term). Commit-message/changelog
  convention: research FIRED (search=1, fetch=1, injected_findings_count=2; retrieval = 1
  semi-primary + 9 SEO/listicle → commodity confirmed). **delta = −1.0, REAL harm** (|delta|=1.0
  > spread=0.5; findings cited in all 3 B-runs ⇒ not judge-discard). Mechanism: commodity findings
  anchored B to the generic answer and crowded out the context-specific reasoning the baseline
  produced unprompted. VETO triggered → KEEP off the table.
- T4 ran the RICH topics. Retry/backoff: delta = 0.0 (variance-dominated, spread=0.79, n escalated
  3→5). Ledger isolation-level: delta = −0.4 (variance-dominated, spread=1.19, n→5). Both: findings
  cited in all B-runs yet zero lift — the baseline independently surfaced full jitter / circuit
  breakers / write-skew / serializable isolation. Research told the model what it already knew.
- T5 aggregated: new-topic mean delta = −0.47 (13 paired runs); not one topic at n≥3 positive;
  Phase 58's +0.5 sits inside the n=5 noise band (re-reads as a noise draw). Mechanical rule:
  rich no real positive (CUT condition) + poor real-negative (VETO) ⇒ **CUT**. TRIM cannot rescue
  (rich ≈ 0 even ideal). User confirmed CUT at Checkpoint 3.
- T6 remediation: removed the Step 2.7 section + Step-6 research-citation bullet from dev-plan
  SKILL.md (326→321) and deleted the `domain-research-spec.md` companion. T7 regression gate:
  test_templates.sh 169/169, make test green, make eval 54/54.

## Decisions Made

- [[cut-active-research-step-2-7|CUT active web-research injection from dev-plan Step 2.7]] --
  measured net-negative; reverses Phase 58's Fix 2; reverts dev-plan to Phase-55 behavior.

## Problems Solved

- Workflow tool: args passed via the tool's `args` param did not reach the script (args
  undefined) -- fixed by embedding the topic data as a `const` in the script. Reliable path for
  future workflow authors.
- `results.md` header level (`#` → `##`) so the section matched the exit-gate regex.

## Open Questions

- Active research's value on genuinely novel / post-training-cutoff / proprietary topics (weak
  parametric knowledge — research's theoretical sweet spot) is UNTESTED. Only well-documented
  domains were measured. A deliberate keep-for-novel-topics-only is a separate user-owned call.
- Judge inter-run variance recurred (rich-topic spread 0.79–1.19, both variance-dominated at
  n=5). Cross-model judge / judge re-calibration remains a standing lever (deferred).

## Artifacts Changed

- `templates/.claude/skills/dev-plan/SKILL.md` (removed Step 2.7 section + Step-6 research-citation bullet; 326→321 lines)
- `templates/.claude/skills/dev-plan/domain-research-spec.md` (DELETED — companion no longer referenced)
- `eval/research-measurement/results.md` (appended Phase-59 section: pre-registration block, 3-topic results, aggregate, mechanical CUT verdict, OUTCOME)

## Related

- [[phase-59-validate-research-delta|Phase 59: Validate Active-Research Residual Delta]] -- parent phase
- [[measure-residual-research-delta]] -- residual-delta-not-headline methodology (the subtraction test)
- [[pre-registered-keep-trim-cut-measurement]] -- the rule the verdict was applied mechanically against
- [[domain-research-dev-plan-step-2-7]] -- the feature that was cut (Phase 58)

## Soft Observations / Phase N+1 Candidates

- FINDING generalizes a nana-soul tenet: "retrieval/context-injection over parametric knowledge"
  does NOT pay when the model's parametric knowledge is already strong (well-documented domains).
  Research injection helped nowhere measured and harmed on commodity. | Candidate: refine the soul
  principle / extract a transferable heuristic. | evidence: results.md Phase-59 AGGREGATE + DECISION.
- The pre-registered measurement (poor-topic VETO + variance gate + burden-of-proof-on-feature)
  caught an n=1 at-threshold result that had already SHIPPED and was a false positive. | Candidate
  heuristic: n=1 at-threshold deltas are noise until replicated at n≥3 with a variance gate. |
  evidence: Phase 58 +0.5 → Phase 59 verdict CUT.
- Next-phase candidates (Phase 60): Fix 3 (AGENTS.md reshape), Fix 5 residual (kit-uninitialized
  session-start nudge), vector-search-default-on design call. | evidence: roadmap cross-refs in
  _CURRENT_STATE.md.
- Workflow tool: passing args via the tool's args param did not reach the script; embedding data
  as a const in the script was the reliable path. | Candidate: kit-note for future workflow authors.

### Activation Quality

active-knowledge.md: 3 entry blocks, 5 distinct slug references
([[pre-registered-keep-trim-cut-measurement]], [[measure-residual-research-delta]],
[[measurement-fan-out-as-workflow]], [[wiki:context-injection-budget]],
[[wiki:open-ended-over-prescriptive]]). All 3 blocks were load-bearing this session: the
pre-registered rule drove T1/T5's mechanical verdict, the judge-variance/paired-delta discipline
drove the n=3→5 escalation + variance gate, and "measurement IS the functional test" justified
treating the A/B artifact as Step 2.7's test (no binary runner). Hit rate: 3/3 blocks activated.

### Review Gate

Skeptical, independent review focused on whether the measurement justifies cutting a SHIPPED
feature: **9/10, accept.** Independently re-ran the gates (test_templates 169/169, make test
green, make eval 54/54), verified pre-registration ordering empirically (pre-reg block has zero
numeric deltas; first result 17 lines later), and confirmed both false-negative risks are
controlled — the rich findings were primary-sourced, decision-changing, and cited in every B-run
(so rich nulls = "the model already knew it", not weak findings injected); A and B differed only
by the injection. LOW: poor-topic harm rests on n=3 (thin, but it's a VETO not an averaging term —
the verdict holds on the rich nulls alone). INFO: `SKILL.md:154` "domain research / +1.75" is the
separate `/wiki-bootstrap` feature (Phase 42), not a dangling Step 2.7 reference. Verdict: the CUT
is correct; the measurement did exactly its job.
