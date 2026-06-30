---
title: "Phase 114: Pi as the default daily engine (good tools) + workspace picker"
aliases: [phase-114, pi-default-engine, good-tools, workspace-picker]
category: phases
tags: [engine-adapter, pi-sdk, vercel, default-engine, tools, workspace, picker, tauri, gate, security, dogfood]
parents: [phase-109-felt-quality-surface, phase-112-os-sandbox-bash-fs-isolation]
created: 2026-06-30
updated: 2026-06-30
source: plan
status: built
scope: ["app/src/engine/pi/**", "app/src/engine/vercel/**", "app/src/host/**", "app/src/ui/**", "app/src/App.tsx", "app/src-tauri/**", "app/tests/**", ".claude/rules/active-phase.md"]
entry_criteria: "Phase 113 DELIVERED + ACCEPTED (axis-3 command palette; commit landed; app suite 318 green after the 2026-06-30 dogfood HOTFIX — Vercel step-cap #1 / spinner #4 / failed-turn render #5). A live drive surfaced 'the tools are awful'; a 4-lens investigation root-caused it as an ACCIDENTAL default (main.ts:20 NANA_ENGINE ?? 'vercel'), not a missing feature — Pi (the spec's PRIMARY) already ships the rich paginated/capped tool suite and the gate already covers it (Ph112 T1/A4). Dogfood #3 (wrong-project / workspace silently = app/ cwd) folded in; #2 conversation memory → Ph115."
exit_criteria: "NANA_ENGINE-unset defaults to Pi (Vercel intact as the explicit fallback); a LIVE Pi e2e (skip-loud without localhost:8080) proves Pi streams a real response, grep/find/ls are ACTIVE (not a bash fallback), a surgical edit applies, the gate is PROVABLY in the loop for the new tools (secret-path grep/ls DENIED; destructive write/edit HELD + snapshotted), and outputs are capped (length ≤ cap + truncation marker); maxTokens threaded past 2048 (NANA_MAX_TOKENS, default ~8192); a Rust-atomic workspace picker (native dialog → re-spawn the sidecar with the chosen NANA_WORKSPACE; webview NEVER supplies the root; dialog-ONLY capability — no fs/shell/http); the UI shows the active workspace + project-blind state + a 'Change workspace…' palette command; the gate verdict-loop core + inert-render + redact NO regression on the Pi path; full app suite + npm run build + cargo check all exit 0; + a focused adversarial pre-commit review's confirmed findings fixed. Out-of-workspace READ stays the pre-existing Ph112 residual; the native re-spawn round-trip is live-verified by the maintainer (cargo check = compile, Ph109-112 precedent)."
---

# Phase 114: Pi as the default daily engine (good tools) + workspace picker

## Objective

Fix the dogfood "the tools are awful" complaint at its real root: **make Pi the default engine** (it already ships read/grep/find/ls + surgical edit + a capping bash; the gate already covers it), instead of building a tool suite for the **accidentally-default** Vercel adapter. Harden the Pi path (maxTokens, activate the dormant grep/find/ls, prove the live round-trip) and add a **Rust-atomic workspace picker** (dogfood #3).

## Scope

Files and modules affected:
- `app/src/host/main.ts` — flip the default to Pi; thread `NANA_MAX_TOKENS`; export `buildAdapter` + guard the auto-run
- `app/src/engine/pi/**` — thread `maxTokens` past 2048; activate grep/find/ls (`tools` allowlist, fallback `customTools`)
- `app/src/engine/vercel/**` — fallback only (kept usable by the hotfix step-cap fix)
- `app/src-tauri/**` — Tauri dialog plugin + dialog-only capability grant + `pick_workspace` command + kill-and-respawn lifecycle
- `app/src/ui/**`, `app/src/App.tsx`, `app/src/host/engine-host.ts`, `app/src/ui/engine-bridge.ts` — workspace UI surface + bridge re-wire + widen the `ready` message
- `app/tests/**` — live e2e, adapter, host, capability-audit, ui tests
- `.claude/rules/active-phase.md` — flip to BUILT at T6

**OUT (→ later):** conversation memory (dogfood #2 → Ph115); blocking out-of-workspace READ (Ph112 confidentiality residual); cross-platform OS-sandbox; Claude Agent SDK adapter.

## Exit Criteria

- [x] LIVE Pi e2e proves: real streamed text; grep/find/ls ACTIVE (not a bash fallback); a surgical edit applies; the gate is PROVABLY in the loop (secret-path grep/ls DENIED, destructive write/edit HELD + snapshotted — an outcome ONLY the gate produces); outputs capped (length ≤ cap + truncation marker) — `maxTokens` threaded (NANA_MAX_TOKENS, default ~8192) (T1)
- [x] `buildAdapter()` defaults to `'pi'` when `NANA_ENGINE` is unset; `NANA_ENGINE=vercel` → `'vercel'` (fallback intact); `buildAdapter` exported + the module auto-run guarded so the test imports without opening stdin (T2)
- [x] A capability-audit test asserts no broad fs/shell/http/process/os grant and at most `dialog:allow-open`, and that `pick_workspace` takes NO webview-supplied path argument (T3 — landed TIGHTER than planned: the dialog is opened Rust-side, so the webview gets NO dialog grant at all)
- [x] On a chosen workspace the bridge tears down + reconnects + re-receives `ready`, and the new sidecar is spawned with the chosen `NANA_WORKSPACE` (fresh `createHostGate(newRoot)` + fresh approved-writes Map); native dialog→re-spawn runtime is LIVE-DRIVE-only (cargo check proves compile) (T4)
- [x] The header shows the active workspace + PROJECT-BLIND state (from the widened `ready` — `workspaceRoot` + assembly available/sources, NOT the `systemContext` string); a "Change workspace…" palette command invokes `pick_workspace` (T5)
- [x] Full app suite (343) + `npm run build` + `cargo check` exit 0; gate/inert/redact + Ph110/111 tool-visibility NO regression on the Pi path; focused adversarial pre-commit review's 6 confirmed findings fixed; residuals documented; active-phase.md → BUILT (T6)

## Review & Residuals (T6)

**Adversarial pre-commit review** — 3 parallel finders, every finding verified against the code by the orchestrator (subagent prose is candidate-only; see [[HEU-012]] / the Ph80 leak discipline). **6 confirmed findings, all fixed:**

| # | Sev | Finding | Fix |
|---|-----|---------|-----|
| 1 | HIGH | `secret-deny` was ancestor-blind: the Ph114-activated grep/find/ls RECURSE (and, unlike bash, are NOT seatbelt-confined), so `grep ~` / `ls ~/.aws` read secret files the gate did not deny (`isDeniedPath` is self-or-descendant only). Newly exposed by activating these tools. | `pathReachesDeniedPath` (ancestor-aware); the grep/find/glob/ls gate case checks `args.path ?? workspaceRoot` through it. New ancestor tests. |
| 2 | MED | Zombie child: `pick_workspace` `kill()`'d the old sidecar but never `wait()`'d it → a defunct process leaks per workspace change. | Reap off-thread (`thread::spawn(move \|\| { let _ = old.wait(); })`). |
| 3 | MED | Re-entrant `changeWorkspace` clobbered the single `readyWaiter` → the first promise hangs + a double respawn. | `changing` re-entrancy guard (a re-entrant call returns null). +test. |
| 4 | LOW | Non-atomic child/stdin swap window: `engine_send` could write to the dead pipe mid-swap. | Hold the stdin lock across BOTH swaps (stdin→child; no lock-order inversion with `engine_send`). |
| 5 | LOW | Relative-path cwd divergence after respawn: the gate resolves a relative path against `app/`, Pi against the workspace. | `spawn_sidecar` sets `current_dir(ws)` so `process.cwd()` == Pi's cwd == workspaceRoot. |
| 6 | LOW | Unhandled rejection in `App.changeWorkspace` dispatch on a dialog/respawn failure. | `.catch` surfaces it (prior session stays intact). |

**Residuals (honest, NOT over-claimed):**
- **Out-of-workspace READ stays the pre-existing Ph112 residual** — UNCHANGED. Pi's read tools make it ergonomic, not newly possible. The Ph114 fix tightened the *secret* class specifically (grep/find/ls can no longer reach `~/.ssh`/`~/.aws`/keychain via an ancestor root); blocking general out-of-ws reads = a future confidentiality phase.
- **Native dialog → kill → respawn → re-ready round-trip is LIVE-DRIVE-only** — `cargo check` proves it compiles; runtime is the maintainer's drive (Ph109–112 precedent). The fresh-process ⇒ fresh `createHostGate(root)` + fresh approved-writes is a property of `main.ts` re-reading `NANA_WORKSPACE`, asserted structurally, not as an in-process event.
- **#2 conversation memory → Ph115** (out of this phase's scope by plan).
- **PRE-EXISTING, out-of-scope (flagged for a future renderer-trust phase, NOT a Ph114 regression):** under the "renderer is potentially-compromised" model, a compromised renderer can (a) auto-approve a held gate call via `engine_send({type:'gate-verdict', approved:true})` (the Ph108/109 confirming-gate trust model — the host trusts the renderer's verdict), and (b) pop unsolicited native folder dialogs (mild annoyance/DoS; any app command is renderer-invocable by default). Neither relocates the gate root; the picker's "renderer can't supply the root" guarantee holds. Worth a separate decision on a non-renderer authorization gesture for host-side verdicts.

## Constraints

- **SECURITY (the constant, unchanged):** the in-process gate must intercept EVERY tool call on the Pi path incl. the now-active grep/find/ls (`host-gate.ts` `default` branch already covers them by string args) — prevents the engine flip from opening an ungated tool. The gate verdict-loop core (`ConfirmationBroker`/`confirmingGate`/key-store hard-deny) + inert-render + redact stay UNCHANGED — prevents a security-rail regression.
- **The picker MUST be Rust-atomic** — the gate auto-allows in-workspace writes, so the workspace root IS the free-write zone; a webview-supplied root would let the model relocate the gate boundary. Native dialog → re-spawn; webview never sends a path; capability grant is dialog-ONLY.
- **Mechanics-only tests** — felt-quality + the native re-spawn runtime ship on maintainer judgment (Ph59/80 carve-out, Ph109-113 precedent).

## Checkpoints

- **T1 is the FRONT-LOADED make-or-break (A1).** STOP-and-escalate (do NOT flip the default) if Pi can't drive the local model reliably OR the gate can't be PROVEN to see the now-active tools. The live round-trip was never GUI-verified (Ph109 deferred) + a flaky e2e exists — Vercel may be the de-facto path for a real reason.

## Assumptions

- **A1 (high, the key risk):** the live Pi round-trip works reliably. If false: STOP-escalate at T1; the default stays Vercel.
- **A2/A3:** grep/find/ls activate via the `tools` allowlist (else `customTools`, T1 resolves); the gate's default branch covers them (T1/T6 verify empirically). If false: register via `customTools` / widen the gate.
- **A4:** the Rust dialog→re-spawn round-trip is the right boundary. If false: the webview-supplied-root alternative is REJECTED (re-opens the gate-root relocation).

## Notes

Umbrella spec: `specs/gui-harness-architecture.md` (nana:approved) — its Surface + the Pi-primary engine choice govern this slice; no separate phase spec (ADR-named, Ph108-113 precedent). Decision [[pi-default-engine]] (high). Builds on [[engine-adapter-in-process-gate]] (Pi named primary), [[os-sandbox-bash-fs-isolation]] (Ph112 proved the gate sees ALL Pi tools), [[second-adapter-vercel-ai-sdk]] + [[provider-defaults-to-local-model]] (why Vercel was the 2nd adapter, not the intended default).

**Grounding (verified against the code):** `main.ts:20` `NANA_ENGINE ?? 'vercel'` (the accidental default); `main.ts:17` `buildAdapter` not exported; `main.ts:65` `main()` auto-runs at import; `main.ts:31` `NANA_WORKSPACE ?? process.cwd()` = `app/`; `pi-adapter.ts:309` `maxTokens ?? 2048`; `pi-adapter.ts:384` `customTools` on `createAgentSession`; `host-gate.ts:179` default branch + `PATH_ARG_KEYS` + `isDeniedPath`; `lib.rs:45/62` `spawn_engine_host` → `Command::new("node")` sets no cwd/env. Pi caps: 2000 lines / 50KB, default-active tools = read/bash/edit/write only.

**Knowledge gaps (T1 resolves):** whether the `tools` allowlist alone activates grep/find/ls or they also need `customTools`; whether Pi drives the local model reliably in a live drive (A1, STOP-escalate); the gate-implications investigation lens FAILED (retry cap) → T1/T6 verify the gate's coverage of the now-active read/grep/find/ls empirically.
