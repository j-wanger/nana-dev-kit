---
title: "Pi as the default daily engine (good tools) + workspace picker"
aliases: [pi-default-engine, pi-default-daily-engine, good-tools, workspace-picker, pi-good-tools]
category: decisions
tags: [engine-adapter, pi-sdk, vercel, default-engine, tools, workspace, picker, tauri, gate, security, dogfood, phase-114]
parents: [phase-114-pi-default-engine-workspace-picker]
created: 2026-06-30
updated: 2026-06-30
source: debrief
confidence: high
---

## Context

Live-drive dogfooding surfaced a sharp complaint: **"the tools are awful — bash read takes the whole document and fills the model's context."** A 4-lens adversarial investigation found the root cause is NOT a missing feature — it is an **accidental default**. The embedded agent runs on the **Vercel** adapter, which carries only two hand-rolled tools: `bash` (output uncapped) and `write` (whole-file overwrite, no surgical edit). But Vercel is the default purely by a **Phase-109 bring-up artifact** — `app/src/host/main.ts:20` reads `process.env.NANA_ENGINE ?? 'vercel'`. **No decision ever chose Vercel as primary.** The spec and all three Phase-108 decisions name **Pi** (`@earendil-works/pi-coding-agent`) as PRIMARY (`specs/gui-harness-architecture.md`:42/91 "round-trip via the embedded Pi SDK"; [[engine-adapter-in-process-gate]]); Vercel was only ever the approved *fallback* ([[second-adapter-vercel-ai-sdk]], [[provider-defaults-to-local-model]]).

Pi ALREADY ships the rich tool suite the complaint asks for: `read` (offset/limit pagination), `grep` (ripgrep), `find` (fd), `ls`, surgical multi-`edit` (not whole-file), and a `bash` that **caps output (2000 lines / 50KB) and spills overflow to a file**. The host gate (`pi.on('tool_call')`) intercepts ALL of them — proven Phase-112 T1/A4. So **"good tools" = make Pi the default, not build a tool suite for Vercel.**

## Decision

**Make Pi the default daily engine** (flip `main.ts:20` `'vercel'` → `'pi'`; Vercel stays as the explicit `NANA_ENGINE=vercel` fallback, kept usable by the Ph-hotfix step-cap fix), **harden the Pi path** so it is actually good to drive, and **add a Rust-atomic workspace picker** (folded in from dogfood complaint #3). Hardening:
- **Thread `maxTokens` past the 2048 default** (`pi-adapter.ts:309` `maxTokens ?? 2048`, never threaded from `main.ts`) → configurable `NANA_MAX_TOKENS`, default ~8192, or Pi truncates responses.
- **Activate Pi's dormant `grep`/`find`/`ls`** (default-active set is `read`/`bash`/`edit`/`write` only) via the `tools` allowlist on `createAgentSession`; IF allowlisting alone does not register them, register via `customTools`/`createAllToolDefinitions` (T1 spike resolves which).
- **Workspace picker** = a native Rust folder dialog → re-spawn the node sidecar with the chosen `NANA_WORKSPACE` (a fresh process rebuilds `createHostGate(newRoot)` + resets approved-writes). The webview NEVER supplies the root; the capability grant is **dialog-ONLY** (no fs/shell/http).

### Locked assumption positions (assumption-ledger Phase-114, all_accept:true)
- **A1 (the KEY RISK, high) — accept, spike-gated.** The live Pi GUI round-trip was NEVER verified (Ph109 deferred it) and a flaky e2e exists → Vercel *might* be the de-facto path for a real reason. **T1 FRONT-LOADS a live Pi drive with a hard STOP-and-escalate**: do NOT flip the default if Pi can't drive the local model reliably OR the gate can't be PROVEN to see the now-active tools.
- **A2/A3 — accept.** Config wiring (maxTokens threading; grep/find/ls activation) is mechanical; the gate's `default` branch already covers grep/find/ls by string args (`host-gate.ts` `PATH_ARG_KEYS` + `isDeniedPath`), verified empirically by T1/T6.
- **A4 — accept.** The picker MUST be Rust-atomic because the gate AUTO-ALLOWS in-workspace writes — the workspace root IS the free-write zone, so a webview-supplied root would let the model relocate the gate boundary. Native dialog → re-spawn; webview never sends a path.

### Alternatives considered + rejected
- **(B) Build a tool suite on Vercel** — re-implements what Pi already ships, each tool gate-wrapped by hand; rejected (Pi has it + the gate already covers it).
- **(C) User-pickable engine+workspace at launch** — bigger scope; only the **workspace** half was folded in; engine choice stays an env var.
- **Conversation-memory (dogfood #2)** — deferred to **Phase 115** (cleaner to design once the engine is decided).

## Consequences

- `main.ts` gains an exported `buildAdapter` + a guarded auto-run (so the default-flip is unit-testable without opening stdin); `pi-adapter` gets a threaded `maxTokens`; `createAgentSession` gets a `tools` allowlist (and possibly `customTools` for grep/find/ls).
- New Tauri **dialog** plugin + a **dialog-only** capability grant + a `pick_workspace` Rust command that takes NO webview path arg; a Rust **kill-and-respawn** of the sidecar with the chosen cwd/`NANA_WORKSPACE`; the bridge re-wires (re-listen + re-ready).
- The UI surfaces the active workspace + a **project-blind** state (carried on the widened `ready`/status message — `workspaceRoot` + assembly available/sources, NOT the full `systemContext` string, which contains AGENTS.md/CLAUDE.md); a "Change workspace…" palette command.
- **HONEST RESIDUALS (do NOT over-claim):** **A1** — the live round-trip is the make-or-break, proven only by T1's live drive; the native-dialog→re-spawn round-trip itself is **live-drive-only** (cargo check = compile, runtime deferred to the maintainer, Ph109-112 precedent). **Out-of-workspace READ stays OPEN** (the pre-existing Ph112 residual — Pi's read tools make it *ergonomic*, not newly possible; blocking reads = a future confidentiality phase). **#2 conversation memory → Ph115.**
- SECURITY (the constant, unchanged): the in-process gate intercepts EVERY tool call on the Pi path incl. now-active grep/find/ls; the gate verdict-loop core ([[gate-confirm-approve-loop]] ConfirmationBroker/confirmingGate/key-store hard-deny) + inert-render + redact stay UNCHANGED.

## Outcome (DELIVERED 2026-06-30)

Delivered, all 6 tasks; app suite **343/343** + `npm run build` + `cargo check` exit 0. T1 (make-or-break) PASSED — live Pi e2e green, the gate intercepts every tool, no STOP; default flipped vercel→pi. The Rust-atomic picker landed **TIGHTER than planned**: the dialog is opened from Rust, so the webview gets **NO dialog capability at all** (verified against the Tauri v2 model — app-commands are default-allowed + Rust-side plugin calls bypass the webview ACL; `default.json` stays `core:default`).

The T6 adversarial pre-commit review (3 finders, every finding orchestrator-verified against the code) caught + fixed **6 confirmed findings, incl. 1 HIGH**: the secret deny-list was **ancestor-blind**, so the now-active recursive grep/find/ls (NOT seatbelt-confined like bash) reached `~/.ssh` / `~/.aws` via an *ancestor* search root the gate didn't deny — fixed with `pathReachesDeniedPath` (ancestor-aware) on the grep/find/glob/ls gate case. The detail + the gate-design lesson are in the journal [[2026-06-30-phase-114-pi-default-engine-workspace-picker-delivered]] and the §Review & Residuals of the phase article. **Ledger revisit: A1/A3/A4 held, A2 BIT** (the ancestor-blind secret-read hole — the assumption that activation added no new hole beyond the read residual was disproven). Residuals unchanged: out-of-ws READ = Ph112 residual; native respawn round-trip live-drive-only; #2 conversation memory → Ph115; a pre-existing renderer-trust gap (a compromised renderer can auto-approve a held gate via `engine_send{gate-verdict}`) flagged for a future phase.

## Source

Phase 114 plan (2026-06-30), delivered + debriefed 2026-06-30. Direction confirmed at the assumption gate (ledger Phase-114, all_accept:true, A1-A4; `--gate 114` exit 0). Trust: high. Builds on [[engine-adapter-in-process-gate]] (Pi named primary), [[os-sandbox-bash-fs-isolation]] (Ph112 proved the gate sees ALL Pi tools), [[second-adapter-vercel-ai-sdk]] + [[provider-defaults-to-local-model]] (why Vercel was the 2nd adapter, not the intended default). Rides umbrella spec `specs/gui-harness-architecture.md` (Ph108-113 precedent, ADR-named).
