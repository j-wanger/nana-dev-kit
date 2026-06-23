---
title: "Phase 105: Code-Retrieval Adopt-Scout (code-KG / tool-reach) — planning-stage null"
aliases: [phase-105, code-retrieval-adopt-scout, code-kg-adopt-scout]
category: phases
tags: [adopt-scout, code-kg, retrieval, amplifier-null, tool-reach, companion-research, heu-012]
parents: [code-retrieval-adopt-scout]
created: 2026-06-23
updated: 2026-06-23
source: plan
status: completed
scope: ["companion/research/code-retrieval-scout/**", ".dev-wiki/**", ".claude/rules/active-phase.md", ".claude/rules/working-knowledge.md"]
entry_criteria: "Ph104 delivered + accepted (2026-06-22); maintainer chose NEXT option (a) the adopt-scout, aimed at Category 2 (code-KG / codebase-retrieval as MCP)."
exit_criteria: "Adopt/no-adopt verdict reached; decision article + working-knowledge amendment (incl. the Ph59 post-cutoff boundary, option (c)) written; ZERO kit code change; make test PASS + eval 50/50 + drift 0; git ls-files companion/ empty."
---

# Phase 105: Code-Retrieval Adopt-Scout (code-KG / tool-reach) — planning-stage null

## Objective

Evaluate whether the kit should adopt a **code-knowledge-graph / codebase-retrieval** capability (Ph104
Category 2, surfaced at 53–66k stars) — the adopt-scout follow-on the maintainer chose. Answer the adoption
question with evidence, not plausibility.

## Outcome — RESOLVED AT PLANNING (informative null)

This phase did **not** reach an implementation/measurement run: three controls-first adversarial workflows
converged on a predicted null that prior art already establishes, so the maintainer banked the null at the
planning boundary (the rigorous direction-setting *was* the measurement — burden-of-proof-on-the-feature).

**Verdict: do NOT adopt.** Two framings, each killed by adversarial review:
1. *Vendor a code-KG-MCP, screened on a consuming repo* — non-viable: the index is an answer-cache for the
   scored relations (PASS baked in); the positive control is non-constructible (OFF's 0.13s stdlib-`ast` BFS
   on the 26K-LOC first-party repo); the syntactic candidates are dominated by the substrate's installed
   `mypy` on the only hard cases (method dispatch).
2. *(Reframe) surface already-present type-aware tooling ("are agents under-using mypy?")* — the fair Rung-1
   existence-only test predicts DEGENERATE; this is the amplifier-null hypothesis class, terminated 4× here
   (Ph59/70/77/78); the dispatch-hard corpus is only PARTIAL (~1–2 cross-module cases; registry dispatch both
   mypy-unresolvable and prose-leaked).

**Generalizes:** harness headroom does not live in re-presenting **code structure / tool-choice** the strong
model recovers from the repo already in its context. **Ph59 boundary (option (c)):** local code-structure
retrieval is NOT in the post-cutoff carve-out Ph104 demonstrated (recoverable in-context + dominated by
installed type-aware tooling); the carve-out is for facts derivable from *no fair corpus*.

## Scope

- `companion/research/code-retrieval-scout/evidence.md` — gitignored 3-workflow evidence record (apparatus
  private, Ph97/104 precedent)
- `.dev-wiki/**` — planning + close-out bookkeeping; decision article [[code-retrieval-adopt-scout]]
- `.claude/rules/{active-phase,working-knowledge}.md` — compaction anchor + the amplifier-null extension and
  Ph59 boundary amendment

OUT: any kit code/config change; an actual adoption; a measurement run (pre-empted by the planning-stage null).

## Direction gate (the multi-round reframe)

Resolved across four AskUserQuestion rounds (ledger Phase-105): Category-2 over Category-1 → measurement-screen
over desk-eval/spike (null-is-valid accepted, substrate aml-substrate) → reframe to tool-reach after the
code-KG screen was found rigged → bank the null after the harden probe showed the reframe is the 4×-terminated
amplifier-null class with a thin corpus. The pre-mortems caught each non-viable instrument before any L-run.

## Health

SHIPS NOTHING — `make test` PASS, `make eval` 50/50, drift 0, `git ls-files companion/` empty. Decision
[[code-retrieval-adopt-scout]] (high). Controls discipline [[HEU-012]] / [[can't-measure-clean-context-in-kit]].
