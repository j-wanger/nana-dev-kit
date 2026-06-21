---
title: "Phase 94 complete — Clean Consumer Memory Re-measure"
aliases: [2026-06-20-phase-94-consumer-memory-remeasure-complete]
category: journal
tags: [memory, demand-evidence, dogfood, verify-by-firing, transcript-forensics]
parents: [phase-94-consumer-memory-remeasure]
created: 2026-06-20
updated: 2026-06-20
source: debrief
duration: ~3-4h (post-compaction estimate — may undercount)
---

# Phase 94 complete — Clean Consumer Memory Re-measure

## What Happened
- Produced ONE clean, admissible RETROSPECTIVE re-measure of consuming-project memory-LAYER
  demand across a 3-consumer machinery gradient on the repaired (Ph91 PYTHONPATH) global memory
  MCP. EVIDENCE ONLY — Phase 94 took NO disposition (that is Phase 95's job). 3/3 tasks, 11/11
  exit criteria, `make test` ALL-PASS (no regression), git diff scope = `eval/` + `.dev-wiki/`
  + `specs/` + `.claude/rules/` only — ZERO kit code touched.
- **T1 verify-by-firing** (HARD admissibility gate): drove the MCP server exactly as Claude
  Code launches it (configured venv python, `-m memory_server`, `PYTHONPATH=~/.claude`) with
  cwd=a consumer; store→search round-trip persists+retrieves a row in the CONSUMER's
  `.memory/memory.db`. `VERDICT: FIRES`; the deliberately-broken-config control classified
  `COULDNT-FIRE` (instrument-dead self-check passed). The Ph89/Ph83 consumer zeros were
  couldn't-fire on broken memory — now admissible.
- **T2 retrospective 3-consumer tally** (JSON `tool_use` parse, never grep): `--selftest` +
  `--verify-ingest` + subagent-file capture all pass. Window pinned to repair-commit `318e9b6`.
- **T3 file evidence**: `eval/memory-remeasure/memory-demand-remeasure.md` (Ph89 schema,
  EVIDENCE-ONLY + NO-SUFFICIENCY caveat).
- Also resolved two deferred backlog items in tasks.md "Discovered" — install.sh re-sync
  (Phase 93) and memory re-measure (Phase 94) — both now `[x]`.
- **Live kit-side datapoint:** enforce-memory FIRED on the orchestrator this session (blocked a
  Write until a memory_search ran + the marker was touched) — directly relevant to the Phase-95
  enforce-memory redesign-or-retire question (the hook DOES create compliance; value-vs-ritual
  is the open question).

## Decisions Made
- [[consumer-memory-remeasure|Consumer Memory-Layer Re-measure (Phase 94)]] (high) — already
  on disk from planning; verified, not duplicated.

## Problems Solved
- **Review gate 7/10 revise — one HIGH FIXED inline:** the tally originally missed subagent
  transcripts (they live in separate `<session-uuid>/subagents/agent-*.jsonl` files, not inline
  `isSidechain` entries), dropping ~22 (casework) + ~52 (substrate) real admissible subagent
  memory calls and making the evidence file's "subagent calls... none exist" FALSE. Fixed: tally
  now reads `subagents/*.jsonl`, the selftest guards it with a real subagent fixture, evidence
  file corrected (side calls signal-watch 0/0, aml-casework 15/7, aml-substrate 27/25).
- 3 LOW also fixed inline: removed an "earning its keep" disposition lean from the evidence
  file; added a `machinery()`-reads-current-FS caveat; corrected the grep over-count ratio to
  ~18x. Load-bearing parts independently re-verified SOUND (the 0/20/44 persisted-DB-row
  gradient read directly from consumer DBs, the firing admissibility gate, contamination
  exclusion, cross-session read-back).

## Open Questions
- A2 sufficiency-for-cut routed to Phase 95 (ledger Phase-94 revisit-status open).
- Read-back measures cross-session retrieval-HAPPENING, not downstream action-CHANGE — a
  stronger Phase-95 measure would grade whether retrieved memories changed the action.
- Domain skew: 2 of 3 high-demand consumers are AML projects — a non-AML machinery consumer
  would strengthen generalization.

## Artifacts Changed
- `eval/memory-remeasure/verify-firing.sh` (T1 firing gate + broken-control)
- `eval/memory-remeasure/tally-demand.py` (T2 JSON tool_use tally + selftest + verify-ingest + subagent-file glob)
- `eval/memory-remeasure/fixtures/**` (selftest + subagent fixtures)
- `eval/memory-remeasure/memory-demand-remeasure.md` (T3 evidence file)
- `.dev-wiki/tasks.md` (T1/T2/T3 + 2 Discovered items → `[x]`)

## Related
- [[phase-94-consumer-memory-remeasure|Phase 94: Clean Consumer Memory Re-measure]] — parent phase

## Soft Observations / Phase N+1 Candidates
- The finding REVERSES Phase 95's premise: "memory-layer shrink" should be re-scoped to
  "reconcile spontaneous floor + coerced demand + cross-session read-back" — the coerced layer
  is in active value-bearing use in 2 of 3 live consumers; likely keep/refine, maintainer's
  call. | Evidence: `eval/memory-remeasure/memory-demand-remeasure.md`.
- enforce-memory fired ON the orchestrator THIS session — a live hook-prompted datapoint for the
  Phase-95 enforce-memory redesign-or-retire question. | Evidence: this journal "What Happened".
- Read-back measures retrieval-happening, not action-change — a stronger Phase-95 measure would
  grade action-change. | A non-AML consumer with the kit memory machinery would strengthen
  generalization beyond the two AML projects.
