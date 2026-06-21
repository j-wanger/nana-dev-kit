# Consumer Memory-Layer Demand — Clean Re-measure (Phase 94)

**EVIDENCE ONLY — this file takes NO keep/shrink/cut disposition. Disposition belongs to Phase 95.**

Re-measure of consuming-project memory-LAYER demand on WORKING memory, replacing the Phase-89
demand-zero (which was COULDN'T-FIRE — memory was broken in consumer cwds until the Ph91 fix, so
inadmissible per [[HEU-012]]). Reuses the Phase-89 `eval/dogfood-round/evidence/memory-demand.md`
schema. Substrate = three live, measurement-blind consumers (maintainer-fixed n=3 at the direction
gate, expanded from n=1).

## Admissibility (the gate that makes a zero mean "no demand", not "couldn't fire")

- **repair-commit `318e9b6`** (Phase 91, 2026-06-14 14:45:16 -0400 = `2026-06-14T18:45:16Z`) — the
  `PYTHONPATH=~/.claude` env on the global MCP registration that makes `-m memory_server` resolve in a
  consumer cwd. The admissible window = sessions whose FIRST entry post-dates this commit (SHA-primary;
  pre-repair sessions ran against the broken layer and are excluded).
- **Verify-by-firing: `VERDICT: FIRES`** (`eval/memory-remeasure/verify-firing.sh`). The memory MCP
  server, launched EXACTLY as Claude Code launches it (its configured venv python, `-m memory_server`,
  `env.PYTHONPATH`) with cwd set to a fresh consumer dir, completed a store→search round-trip and a row
  physically landed in `<consumer-cwd>/.memory/memory.db` (the CWD-relative path — NOT `~/.claude/.memory/`,
  the exact Ph91 failure). The controls-first `--broken-control` run (PYTHONPATH dropped) reproduced the
  Ph91 break and classified `COULDN'T-FIRE`, so the firing detector is real, not a rubber stamp.
- Corroboration: two consumer DBs already hold real persisted rows (aml-casework 20, aml-substrate 44).

## The natural experiment — kit-memory-machinery gradient (all on working memory, blind)

| consumer | machinery | adm. sess | searches | stores | satisfied srch | cross-session read-back | sidechain (s/st) | persisted DB rows |
|---|---|---|---|---|---|---|---|---|
| signal-watch | **none** (no nana-soul memory rules, no enforce-memory hook) | 16 | 1 | 0 | 0 | 0 | 0/0 | 0 |
| aml-casework | **rules** (nana-soul session-start search + store-decisions, no hook) | 15 | 10 | 17 | 10 | 10 | 15/7 | 20 |
| aml-substrate | **rules + hooks** (rules + enforce-memory PreToolUse) | 21 | 28 | 37 | 26 | 25 | 27/25 | 44 |

Counts are REAL `type==assistant` `tool_use` blocks only (the deferred-tool catalog in
`type==attachment`/`system` entries — present in ~15/67 signal-watch sessions — is excluded; a naive
grep over-counts several-fold, e.g. ~18× for signal-watch [18 line-hits vs 1 real call]).
**Subagent calls** live in separate `<session>/subagents/agent-*.jsonl` files; being orchestrator-driven
(not organic main-agent demand) they are counted SEPARATELY in the `side(s/st)` column, never folded into
the demand columns — signal-watch 0/0, aml-casework 15/7, aml-substrate 27/25 (across 22 / 32 / 67
admissible subagent files). They are additional COERCED-context use that tracks the same gradient:
signal-watch's subagents make ZERO memory calls (no machinery, no demand even there), while the
machinery-equipped consumers' subagents also exercise the layer. Reproduce:
`python3 eval/memory-remeasure/tally-demand.py` (+ `--selftest`, `--verify-ingest`).

## What the numbers say (findings — not dispositions)

1. **Spontaneous floor ≈ 0, now ADMISSIBLY.** signal-watch — a full dev-wiki consumer on the working
   global memory layer but with NO kit memory machinery — made 1 search (empty) and 0 stores across 16
   admissible sessions. Genuine spontaneous demand for the memory layer, when it is available but
   un-announced and un-coerced, is ≈ zero. (This replicates the Ph89 direction, but admissibly: T1 proves
   the layer fires; the zero is no-use, not couldn't-fire.)
2. **Coerced/announced demand is substantial — and VALUE-BEARING, not ritual.** The two consumers with
   the kit's memory machinery show real, sustained use (aml-casework 10 searches / 17 stores / 20 rows;
   aml-substrate 28 / 37 / 44 rows). The ritual-vs-value discriminator is **cross-session read-back**:
   nearly every search returns a memory STORED IN AN EARLIER SESSION (aml-casework 10/10; aml-substrate
   25/28). The layer is doing exactly its design job — serving cross-session continuity in real AML work.
   Satisfied-search rates are high (10/10; 26/28), so these are not empty ritual searches.
3. **Demand tracks the machinery level** (none → rules → rules+hooks ⇒ 0 → 20 → 44 persisted rows;
   0 → 10 → 25 cross-session read-backs). The kit's rules+hooks are what CREATE the value-bearing use; the
   value is not intrinsic to having the layer available (signal-watch had it available and used it ~never).
4. This **reverses the roadmap's "consumer demand is zero" prior** (the [[strategic-inflection-review]]
   lean rested on the Ph89 couldn't-fire zero). On working memory, the coerced layer — the actual Phase-95
   cut target — is in active, cross-session-value-bearing use in 2 of 3 live consumers.

## Admissibility caveats (read before using this for any decision)

- **The spontaneous floor measures demand-when-UNANNOUNCED** (signal-watch has no rules/hooks and the MCP
  tools are deferred-loaded — the agent must `ToolSearch` to discover memory). It is the floor, NOT the
  coerced demand the kit's machinery is designed to create. The coerced demand IS measured here (the two
  AML consumers) — it is the actual cut target.
- **n=3 is FORCED, not chosen.** edge-screener (the Ph89 substrate) and edge-analyst/ai-game/fate are
  dormant (no post-repair sessions; edge-screener last active ~2026-06-11), so they yield no admissible
  window. The three live consumers are the available set.
- **Skew:** the two high-demand consumers are AML-domain projects (the maintainer's own work); signal-watch
  is an agent project. Domain/task-mix is a confound the gradient cannot fully separate from the machinery.
- **Read-back here = a search returning a memory created before the session's first entry** (deterministic
  from the tool_result's `created_at`). It establishes cross-session retrieval is happening; it does NOT
  grade whether each retrieved memory changed the downstream action — "value-bearing" rests on
  retrieval-happening, not on measured action-change. A stronger Phase-95 measure would grade action-change.
- **Machinery level is read from CURRENT filesystem wiring** (presence of nana-soul memory rules +
  enforce-memory hook) and applied to the whole admissible window; wiring is assumed stable across the
  post-repair window (no install/uninstall observed). Per-session session-time wiring was not separately
  reconstructed.

## NO-SUFFICIENCY (the boundary this round must not cross)

A spontaneous floor alone CANNOT license cutting a coerced layer — that would measure the wrong variable.
Phase 95 must reconcile ALL of three distinct quantities — the spontaneous floor (≈0), the coerced-demand
magnitude (substantial), and the cross-session read-back rate (high) — together; no single one of them
settles a keep/shrink/cut call. Phase 95 owns that call; this file characterizes no direction. The
maintainer's A2 don't-know (is the floor a sufficient basis for the cut?) is therefore routed to Phase 95,
not answered here. (Ledger Phase-94 A2, revisit-status: open.)

## Excluded heavier alternative (named for the record)

The apparatus path — install the kit memory layer FRESH into a clean consumer, then run NEW
measurement-blind sessions to isolate coerced demand de novo — was deliberately NOT taken (the
[[strategic-inflection-review]] mandated a lightweight retrospective dogfood, not a new measurement-apparatus
phase). The retrospective machinery-gradient over already-installed consumers measures the coerced demand
directly without it. If Phase 95 needs a controlled (rather than naturalistic) coerced measure, that path is
the follow-on.

## Pointers / disposition routing

- Resolves the open re-measure item ("Re-measure Phase-92 memory-layer demand on the now-WORKING layer") —
  see `.dev-wiki/_CURRENT_STATE.md` Blockers.
- Feeds Phase 95 (memory-layer shrink) and the [[deterministic-vs-llm-boundary]] enforce-memory
  redesign-or-retire question. Does NOT trigger the deferred Phase-93 live consumer re-sync.
- Decision: [[consumer-memory-remeasure]]. Spec: `specs/phase-94-consumer-memory-remeasure.md`.
