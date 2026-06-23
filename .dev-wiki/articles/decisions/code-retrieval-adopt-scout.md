---
title: "Phase 105: Code-Retrieval Adopt-Scout — Planning-Stage Informative Null"
aliases: [code-retrieval-adopt-scout, code-kg-adopt-scout, tool-reach-screen]
category: decisions
tags: [adopt-scout, code-kg, retrieval, amplifier-null, tool-reach, post-cutoff, companion-research, heu-012]
parents: [phase-105-code-retrieval-adopt-scout]
created: 2026-06-23
updated: 2026-06-23
source: plan
confidence: high
---

## Context

Ph104 [[frontier-landscape-survey]] left three maintainer's-call follow-ons. The maintainer chose **(a) the
adopt-scout**, aimed (over my Category-1 recommendation) at **Category 2 — code-knowledge-graph / codebase-
retrieval served as an MCP** (codegraph, codebase-memory-mcp, claude-context …, surfaced at 53–66k stars). The
question: should the kit adopt a code-KG capability — it rhymes with the kit's retrieval-over-parametric bet.

This phase **resolved during planning**: three controls-first adversarial workflows (grounding sweep →
code-KG-screen pre-mortem → reframe-harden + make-or-break corpus probe) converged on an informative null
*before* any measurement run. The rigorous direction-setting was the measurement. Full evidence in the
gitignored `companion/research/code-retrieval-scout/evidence.md` (Ph97/104 apparatus-private precedent).

## Decision

**Do NOT adopt a code-KG / code-structure-retrieval capability (in any of the framings explored).** Bank the
informative null. No kit change ships.

The investigation traversed two framings, each killed by adversarial review:

1. **Vendor/adopt a code-KG-MCP, screened on a consuming repo.** A code-KG-vs-grep headroom screen on
   aml-substrate is **structurally non-viable**: the ON arm's pre-built index is an *answer-cache* for exactly
   the transitive-closure relations it scores (PASS baked into the apparatus); the positive control is
   **non-constructible** (a determined OFF agent's stdlib-`ast` BFS recovers transitive callers in 0.13s on the
   26K-LOC first-party repo); and the candidate code-KGs are **syntactic** — *informationally dominated* by the
   `mypy` already installed in the substrate's `.venv` (type-aware) on the only hard cases (method dispatch).

2. **(Reframe) surface already-present type-aware tooling — "are agents under-using mypy/pyright?"** A fair
   test is a Rung-1 *existence-only* affordance (naming the tool + condemning grep over-coaches = the Ph78
   explicit-goal / Ph80 leak failure mode). Under that fair test prior art predicts **DEGENERATE**: this is the
   amplifier-null hypothesis class (harness re-presenting recoverable reasoning), which has **terminated 4× in
   this project** (Ph59 CUT, Ph70/77/78 null). The make-or-break corpus probe found the dispatch-hard corpus is
   only **PARTIAL** (~1–2 genuine cross-module cases; most collisions resolve by reading 5 lines locally; the
   AML-central registry dispatch is both mypy-unresolvable *and* prose-leaked in `_ARCHITECTURE.md`).

**Generalized finding (extends the amplifier-null family to code-structure / tool-reach):** harness headroom
does not live in re-presenting **code structure or tool-choice the strong model recovers from the repo it
already has in context**. A local typed repo's structure is recoverable in-context (a sub-second AST walk) and
dominated by already-installed type-aware tooling — it is NOT the surviving untested avenue (genuinely
proprietary / post-cutoff correctness derivable from no fair corpus).

## Ph59 post-cutoff boundary (the (c) deliverable)

Ph104 demonstrated Ph59's carved-out exception is real **for public, post-cutoff repos at scale** (the trending
survey paid). Phase 105 **bounds** it: **local code-structure retrieval is NOT in the carve-out** — the model
holds enough to re-derive a consumer repo's structure in-context, and type-aware tooling already present
dominates a vendored syntactic index. Retrieval pays on facts derivable from *no fair corpus*, not on a typed
codebase sitting in the working tree. The Ph59 working-knowledge caveat is amended accordingly.

## Alternatives considered

- **Run the hardened Rung-1 3-arm screen anyway** (measurement over prediction) — declined; thin corpus,
  L-effort, predicted DEGENERATE, and the burden-of-proof discipline says don't spend on a predicted null.
- **Switch to a large substrate** (where a code-KG's token-reduction value prop lives — repos that don't fit in
  context) — declined; not a "consuming project," different regime than the maintainer's domain.
- **Adopt directly / spike a vendor** — declined; reproduces the Ph59 shipped-then-cut class on an unscreened,
  footprint-heavy, capability-overlapping feature.
- The original Category-1 (skill-file security scanner) was not pursued (maintainer chose Category 2).

## Consequences

Ships nothing; the kit's prose-only retrieval stack stands. The honest result is the value of the controls:
three workflows caught a rigged screen, an inverted comparison, and a 4×-terminated hypothesis class before any
L-run — the burden-of-proof / measure-before-optimize discipline working at the planning boundary. The
surviving frontier for harness/retrieval value remains the Ph104-style **proprietary / post-cutoff** regime,
not local code structure. Any future revisit needs a substrate where structure is genuinely un-re-derivable
in-context (large, or genuinely dynamic past static reach) AND a fair existence-only affordance with a
grep-fine harm arm. Evidence: `companion/research/code-retrieval-scout/evidence.md`; controls discipline
[[HEU-012]] / [[can't-measure-clean-context-in-kit]].
