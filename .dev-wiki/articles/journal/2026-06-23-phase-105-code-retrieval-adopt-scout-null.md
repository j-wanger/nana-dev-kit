---
title: "Phase 105 complete — Code-Retrieval Adopt-Scout: a planning-stage informative null (do NOT adopt)"
aliases: []
category: journal
tags: [phase-105, adopt-scout, code-kg, tool-reach, amplifier-null, post-cutoff, heu-012, planning-stage-null]
parents: [phase-105-code-retrieval-adopt-scout]
created: 2026-06-23
updated: 2026-06-23
source: debrief
---

# Phase 105 complete — Code-Retrieval Adopt-Scout: a planning-stage informative null

## What Happened

The Ph104 NEXT option (a) adopt-scout, maintainer-aimed (over my Category-1 skill-file-scanner rec) at
**Category 2 — code-knowledge-graph / codebase-retrieval as MCP**. The phase **resolved entirely at the
planning boundary**: no implementation tasks, no measurement run. Three sequential `Workflow` fan-outs did the
work, and each one pushed the same direction — the answer is a predicted null prior art already establishes.

- **Workflow 1 (grounding sweep, 6 agents):** confirmed the gap is real (the kit indexes prose only — verified
  against `wiki-index`/`memory_server`/`dev-scan` source), but the two adversarial steelmen (ADOPT vs
  NOT-ADOPT) CONVERGED on "fund a screen, not the adoption." My initial "already-covered" prior was a guess;
  this made it the hypothesis under test.
- **Workflow 2 (code-KG-screen pre-mortem, 3 lenses):** killed the screen design. The pre-built index is an
  **answer-cache** for the exact transitive-closure relations it scores (PASS baked in); the positive control
  is **non-constructible** (a determined OFF agent's 0.13s stdlib-`ast` BFS recovers callers on the 26K-LOC
  repo); the syntactic candidate code-KGs are **informationally dominated** by the `mypy` already installed in
  the substrate. Maintainer reframed to "are agents under-using already-present type-aware tooling?" (tool-reach).
- **Workflow 3 (reframe-harden + make-or-break corpus probe, 3 agents):** the reframe is the **amplifier-null
  hypothesis class terminated 4× here** (Ph59/70/77/78). The fair Rung-1 existence-only test predicts
  DEGENERATE (naming the tool over-coaches = Ph78 explicit-goal / Ph80 leak). The empirical corpus probe found
  the dispatch-hard corpus only **PARTIAL** (~1–2 cross-module cases; the AML-central registry/Protocol
  dispatch is both mypy-unresolvable AND prose-leaked in `_ARCHITECTURE.md`).

Maintainer banked the null (do NOT adopt). The rigorous direction-setting WAS the measurement — no L-run spent.

## Decisions Made
- [[code-retrieval-adopt-scout|Phase 105: Code-Retrieval Adopt-Scout — planning-stage null]] -- do NOT adopt;
  extends the amplifier-null family to code-structure / tool-reach; bounds the Ph59 post-cutoff carve-out.

## Problems Solved
- **A rigged screen, caught before the run.** The code-KG-vs-grep design would have PASSED trivially (index =
  answer-cache). The pre-mortem caught it; verification-first / burden-of-proof saved an L-effort run on a
  pre-determined result.
- **Subagent claims promoted to evidence only after orchestrator re-run** ([[HEU-012]]): the load-bearing facts
  (26K first-party LOC not 1.79M, `mypy` installed, `_ARCHITECTURE.md` leaks dependency rows, 12 `to_dict`
  defs / 21 sites) were each re-verified by a command the orchestrator ran itself before acting on them.

## Open Questions
- Does the null generalize past this substrate? A **much larger or genuinely dynamic** codebase (structure
  truly not in-context, static tooling can't resolve) could still host a real signal — the only door left open.

## Artifacts Changed
- `.dev-wiki/articles/decisions/code-retrieval-adopt-scout.md` (new — the verdict, high confidence)
- `.dev-wiki/articles/phases/phase-105-code-retrieval-adopt-scout.md` (new — status completed)
- `.claude/rules/working-knowledge.md` (new Ph105 entry + Ph59 post-cutoff caveat amended — option (c))
- `.claude/rules/active-phase.md` (rewritten for Phase 105 completed-null)
- `.dev-wiki/{_CURRENT_STATE,assumption-ledger,index,log}.md` (close-out bookkeeping; ledger Phase-105 schema-valid)
- `companion/research/code-retrieval-scout/evidence.md` (gitignored — the 3-workflow evidence record)

## Related
- [[phase-105-code-retrieval-adopt-scout|Phase 105: Code-Retrieval Adopt-Scout]] -- parent phase
- [[frontier-landscape-survey|Phase 104]] -- the survey that surfaced the code-KG category (NEXT option (a))

## Retro (dims 1-3, Phase-105 = 105th completed, %5 trigger)
- **Reversals:** I reversed my own "Category 2 is already-covered" prior (a guess) under evidence — the right
  move; and the maintainer reframed the phase twice (code-KG → tool-reach → bank-null) as each instrument was
  found non-viable. The reframes were the process working, not churn.
- **Corrections:** the pre-mortem corrected a rigged screen design before any run; the harden probe corrected
  the reframe (predicted DEGENERATE, thin corpus). No course-correction was needed downstream because none was
  shipped.
- **Blockers:** none. The phase closed cleanly with zero kit change.

## Soft Observations / Phase N+1 Candidates
- The rigorous direction-setting can BE the measurement: 3 adversarial workflows resolved an adopt-scout to a
  null before any run. | Phase N+1: reuse the "adversarial pre-mortem before freezing any measurement
  instrument" pattern as a standing step for measurement phases. | [[code-retrieval-adopt-scout]]
- The surviving untested avenue is unchanged: genuinely PROPRIETARY/POST-CUTOFF correctness derivable from no
  fair corpus (Ph104 lit it up for public repos). | Phase N+1 (a): a screen there — the one regime where
  retrieval/harness headroom plausibly lives. | [[frontier-landscape-survey]]
