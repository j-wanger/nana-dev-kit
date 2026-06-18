---
title: "Strategic Inflection Review — Product Frame + Re-measure-then-Shrink"
aliases: [strategic-inflection-review, inflection-point-review, phase-92-review]
category: decisions
tags: [strategy, objectives, amplifier-program, deterministic-vs-llm, roadmap, subtraction]
parents: [phase-92-strategic-inflection-review]
created: 2026-06-18
updated: 2026-06-18
source: plan
confidence: high
---

## Context

At ~91 phases the maintainer called an inflection point: re-examine the kit's strengths/limitations,
revisit *why* nana-dev-kit is built, and define what belongs deterministic vs LLM in an agentic harness.
The review was grounded in the kit's OWN measured evidence — a 7-agent workflow (5 parallel surveys over
skills / hooks / memory / the eval program / founding objectives → a synthesis → an adversarial critique),
not recollection. The critique was the quality gate and it earned its keep: it corrected five overclaims
in the synthesis before any direction was gated on them.

The load-bearing finding is existential and is the kit's own: the amplifier program measured the harness's
core re-presentation function and got a NULL — **4 clean pre-registered, controls-validated, NO-LLM-scored
nulls** (Ph70 single-decision recall DEGENERATE; Ph71 cross-compaction retention; Ph77 cross-session
residual 0/14; Ph78 tooling-correctness DEGENERATE) **+ 1 instrument-dead** (Ph80 leaked — NOT a clean
null), plus two runtime-retrieval A/B nulls (Ph61 wiki-search -0.67, memory_search 0.00). The honest count
is 4+1, not "five independent nulls," and untested regimes remain (cumulative multi-compaction, true
cross-session under token pressure, non-AML domains).

## Decision

Two maintainer positions at the direction (assumption) gate, 2026-06-18 (ledger Phase-92 block; all_accept:false):

1. **FRAME = product for consumers.** The maintainer REJECTED the evidence-led "primarily a single-maintainer
   research instrument" read. Consequence: the last ~10 days' inward measurement/hygiene growth (eval/ at 28M
   / 1,583 files vs templates/ at 916K; the dense Jun 9–13 cluster) is **mission-creep to correct**, and the
   under-served consumer surface (the unbuilt install.sh re-sync, consumer memory firing fixed only at Ph91,
   scaffold currency) is the **primary** work.

2. **DIRECTION = re-measure-once-then-shrink** (NOT the synthesis's "refocus"). The synthesis's recommended
   option smuggled in two *unmeasured* build commitments under the banner of "following the null" — a
   proprietary/post-cutoff retrieval R&D track with ZERO lift evidence (the positive-unknowable controls
   prove the instrument can DETECT a bare-model failure, never that the harness RECOVERS the answer), and a
   linter-rewrite on a never-observed defect. Burden-of-proof-on-the-feature bars both. The honest reading of
   the kit's own nulls is wind-down, executed with the Ph88 discipline (reversible trim-trials + revert
   triggers). The one guardrail: the Ph89 memory demand-zero was measured on memory **broken until Ph91**, so
   it is a *couldn't-fire* zero ([[HEU-012]]) and you don't cut on it — ONE clean re-measure on re-synced,
   working memory must precede any memory-layer cut.

### Corrections the critique forced (recorded so they don't propagate)

- The Ph87 "deterministic validity sweep caught a golden-master corruption both blinded LLM reviewers missed"
  is **a confound, not a det-over-neural proof** — the corrupted file was a *binary excluded from the
  reviewers' diff view*. The keep-case for the deterministic spine stands on the 4 silent breakages caught
  (8–33 phases dormant), NOT on Ph87.
- "Five independent nulls" double-counts Ph80 (instrument-dead). Honest: 4 clean + 1 leaked.
- enforce-memory field evidence is ~4 real follow-throughs : 2 ritual-touches (one a resume artifact), not
  lopsidedly ritual.
- The three "linter-skills" were size-inflated ~40% (wiki-health 218 lines not 300; dev-check 147) and their
  "LLM mis-reads frontmatter" failure mode is hypothesized, never observed → rewrite is **deferred**.
- "Every measured positive lives in the deterministic spine" is partly circular — the program only ever
  GATED on deterministic checks (Ph63), so LLM interventions were definitionally excluded from producing a
  "measured positive."

## Consequences

Re-sequenced roadmap (this review's output; supersedes the queued ordering):

- **Phase 93 — install.sh idempotent update / consuming-project re-sync mode** (the unbuilt original Phase-91
  scope). Propagates the Ph91 memory fix + the assumption gate + post-trim surfaces into signal-watch (no kit
  hooks today) and the 4 staged consumers. Consumer-serving *and* the prerequisite for the re-measure.
- **Phase 94 — clean consumer memory re-measure** on a re-synced consumer with working memory (lightweight
  dogfood, run in a consuming project per the in-kit leak constraint, NOT a new measurement-apparatus phase).
- **Phase 95 — memory-layer shrink**: make the Ph88 trim-trials permanent if their windows close clean, prune
  the re-presentation layer per the re-measure, redesign-or-retire enforce-memory. **Supersedes**
  `specs/phase-92-memory-layer-prune.md`, which assumed a cut without the re-measure precondition.

Frozen/deferred: no implementation code in Phase 92 (decisions/docs only); no memory-layer cut until Phase 94
lands; the proprietary-retrieval R&D track is NOT chartered (would require a pre-registered screen first, and
it is not the product-frame priority); the linter-determinization stays deferred. The det-vs-LLM boundary is
captured separately as [[deterministic-vs-llm-boundary]] and adopted as a maintenance guideline. The Phases
90–93 window-events append obligation still stands through the Phase-93 trim-trial disposition.

Open tension to carry forward: the assumption gate (Ph91) is held up as the architecture to emulate, yet it
is itself a re-presentation/forcing feature whose measured lift is weak by Ph80. Resolution: keep it because
it is *cheap and checkable* (a Bash validator asserting the ledger row), not because it has proven lift — the
value generalized is the forcing-function *shape*, not the surfacing prose.
