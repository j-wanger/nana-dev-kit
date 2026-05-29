---
title: "Domain research in dev-plan via gap-gated Step 2.7 (mechanism c)"
aliases: ["step-2-7-research", "active-domain-research", "gap-gated-research"]
category: decisions
tags: [dev-plan, domain-research, wiki-query, context-shaping, fail-open, provenance, prompt-injection]
parents: [phase-58-active-domain-research-in-dev-plan]
created: 2026-05-28
updated: 2026-05-28
source: plan
status: accepted
confidence: medium
phase: 58
---

## Decision

Add a bounded, gap-gated research step — **Step 2.7** — to dev-plan, between Step 2.5 (iterative retrieval) and Step 3 (scope exploration). For each `### Domain Research Question` the spec poses, query the local wiki via `wiki-query`; research fires **only** on questions the wiki does not already answer. Uncovered questions get bounded web research (numeric caps), findings are distilled to a ~1200-char context-shaped summary injected at **named** Step 6 approach decisions, and durable facts persist via the wiki's existing capture path with provenance (source URL, date, `auto-researched`) plus a contradiction check before persist. The procedure lives in a companion file (`domain-research-spec.md`) because dev-plan SKILL.md is at 321/350 — no room to inline.

## Context

Phase 55 reformed the spec template so it now *poses* Domain Research Questions, but nothing answers them and dev-plan only reads the *existing* wiki — when coverage is thin it merely recommends the user run `/wiki-bootstrap` manually (`SKILL.md:154`). So the planner still guesses from parametric knowledge on uncovered topics. This is Fix 2 of the Phase 57+ harness-activation roadmap.

## Rationale

- **Findings should land where design decisions are made** — the Step 6 approach. Mechanism (c) routes research findings directly into the approach so they visibly shape decisions, rather than sitting elsewhere.
- **Per-question wiki-query gate, not Step 2.5's concept-coverage score** — those are different signals. The concept score scores concepts extracted from objective/scope; the gate must test whether the wiki answers *each posed question*. Covered topics cost zero external calls.
- **Bounded + fail-open are mandatory** because Step 2.7 runs on every standard-ceremony plan. Explicit numeric caps degrade to partial findings; no web / no questions / no writable wiki / timeout → skip with an explicit marker, never relabel a parametric guess as "researched."
- **Injection-safe**: question text is LLM-generated from a prior phase and fed to a web-searching agent — treat it strictly as a search topic (data), never as an instruction.
- **DRY**: reuse the `wiki-add` capture path and align findings format with `wiki-bootstrap`; do not build a 4th research crawler. Persistence routes through the standard capture path so the `wiki-absorb` curation gate is preserved.

## Alternatives considered

- **(a) Spec answers its own Domain Research Questions (rejected):** re-prescribes content into the spec, cutting against the Phase 55 reform (less-prescriptive specs).
- **(b) Auto-fire `/wiki-bootstrap` (rejected):** looser coupling to the approach — findings would not land where the design decision is made.
- **Research-before-planning as a hard gate (rejected):** the user chose (c) — a bounded step inside planning, not a blocking pre-gate.

## Consequences

- Standard-ceremony plans on uncovered topics incur a short, bounded research pass; well-covered topics spend zero external calls.
- Persisted findings carry provenance so later phases and audits can distinguish researched fact from human-curated knowledge and re-verify it.
- The companion file pattern keeps SKILL.md under the 350-line cap (existing assertion at `tests/test_templates.sh:262-263`).

## Source

Phase 58 plan. Consumes the Domain Research Questions section shipped by Phase 55. Builds on [[decision:dev-plan-scope-extraction]] (companion pattern), the `wiki-add`/`wiki-bootstrap` capture conventions, and the fail-open hook pattern.
