<!-- nana:approved 2026-07-01 (dev-plan Step 13 assumption gate closed, all_accept:false; approach reviewer 5/10 → revised all-in per maintainer + folded; three don't-knows resolved verify-first + safe-fallback) -->
# Spec: Phase 119 — Pi-UX felt-quality + ecosystem slice (Tier 1 + Tier 3)

## Objective
Improve nana's embedded-Pi GUI harness by incorporating the Tier 1 + Tier 3 items of the research finding [[pi-gui-setup-improvements]], on a properly de-risked **persistent-session foundation** — all governed by the existing un-bypassable host gate. The root discovery (state-load): nana's Pi session is currently PER-TURN EPHEMERAL (`createAgentSession` built + disposed inside every `sendPrompt`), so the headline felt-quality items (context/cost meter, compaction, runtime model/thinking switch) presuppose a session that lives across turns. This phase makes the session persistent (the 1 L), surfaces the felt-quality bits it unlocks, and wires the safe-default ecosystem items — with every session-mutating surface proven not to detach the gate.

## Context
A research spike (2026-07-01) grounded an improvement list for nana's own Pi embed from 4 Pi power-user walkthroughs + an Explore-verified map. The maintainer directed "incorporate Tier 1 + Tier 3." An approach reviewer (5/10) found the persistent-session foundation is a core-invariant refactor with real gate-danger; the maintainer chose to keep it ALL IN ONE PHASE with the reviewer's fixes folded. Pi SDK v0.80.2 confirmed-exports every capability named (getContextUsage/getSessionStats, compact/setAutoCompactionEnabled, setThinkingLevel/cycle, setModel/cycleModel, loadPromptTemplates/session.promptTemplates, loadSkills). Prior invariants: the host gate byte-unchanged + un-bypassable (Ph108/112); Ph115 restore is DISPLAY-ONLY (zero engine sends); the local $0 model is the DELIBERATE default (Ph108, KEPT); felt-quality ships on maintainer judgment at the delivery gate with mechanics-only vitest (Ph109-115).

## Scope
### In scope (app/ only)
- `app/src/engine/pi/pi-adapter.ts` — the persistent-session lifecycle refactor + the C1 denial-sink decouple + auto-compaction + the gate-survival verification + gate-survives-mutation tests.
- `app/src/host/{engine-host.ts,main.ts,build-adapter.ts}`, `app/src/context/assembly.ts` (AGENTS.md dedup + nana-conventions + host-orchestrated memory retrieval), `app/src/ui/{commands.ts,command-palette.tsx,chat-runtime.ts,conversation-store.ts}` + a bottom-bar meter, `app/src/control/spend.ts` (wire it), `app/src/engine/{types.ts,adapter.ts}` (additive-optional context-usage event).
- Mechanics tests (vitest) + `npm run build` + `cargo check`.

### Out of scope (this phase — deferred, from the gate resolutions + reviewer)
- **Model-facing memory MCP + a `memory_*` gate carve-out** (A3 don't-know) — memory stays HOST-ORCHESTRATED this phase.
- **`systemPromptOverride`** replacing/appending Pi's system prompt (A4 don't-know) — nana conventions go via AGENTS.md/context only this phase.
- **T2 items** (gate-as-hero legibility, file-change timeline, branching sessions) — a later phase.
- Any model-switch/thinking surface **whose mutation the T1 checkpoint shows detaches the gate** — DEFERRED.
- No shipped-kit / `install.sh` change.

## Approach
A persistent-session foundation (the 1 L) whose T1 opens with a **gate-survival verification checkpoint**, then the felt-quality surfaces + safe-default ecosystem wiring. Every session-mutating surface (setModel/compact/setThinkingLevel) ships with a "gate still intercepts after X" mechanics test; the gate's denial-sink is decoupled from the per-turn event queue (C1); compaction is folded into the foundation as the correctness dependency (a persistent `inMemory` session grows unbounded). Ph115 restore stays display-only + a "model context reset" marker (A2). Memory + the system prompt take their SAFE fallbacks this phase (host-orchestrated retrieval; AGENTS.md/context injection).

## Domain Research Questions (resolved at T1 verification, per the deferred don't-knows)
1. Does Pi v0.80.2 re-run the gate's `extensionFactories` on `setModel`/`compact` — i.e. does the gate survive a session mutation, or detach? (A1 — hard-blocks the mutating surfaces.)
2. Is Pi's default system prompt load-bearing for tool-calls on the weak local $0 model — can nana's conventions be appended, or must they stay in AGENTS.md/context only? (A4 — deferred; safe default built.)
3. Can the memory MCP be made model-facing with a tight, safe `memory_*` carve-out — or must it stay host-orchestrated? (A3 — deferred; safe default built.)

## Constraints (CRITICAL)
- **The host gate stays byte-unchanged + un-bypassable** across the persistent session AND across every session-mutating call — the load-bearing invariant. T1's verification checkpoint proves it; any mutation that detaches the gate DEFERS that surface; if the gate can't survive a persistent turn-2, the foundation STOPs + reports.
- **C1 — denial events must reach the current turn's stream.** Decouple the gate's denial-sink from the captured per-turn event queue (swap a per-turn queue reference); a DENIED tool on turn 2 must surface its `tool-denied` event on turn-2's stream (mechanics test).
- **Ph115 restore stays DISPLAY-ONLY** — a no-bypass test asserts restore issues ZERO engine sends; a restored thread the fresh engine doesn't remember carries a "model context reset" marker. Engine cross-turn memory is intra-run only (dies with the sidecar) — a named crash-isolation/restart residual; `new-conversation` = the recovery.
- **Compaction is a correctness dependency**, folded into the foundation — a persistent session must not exhaust context.
- **Safe fallbacks this phase:** memory host-orchestrated (no carve-out); nana conventions via AGENTS.md/context (no systemPromptOverride). De-dup ONLY the AGENTS.md double-injection — KEEP the `.claude/rules/*` injection.
- **Local $0 default KEPT** (Ph108) — the cost meter reads $0 on local (accepted); SpendCeiling is pause-after-exceed (post-hoc), fine at $0, matters on hosted.
- Mechanics-only vitest + `npm run build` + `cargo check`; native-runtime behavior on a maintainer LIVE-DRIVE.

## Success Vision
The maintainer runs nana's Pi, and: the session lives across turns with a live context%/cost meter + auto-compaction (no silent bloat); a denied tool still surfaces its denial on the current turn; switching model or thinking-level is a click AND the gate provably still intercepts after; a restored thread shows a "model context reset" marker; prompt-templates + skills appear as palette commands (each a gated turn); nana's conventions reach Pi via AGENTS.md/context; memory is retrieved host-side at turn start. The un-bypassable gate held through every mutation (proven by tests + the live-drive). No shipped-kit change.

## Exit Criteria (machine-checkable where possible)
- [ ] `cd app && npm test` green (the persistent-session mechanics: turn-2 denial visible; gate intercepts after compact; abort-then-continue reusable; gate-survives-setModel/setThinkingLevel; restore zero-engine-sends; AGENTS.md-dedup-keeps-rules; prompt-template gated-submit) AND `npm run build` (tsc+vite) AND `cargo check` green.
- [ ] T1 VERIFICATION CHECKPOINT report: does the gate survive setModel/compact (per Pi v0.80.2) — with the answer + which mutating surfaces (if any) were DEFERRED because their mutation detaches the gate.
- [ ] The additive context-usage event is an optional variant (no breaking change to the engine event union); the meter renders % + cost.
- [ ] Memory is host-orchestrated (no model-facing memory tool registered); Pi's system prompt untouched (no systemPromptOverride); AGENTS.md injected once with `.claude/rules/*` still injected.
- [ ] `.dev-wiki/` + `active-phase.md` + the delivery gate reflect the phase; a maintainer live-drive covers the three vitest-invisible checks (turn-2 denial visible, interrupt-then-continue, restart divergence).

## Checkpoints
- **T1 gate-survival VERIFICATION CHECKPOINT** (before any mutating surface): probe + assert the gate survives persistence + setModel/compact; STOP if it can't stay attached; DEFER any surface whose mutation detaches it. Resolves the A1 deferred don't-know.
- **Maintainer live-drive at the delivery gate** — the native-runtime behavior (persistence, denial-surfacing, interrupt-then-continue, restart divergence) is vitest-invisible.
- Any gate-survives-mutation test failing → STOP + report (the mutating surface is deferred, not shipped un-gated).

## Assumptions (positions at the Step-13 gate; ledger Phase-119, all_accept:false)
- **A1 (don't-know → deferred, revisit-open, cost high):** a persistent session keeps the gate un-bypassable across turns + mutations. Resolved at the T1 verification checkpoint.
- **A2 (accept, cost high):** Ph115 display-only restore + a "model context reset" marker is acceptable (vs gated engine-replay).
- **A3 (don't-know → deferred, revisit-open, cost high):** a model-facing memory carve-out is safe. DOWN-SCOPED this phase to host-orchestrated memory.
- **A4 (don't-know → deferred, revisit-open, cost medium):** a lean prompt can be appended without breaking local tool-calls. DOWN-SCOPED this phase to AGENTS.md/context injection.
