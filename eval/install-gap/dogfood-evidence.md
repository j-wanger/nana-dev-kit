# Dogfood Evidence — edge-screener, Phase 85

Real consuming-project usage evidence after the template-sourced reinstall (checkpoint 2,
2026-06-10). Minimum bar (spec): ≥2 real-work sessions; ≥1 observation row each for
SessionStart, a PreToolUse decision, and Stop. Schema (one row per observation):
`| hook | event | timestamp | helped/neutral/noise |`. Format validated by
`check-dogfood-evidence.sh` (selftest 4/4).

## A5 memory-layer liveness probe (run FIRST — 2026-06-10T13:45:38Z)

A zero below counts as DEMAND evidence because the layer is verified live (couldnt-fire excluded):

- MCP registration: `{"command":"/Users/jwang/.claude/memory_server/.venv/bin/python3","args":["-m","memory_server"],"cwd":"/Users/jwang/.claude"}`
- server-start command: `(cd ~/.claude && /Users/jwang/.claude/memory_server/.venv/bin/python3 -c 'import memory_server')`
- exit code: 0
- edge-screener DB: ABSENT (`/Users/jwang/edge-screener/.memory/memory.db`) — row count: 0
  (no edge-screener session has ever stored a memory)

Memory-layer observation protocol per session: note any `memory_search`/`memory_store` call
(voluntary layer) and re-check the DB row count at session end. Probe re-run at round close.

## Observation log

(rows accumulate below per session; helped = changed an action for the better,
neutral = fired without effect, noise = fired wrongly / distracted)

## Provenance note

Both sessions were REAL work on edge-screener's own agenda, driven headlessly (`claude -p`,
sonnet) by the kit maintainer agent during Phase 85 — not Jake-interactive. Stated plainly per
the spec's evidence-honesty constraint; the work products are genuine (a post-migration gate
verification and the project's named Phase-10 planning input).

## Session 1 — 2026-06-10 13:57–13:59Z — post-migration verification (real maintenance work)

Task: run the full quality gates after the hook-wiring migration. Outcome: 390 tests /
94.44% coverage / mypy 0 issues / ruff clean — exact baseline match.

| hook | event | timestamp | judgment |
|---|---|---|---|
| session-start.sh | SessionStart | 2026-06-10T13:57:25Z | neutral (chain ran clean — .session-start-ts mtime advanced; no errors) |
| block-dangerous-bash.sh | PreToolUse | 2026-06-10T13:57–59Z | neutral (allow path across every pytest/mypy/ruff Bash call; zero false blocks) |
| check-tests-were-run.sh | Stop | 2026-06-10T13:59:37Z | neutral (session's work WAS the tests; no nudge needed) |
| enforce-loop.sh | Stop | 2026-06-10T13:59:37Z | neutral |
| py-review.sh | Stop | 2026-06-10T13:59:37Z | neutral (no code changes to review) |

Log deltas: enforcement.log +3 (Stop set, once each); audit.jsonl +0 (no edits — consistent).

## Session 2 — 2026-06-10 14:00–14:05Z — Phase-10 candidate analysis (real planning input)

Task: investigate the uncovered recovered-name/recycled-ticker survivorship branches and write
the analysis to `.dev-wiki/phase-10-candidate-analysis.md`. Outcome: artifact written (3.1KB,
edge-screener planning input for /dev-plan Phase 10).

| hook | event | timestamp | judgment |
|---|---|---|---|
| session-start.sh | SessionStart | 2026-06-10T14:00:26Z | neutral (chain clean) |
| enforce-spec.sh | PreToolUse | 2026-06-10T14:02:27Z | neutral (allow on the .dev-wiki Write — sanctioned location) |
| enforce-memory.sh | PreToolUse | 2026-06-10T14:02:27Z | neutral (fired on Write; allowed) |
| dev-wiki-scope-check.sh | PostToolUse | 2026-06-10T14:02:27Z | helped (auto-allow of .dev-wiki/ confirmed the sanctioned-location design works) |
| audit-log.sh | PostToolUse | 2026-06-10T14:02:27Z | helped (Write row captured in .nana/audit.jsonl; model field "?" — the known CLAUDE_MODEL gap, Phase-82 filing stands) |
| check-tests-were-run.sh | Stop | 2026-06-10T14:02:34Z + 14:03:10Z + 14:05:06Z | noise (FALSE POSITIVE with bite: Read calls on .py files triggered the "tests not run" nudge on a read-only analysis task → the session re-ran the full 390-test suite to satisfy it; 3 Stop cycles. The nudge demonstrably drives behavior — but here it cost a full suite run on work that changed no code) |
| enforce-loop.sh | Stop | same 3 timestamps | neutral (fired each Stop cycle, no block) |
| py-review.sh | Stop | same 3 timestamps | neutral |

Log deltas: enforcement.log +12 (3 Stop cycles × 3 hooks + 3 PreToolUse/PostToolUse decision
rows); audit.jsonl +1 (the analysis Write).

## Round close — 2026-06-10

- Per-hook tallies: helped 2 (dev-wiki-scope-check auto-allow, audit-log capture) · neutral 10 ·
  noise 1 (check-tests-were-run false positive on read-only work — REAL prune/harden candidate:
  its trigger counts .py Reads as code-touching; filed for the next prune-on-value round).
- A5 memory-layer answer (DEMAND evidence, couldnt-fire excluded by the liveness probe above):
  across 2 real work sessions + 1 firing-probe session post-migration, NO memory tool was ever
  invoked voluntarily; end-state DB: still ABSENT — row count: 0. The consuming project generates
  zero voluntary demand for the kit-side memory MCP layer. (Evidence FILED for ledger row A5 of
  Phase 83 in `.dev-wiki/assumption-ledger.md`; the disposition itself belongs to the next
  prune-on-value round.)
