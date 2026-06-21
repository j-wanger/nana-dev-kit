---
title: "Phase 94: Clean Consumer Memory Re-measure"
aliases: [phase-94-consumer-memory-remeasure, consumer-memory-remeasure-phase]
category: phases
tags: [memory, demand-evidence, dogfood]
parents: []
created: 2026-06-20
updated: 2026-06-20
source: plan
status: active
scope: ["eval/memory-remeasure/**", ".dev-wiki/_CURRENT_STATE.md"]
entry_criteria: "Phase 93 delivered (5f830dc); memory MCP repaired in consumer cwds (Phase 91); spec specs/phase-94-consumer-memory-remeasure.md nana:approved; direction gate closed (Phase-94 ledger)"
exit_criteria: "verify-by-firing admissibility pass (broken-config control = COULDN'T-FIRE); retrospective 3-class tally across the 3-consumer gradient with read-back + attempted-vs-satisfied; memory-demand.md evidence file with NO-SUFFICIENCY caveat"
---

# Phase 94: Clean Consumer Memory Re-measure

## Objective

Produce **one admissible retrospective re-measure** of consumer memory-layer demand across the
3-consumer machinery gradient (`signal-watch` no-rules/hooks ~ floor, `aml-casework` rules,
`aml-substrate` rules+hooks) on the **working** memory layer (repaired in Phase 91).
**EVIDENCE ONLY** — it feeds Phase 95, which disposes.

## Scope

Files and modules affected:
- `eval/memory-remeasure/*`
- `.dev-wiki/_CURRENT_STATE.md`

No kit code changes (`eval/` + `.dev-wiki/` + `specs/` only).

## Exit Criteria

- [ ] **Verify-by-firing admissibility** — `store -> search` round-trip persists+retrieves a
      row in the consumer's `.memory/memory.db`; the broken-config control classifies
      **COULDN'T-FIRE** (instrument-dead self-check).
- [ ] **Retrospective tally** — JSON `tool_use` parse (never grep), 3-class taxonomy
      (spontaneous / rules-instructed / hook-prompted) across the 3 consumers, with
      cross-session read-back + attempted-vs-satisfied, post-repair window pinned to a SHA,
      positive ingest control.
- [ ] **Evidence file** — `memory-demand.md` reusing the Phase-89 schema, with an explicit
      **NO-SUFFICIENCY caveat** (a spontaneous floor cannot license cutting a coerced layer;
      Phase 95 reconciles).

## Notes

EVIDENCE ONLY — **Phase 95 disposes** (keep / shrink / cut). This phase mints no disposition.

The **verify-by-firing admissibility gate** (T1) is load-bearing: a couldn't-fire layer
yields inadmissible zeros ([[HEU-012]]), which is exactly the Phase-89 trap this re-measure
exists to clear. Must run in consuming projects — never in-kit (working-knowledge leaks the
answer, Phase 80).

Decision: [[consumer-memory-remeasure]] (high). Gated by [[strategic-inflection-review]]
("re-measure-once-then-shrink"). Memory reaches consumers via [[memory-mcp-consumer-e2e-fix]]
(Phase 91), independent of the deferred Phase-93 live re-sync.
