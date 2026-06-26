---
title: "Phase 108: GUI Dev-Harness v1 Thin Slice"
aliases: [phase-108, gui-harness-v1, gui-harness-thin-slice]
category: phases
tags: [gui-harness, pivot, tauri, engine-adapter, security-gate, pi-sdk, claude-agent-sdk, mcp-memory, in-process, phase-108]
parents: []
created: 2026-06-26
updated: 2026-06-26
source: plan
status: completed
scope: ["app/**", "specs/gui-harness-architecture.md"]
entry_criteria: "Spec specs/gui-harness-architecture.md APPROVED (nana:approved 2026-06-26, Rev 2); external-boundary alternatives (ACP/opencode-HTTP/Goose/Paseo) verified against primary sources as unable to own a pre-execution gate; assumption positions taken 2026-06-26 (A1/A2/A4 accept, A3 keyring-rs deferred don't-know); ledger Phase-108 appended + validated."
exit_criteria: "A running v1 thin slice makes the 14 machine-checkable spec criteria pass (Tauri bundle launches; Pi-adapter provider round-trip; second-adapter (Claude SDK) through the same gate; MCP memory write→restart→read-back; in-process destructive-gate denial; gate-bypass-resistance; checkpoint revert-to-exact-bytes; key-store read-deny; inert CSP render; ≤2s hard interrupt; spend-ceiling hard pause; loud memory-unavailable; external-modification detected+held; tool-call normalization byte-identical across ≥2 adapters)."
---

# Phase 108: GUI Dev-Harness v1 Thin Slice

## Objective

Re-platform nana-dev-kit into a GUI-primary, model-agnostic desktop dev harness per the approved spec: build the GUI surface and EMBED a model-agnostic agent engine IN-PROCESS behind an app-owned `EngineAdapter` interface, with the security gate at the in-process tool-call site. This phase = the v1 thin slice (minimum daily loop + security rails), security/gate FIRST.

## Scope

- `app/**` — the new GUI application (Tauri Rust shell + TS/React surface, engine adapters, gate, checkpoint, control, memory mount, tests).
- `specs/gui-harness-architecture.md` — the governing spec (read-only reference).

OUT: any rewrite of the Python MCP memory server (it ports as-is via MCP stdio); any external wire-protocol/server boundary (verified unable to own a pre-execution gate); daily-driver use on the live repo before all security rails pass.

## Exit Criteria

The architecture is validated by a working v1 thin slice — 14 machine-checkable functional tests:

- [ ] Tauri build produces a runnable desktop bundle that launches.
- [ ] End-to-end provider round-trip via the embedded Pi SDK: a GUI prompt streams a visible response (`tests/e2e/provider-roundtrip`).
- [ ] The same engine-adapter interface drives a second engine (Claude Agent SDK) through the identical gate path (`tests/e2e/second-adapter`) — engine-neutrality.
- [ ] The Python MCP memory server mounts and round-trips: write → session restart → read back (`tests/e2e/memory-roundtrip`).
- [ ] The in-process gate denies a seeded destructive tool call (`bash rm`) with no side effect (`tests/security/destructive-gate`).
- [ ] A model-side bypass attempt (same-name shadow tool; unregistered tool) cannot suppress the host gate (`tests/security/gate-bypass-resistance`).
- [ ] A file edit through the checkpoint layer reverts to exact pre-edit bytes in one action (`tests/checkpoint/revert-bytes`).
- [ ] The agent's file-read tool returns access-denied for the key-store path (`tests/security/key-store-deny`).
- [ ] Prompt-injected tool output renders inert and trips a CSP report (`tests/security/inert-render`).
- [ ] A GUI hard interrupt cancels an in-flight/hung tool call within ≤2s (`tests/control/interrupt-hung-tool`).
- [ ] Cost past the configured ceiling triggers a hard pause-for-confirmation (`tests/control/spend-ceiling`).
- [ ] With the memory server stopped, startup surfaces a loud unavailable state and refuses silent-memoryless (`tests/integrity/memory-unavailable`).
- [ ] A file modified externally between read and write is detected and the write held (`tests/safety/external-modification`).
- [ ] The same tool call through ≥2 adapters normalizes to byte-identical internal representation (`tests/adapters/normalize-identical`).

## Constraints (load-bearing)

- **The security gate lives in-process at the tool-call site** — a host can only own a pre-execution gate if the agent loop runs in the host's own process. The swappable boundary is the app-owned `EngineAdapter` interface (≥2 implementations), NOT a wire protocol / external server.
- **Verify un-bypassability by firing, not by claim** ([[HEU-012]]): the security rails are exit-criteria tests. If the Pi `tool_call` hook proves bypassable from the model side → STOP-and-escalate (swap primary to Claude Agent SDK / Vercel AI SDK behind the same adapter), never ship a bypassable gate.
- **Adopt the engine, don't build the loop** (amplifier-null family — the agent loop is commodity, +0.25 floor): Pi primary, Claude SDK second, Vercel AI SDK (build-the-loop) only as the deeper fallback.
- **Key custody fails to a credential helper, never plaintext** (A3): if keyring-rs+Tauri+agent-deny fails on macOS, key custody moves to a separate non-agent-reachable credential helper.
- **UI/felt quality is UNMEASURABLE in-kit** (Ph59/80 carve-out): ships on the maintainer's judgment at the delivery gate; tests assert MECHANICS only.

## Checkpoints

- After the engine spike (Pi embedded + one provider streaming + the `tool_call` gate denying a seeded destructive call): report; confirm Pi vs alternatives before building further.
- After the second-adapter proof (Claude Agent SDK through the same gate interface): report — engine is swappable, not Pi-locked.
- After the memory-server mount + round-trip: report — the spine ports as-is.
- After the security rails (keychain deny, inert CSP + capability-manifest audit, destructive-gate + bypass-resistance, checkpoint revert): report. Do NOT enable daily-driver use on the live repo until all pass.
- If Pi's gate proves bypassable, or its `tool_call`/`event.input` contract is too unstable across versions → STOP and escalate (maintainer decision, not autonomous).
- If the memory-DB / dev-wiki import is lossy vs the originals → STOP; do not cut over amnesiac.

## Blockers and Open Questions

- **keyring-rs + Tauri + agent-deny on macOS (A3 — RESOLVED→accept 2026-06-26, revisit-status: held).** T2 proved it: keyring-rs 3.6.3 (apple-native) round-trips a secret through the REAL macOS Keychain (set→get→delete one-process, no prompt) via a standalone `keyhelper` crate; the agent file-read tool is denied the key-store path; key-shaped strings redacted from logs. Did NOT bite — no credential-helper fallback needed at the dev/unsigned level. **NEW residual (routed to Phase-109):** keyring behavior inside a SIGNED/NOTARIZED Tauri bundle (entitlements/ACL) verifies only at bundle time; the credential-helper fallback stays the contingency for that case. Fold into the bundle/notarization work.

## Notes

Decision [[engine-adapter-in-process-gate]] (high) — embed the engine in-process behind an app-owned adapter; the gate lives at the tool-call site. ACP/opencode-HTTP/Goose/Paseo each verified unable to own a pre-execution gate (agent runs in their process; permission is relay/discretion). Spec `specs/gui-harness-architecture.md` (nana:approved 2026-06-26, Rev 2). Ledger Phase-108 (all_accept:false — A3 deferred don't-know). The app lives in a new `app/` dir; the Python MCP memory server is untouched (mounted via MCP stdio).

## Outcome (BUILT 2026-06-26 — delivery gate PENDING; status remains active)

All 8 tasks [x]; all 14 machine-checkable exit criteria proven (criterion #1 Tauri-bundle = compile-proven, `cargo build` exit 0 / 23.5MB; visual window-launch is the maintainer's check). 63/63 app tests green (incl. live Pi provider round-trip + live Vercel second-adapter + live MCP memory round-trip); `tsc --noEmit` + `vite build` + `cargo build` all exit 0. The Rust toolchain (1.96.0) was installed this session (DEPENDENCY escape hatch, maintainer-confirmed).

- **A1 EMPIRICALLY validated** (not just inferred): a real local model (Qwen3.6-35B via llama.cpp @ localhost:8080) attempted `bash rm` AND an out-of-workspace write through BOTH adapters; the in-process gate denied both before execution — no STOP-and-escalate.
- **A2 validated**: the MCP round-trip failure was a MOUNT bug (FastMCP wraps a list return as `structuredContent.result`; the mount unwraps it), server UNTOUCHED — exactly A2's predicted disposition.
- **A3 resolved→accept** (held): keyring-rs round-trips the real macOS Keychain; residual = signed-bundle entitlements (Phase-109 / bundle-time).
- Two deviations within the spec's approved engine set: provider default = a LOCAL OpenAI-compatible backend (subscription-OAuth ruled OUT — Anthropic prohibits + meters `sk-ant-oat` in third-party harnesses, no Max-quota benefit; [[provider-defaults-to-local-model]]); second adapter = Vercel AI SDK (USER OVERRIDE — the Claude Agent SDK is API-key-only; [[second-adapter-vercel-ai-sdk]]). Engine-neutrality proven LIVE: one `createHostGate`, two engines, both deny a real `bash rm`.
- Ledger Phase-108 A1/A2/A3/A4 all `held` (none bit; `bash scripts/check-assumption-ledger.sh --revisit ... 108` exit 0).
- Discovered → Phase 109+: Claude Agent SDK adapter (key-gated) / felt-quality + branding pass / signed bundle + auto-update + rollback / live-repo dogfood (now unblocked — all security rails pass).
