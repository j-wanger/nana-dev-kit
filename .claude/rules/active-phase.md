# Active Phase Context

Phase: 119 — Pi-UX felt-quality + ecosystem slice (Tier 1 + Tier 3). status: ACTIVE — BUILT + GREEN (all 9 tasks [x], 2026-07-01); delivery PENDING the maintainer live-drive + acceptance. Standard ceremony.
Objective: Give nana's embedded-Pi GUI real felt-quality (context/cost meter + /compact, runtime model + thinking switch, prompt-template/skill palette) on a PERSISTENT cross-turn Pi session whose un-bypassable host gate SURVIVES persistence + every mutation, plus SAFE-fallback ecosystem wiring (host-orchestrated memory + AGENTS.md/context; NO carve-out, NO systemPromptOverride).
Outcome: T1 rebuilt the per-turn EPHEMERAL Pi session into ONE PERSISTENT build-once session; the A1 gate-survival CHECKPOINT verdict = the gate SURVIVES persistence + every mutation, DEFER NOTHING ([[pi-gate-survives-mutation]]; compiled-SDK read + Pi docs + a LIVE turn-2 rm-block) → maintainer USER-OVERRIDE continue-autonomously-T2→T9. app/ 456/456 + npm run build + cargo check green; adversarial gate-bypass review 0 defects (2 Low nits fixed inline); host-gate policy byte-unchanged. T9 hosted-maxTokens = [[hosted-maxtokens-not-a-bug|not a bug]].
Scope: app/src/engine/pi/**, app/src/{engine,gate,host,context,ui}/**, app/src/control/spend.ts, specs/phase-119-*.md.
Key constraints (held): host gate byte-unchanged + un-bypassable across persistence + every mutation; C1 denial-sink decoupled from the per-turn queue (swap a per-turn queue REFERENCE); each mutating surface shipped a gate-survives-after test (C3); Ph115 restore DISPLAY-ONLY + a 'model context reset' marker (ZERO engine sends); SAFE fallbacks (A3 host-orchestrated memory, A4 AGENTS.md/context de-duped via noContextFiles:true); local $0 default KEPT.
Exit criteria: build MET — cd app && npm test + npm run build + (cd src-tauri && cargo check) all green; T1 verdict recorded; ledger Ph119 A1/A2 held, A3/A4 open. REMAINING: the maintainer live-drive (turn-2 denial visible, interrupt-then-continue, restart divergence marker).
Abort rule: a gate-survives-mutation test failing → STOP + defer that surface (none did); a task failing 3× → mark [blocked] + ask the maintainer.
Deferred → Phase 120 candidates (tasks.md): A3 model-facing memory carve-out, A4 systemPromptOverride, the T2-tier gate-hero/file-timeline/branching items.
Decision: [[pi-ux-persistent-session-slice]] (high, Outcome appended). Spec specs/phase-119-pi-ux-felt-quality-slice.md (nana:approved). Lineage [[engine-adapter-in-process-gate]] / [[pi-default-engine]] / [[conversation-memory-persistence]] / [[pi-gui-setup-improvements]].
Gates:
- [x] spec — specs/phase-119-pi-ux-felt-quality-slice.md (nana:approved 2026-07-01)
- [x] Direction confirmed (assumption positions 2026-07-01; ledger Ph119 revisit filled: A1/A2 held, A3/A4 open)
- [x] Delivery accepted (maintainer accept-on-build-evidence 2026-07-01; live-drive a post-commit sanity check)
