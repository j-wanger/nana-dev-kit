---
title: "CUT active web-research injection from dev-plan Step 2.7 (Phase 59)"
aliases: ["cut-active-research", "cut-step-2-7", "research-injection-cut", "fix-2-reversal"]
category: decisions
tags: [measurement, eval, residual-delta, llm-as-judge, subtraction-test, keep-trim-cut, dev-plan-step-2-7, negative-result, parametric-knowledge]
parents: [phase-59-validate-research-delta]
created: 2026-05-28
updated: 2026-05-28
source: plan
confidence: high
---

## Context

Phase 58 shipped dev-plan's Step 2.7 (gap-gated active web research that injects distilled
findings into the proposed approach) on the strength of a single, threshold-level data point:
+0.5 composite at n=1, reasoning-only (decision_quality flat 4→4, reasoning_quality 3→4), on a
deliberately research-FAVORABLE topic, against a judge whose inter-run mean ranges 2.97–4.85.
That number was too thin to bank — under-powered, at the significance threshold, with unknown
variance, and easy to bias toward "keep" by inertia (the feature was already shipped). Phase 59
strengthened the evidence against a pre-registered keep/trim/cut rule (see
[[pre-registered-keep-trim-cut-measurement]]) to resolve whether the feature earns its standing
complexity.

## Decision

**CUT** the active web-research + injection in dev-plan Step 2.7. Revert dev-plan to its
Phase-55 behavior.

Evidence (3 new wiki-uncovered topics, 13 paired within-round runs at n≥3, judge-v2, escalation
to n=5 + variance gate; results in `eval/research-measurement/results.md`):

- **Poor topic (commit-message/changelog convention): delta = −1.0, REAL harm** (|delta|=1.0 >
  spread=0.5; findings cited in all B-runs; injected_findings_count=2). Mechanism from judge
  rationales: commodity findings *anchored* B to the generic "Conventional Commits +
  semantic-release" answer and *crowded out* the deeper, context-specific reasoning the baseline
  produced unprompted (squash-merge footgun, CD-vs-not conditional). Not the Phase-50
  judge-discard case — genuine harm.
- **Rich topic retry/backoff: delta = 0.0** (variance-dominated, spread=0.79); **rich topic
  ledger-isolation: delta = −0.4** (variance-dominated, spread=1.19). Findings cited in all
  B-runs yet zero lift — the baseline independently proposed full jitter, circuit breakers,
  write-skew/serializable isolation. Research told the model what it already knew.
- **Not one topic at n≥3 was positive.** Phase 58's +0.5 now sits well inside the n=5 noise
  band (spread 0.79–1.19) — it re-reads as a noise draw, not a banked effect.

Mechanical rule application: rich topics show no real positive delta (CUT condition MET) AND the
poor topic is real-negative (VETO — KEEP impossible). TRIM cannot rescue: a finding-quality gate
or rich-only firing only helps if research *helps* on rich topics, and it does not (rich ≈ 0) —
a gate cannot manufacture a lift that is absent even under ideal conditions.

Root cause: on well-documented software-engineering domains a strong baseline model already holds
the relevant knowledge in-parameter; injecting researched findings is redundant at best (rich ≈
0) and anchoring-harmful at worst (poor −1.0).

Alternatives rejected: **TRIM** — can't rescue (rich ≈ 0 even under ideal conditions); **KEEP** —
vetoed by the real-negative poor-topic delta and unsupported by any rich-topic lift; untested
speculative upside on novel topics does not earn a KEEP under burden-of-proof-on-the-feature.

## Consequences

dev-plan reverts to Phase-55 behavior; the Phase 57+ harness-activation roadmap's "Fix 2" is
**shipped (58) → measured net-negative (59) → removed**. Implemented: removed the Step 2.7
section + the Step-6 research-citation bullet from
`templates/.claude/skills/dev-plan/SKILL.md` (326→321 lines) and deleted
`templates/.claude/skills/dev-plan/domain-research-spec.md`. Verified: `tests/test_templates.sh`
169/169, `make test` green, `make eval` 54/54 (100%).

Scope caveat (does NOT change the verdict): all four measured topics are *well-documented*
domains — exactly where parametric knowledge is strongest and research helps least. The feature
was NOT tested on genuinely novel / post-training-cutoff / proprietary topics (weak parametric
knowledge — research's theoretical sweet spot). The defensible claim is narrow: active
web-research injection adds no measurable value and can harm on *well-documented* topics; its
value on novel/post-cutoff topics is untested. A deliberate keep-for-novel-topics-only would be
a separate, user-owned call.

Generalizes a nana-soul tenet: "retrieval/context-injection over parametric knowledge" does NOT
pay when the model's parametric knowledge is already strong. The pre-registered measurement
(poor-topic VETO + variance gate + burden-of-proof-on-the-feature) earned its keep by catching
an n=1 at-threshold result that had already SHIPPED (Phase 58) and proved a false positive — the
subtraction test working as intended.
