# enforce-memory demand-evidence snapshot (Phase 88 T1)

Re-derivation: `bash eval/trim-round/evidence/filter-enforcement-log.sh .dev-wiki/enforcement.log enforce-memory`
(filter validated controls-first by `test-provenance-filter.sh` — seeded fixture with known composition).
Extracted: 2026-06-11T11:31:48Z at repo base 7e9c56f. The log keeps growing as sessions run —
THIS snapshot pins the counts the filter produced at extraction; the spec's planning-time "~69"
and the state-loader's "385" are earlier drift points of the same live log, superseded here.

## Provenance-filtered counts (hook = enforce-memory only)

| cell | value |
|---|---|
| total | 416 |
| allow | 404 |
| block | 12 |
| unattributed (no phase field) | 0 |
| by phase | 82: 62 · 83: 52 · 84: 47 · 85: 87 · 86: 93 · 87: 71 · 88: 4 |
| allow reasons | allowlisted-path 289 · memory-consulted 92 · markdown 23 |

All records carry the phase field (enforce-memory was restored Phase 83, after schema_version 1
introduced it) — provenance attribution is complete, no timestamp cross-reference needed.
CONTAMINATION FLAGS: the phase-88 records (4, incl. 1 block) are THIS planning/T1 session's own
work — orchestrator activity, not consuming-work demand; the phase-82 six-block cluster
(18:59:15–19:00:29Z, 10–60s spacing) falls in Phase 82's audit window where piped audit events
wrote real records (the known run-provenance hazard, Blockers filing Phase-82 misc #3) —
treated as suspect, and the conclusion below survives discarding phase 82 entirely.

## Block→follow-through reconstruction (DRQ-1)

Method: each block paired with (a) the NEXT enforce-memory decision in the log, (b) actual
`mcp__memory__memory_search` invocation timestamps extracted from the 82 session transcripts in
`~/.claude/projects/-Users-jwang-nana-dev-kit/` (73 contain memory_search). The hook's demanded
action is memory_search + marker touch, so a search INSIDE the block→allow window = real
follow-through; an allow/memory-consulted WITHOUT a search in the window = marker-touch-only
(ritual compliance — demonstrated reproducible live this session). memory.db write-time pairing
was not needed: search, not store, is the demanded action.

| block episode (ts, phase) | next decision | search in window? | classification |
|---|---|---|---|
| 2026-06-09 18:59:15–19:00:29 ×6 (82) | block (repeats) | — | one episode: 6 rapid re-attempts without compliance (audit-window suspect) |
| 2026-06-09 19:17:56 (82) | allow/memory-consulted +35s | 19:18:12 YES | REAL follow-through (search → marker) |
| 2026-06-10 13:13:12 (85) | allow/memory-consulted +28s | none | marker-touch-only |
| 2026-06-10 21:54:40 (86) | allow/memory-consulted +42s | 21:54:48 YES | REAL follow-through |
| 2026-06-10 22:34:15 (86) | allow/memory-consulted +21s | 22:34:21 YES | REAL follow-through |
| 2026-06-11 00:20:22 (87) | allow/memory-consulted +25s | none | marker-touch-only |
| 2026-06-11 11:29:29 (88) | allow/memory-consulted +29s | none (search 04:13 pre-resume) | marker-touch-only — RESUME ARTIFACT: session-resume clears the marker but the session had already searched; partly hook-design, not pure ritual |

## Verdict-relevant summary (A3 outcome: reconstruction FEASIBLE — not undecidable)

- The reconstruction the gate down-scoped to attempt+fallback SUCCEEDED: provenance is complete,
  follow-through is classifiable per episode. `undecidable-on-this-evidence` is NOT needed.
- Demand signal is MIXED, now quantified: of 7 block episodes, 3 produced a verified real
  memory_search inside the window, 3 produced marker-touch-only compliance (1 of those a
  resume-artifact), 1 (suspect cluster) produced delayed compliance ending in a real search.
- Friction-vs-demand reading: the hook converts roughly half its bites into real memory
  consultation; the other half into ritual marker touches. 92 of 404 allows were
  memory-consulted (marker present at Write/Edit time) — the marker state does real gating work.
- LIMIT: all of this measures the ORCHESTRATOR'S compliance in kit-development sessions; it says
  nothing about consuming-project demand (edge-screener: zero voluntary use — but gate A4 ruled
  that question out of this phase's scope). The verdict row for enforce-memory weighs THIS
  table only.
