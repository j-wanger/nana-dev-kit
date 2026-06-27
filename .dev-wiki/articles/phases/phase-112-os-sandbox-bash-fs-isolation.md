---
title: "Phase 112: OS-sandbox bash filesystem isolation"
aliases: [phase-112, os-sandbox-bash, seatbelt-bash-isolation, bash-fs-sandbox]
category: phases
tags: [security, gate, host-gate, bash, sandbox, seatbelt, sandbox-exec, engine-adapter, pi-sdk, tauri, phase-112]
parents: [phase-111-typed-artifact-fidelity, engine-adapter-in-process-gate, host-gate-out-of-workspace-hardening]
created: 2026-06-27
updated: 2026-06-27
source: plan
status: active
scope: ["app/src/engine/pi/**", "app/src/engine/vercel/**", "app/src/gate/**", "app/src-tauri/src/**", "app/tests/**"]
entry_criteria: "Phase 111 committed (host-gate string-gating residual documented + filed). sandbox-exec confirmed working on the darwin dev machine."
exit_criteria: "A bash file-write outside the workspace is blocked by an OS-level filesystem sandbox even when the Ph111 string-gate cannot see it (python -c / node -e / base64 / env indirection); the gate verdict-loop core stays UNCHANGED; deterministic execute-under-profile test proves the block on darwin (skip-loudly off-darwin); app suite + tsc + cargo check all green."
---

# Phase 112: OS-sandbox bash filesystem isolation

## Objective

Replace/augment the Phase-111 string-gating of bash with OS-LEVEL filesystem sandboxing (macOS seatbelt via `sandbox-exec -p '<profile>'`) that confines bash tool execution's file WRITES to the workspace directory — closing the documented Ph111 residual (`python -c` / `node -e` / base64-decode / env-indirection evasions that string-gating cannot catch by nature). Adds a deeper enforcement layer BELOW the gate; does not reshape the gate.

## Scope

- `app/src/engine/pi/**` — primary adapter; bash runs inside the Pi SDK. Attach via a Pi executor seam (`baseToolsOverride` / `BashSpawnHook` / `BashOperations`).
- `app/src/engine/vercel/**` — second adapter; we own the spawn (`runBash` `execSync`, vercel-adapter.ts:54).
- `app/src/gate/**` — verdict-loop core UNCHANGED; the sandbox composes with (does not replace) the host-gate.
- `app/src-tauri/src/**` — only if a process-wide sandbox of the Node sidecar is chosen over per-command wrapping.
- `app/tests/**` — new execute-under-profile sandbox test class.

## Exit Criteria

- [x] A bash write outside the workspace is blocked at the OS layer even when the Ph111 string-gate misses it (python/node/base64/env-indirection probe) — 18 evasion vectors blocked at the syscall layer (T1 spike).
- [x] The gate VERDICT-LOOP core (ConfirmationBroker / confirmingGate / key-store hard-deny / host-gate base policy) is UNCHANGED — T4 added an approved-targets channel BESIDE it, not inside it.
- [x] Deterministic test executes a real command under the profile and asserts the out-of-workspace write FAILED (darwin); skips loudly off-darwin — `app/tests/sandbox/seatbelt-spike.test.ts` (49) + `gate/sandbox-no-bypass.test.ts` (8).
- [x] Pi's own temp writes + legitimate reads/network/exec still work (A2 BIT-partially: npm/pip/cargo caches denied at first → fixed by allowing `~/.npm`/`~/.cache`/`~/.cargo` in the integrity profile).
- [x] app suite (201→274) + `tsc --noEmit` + `npm run build` + `cargo check` all exit 0.

## Constraints

- Constraint: the gate verdict-loop core stays UNCHANGED — prevents reshaping the security gate while adding a layer (Ph108/109/110/111 invariant).
- Constraint: measure the FALSE-POSITIVE rate of the profile on common agent operations — an over-tight sandbox that breaks legit workspace work is a regression (the Ph111 alert-fatigue lesson, applied to OS enforcement).
- Constraint: the Ph111 string-gate is NOT removed — it remains defense-in-depth + the cross-platform fallback (seatbelt is macOS-only).

## Open Questions

The four planning forks are now LOCKED at the assumption gate (decision [[os-sandbox-bash-fs-isolation]]): Pi attach seam = `baseToolsOverride` (fallbacks BashSpawnHook→BashOperations→gate-modify, A4); wrap layer = per-command TS chokepoint (A3/A4 — engine-neutral, not the Rust sidecar); profile/confirm-loop tension = C1-PRESERVE (approved out-of-ws write threads into `extraWrites`, A3); cross-platform = Ph111 string-gating remains the off-darwin fallback (Linux landlock/bwrap OUT, documented residual). The REMAINING open risk is EMPIRICAL, resolved by the front-loaded T1 spike: see `.dev-wiki/_CURRENT_STATE.md` Blockers `[open: Phase-112 — T1 de-risking gate]` (A1 inheritance / A4 Pi-seam-binds / A5 strict-viability; STOP-and-escalate to integrity-only if T1 fails).

## Notes

Pi SDK (`@earendil-works/pi-coding-agent` v0.80.2) publicly exports first-class bash-executor seams (`dist/index.d.ts`): `createAgentSession({ baseToolsOverride })`, `createBashTool(cwd, { spawnHook | operations })`, `createLocalBashOperations`. So OS-sandboxing IS reachable from our code without forking Pi. `GateDecision.modify` (types.ts:25) already contemplates "redirect a write into a sandboxed path." `sandbox-exec` confirmed working on the darwin dev machine (exit 0). The Python MCP memory server is a separate process, unaffected by a bash-scoped sandbox.

## Outcome (BUILT + adversarially reviewed 2026-06-27 — READY FOR COMPLETION, delivery gate flips on commit)

6/6 tasks `[x]`. SHIPPED a per-command macOS seatbelt (`/usr/bin/sandbox-exec`) layer BELOW the Ph111 string-gate, at the bash EXECUTION site for BOTH adapters via ONE chokepoint — NEW module `app/src/gate/sandbox/{seatbelt.ts,approved-writes.ts}`. **T1 spike proved A1 (inheritance) / A4 (Pi seam binds + gate sees original) / A5 (strict viable) HELD; A2 BIT-partially** (cache denials → integrity caches). C1-PRESERVE wired via per-command `extraWrites`; verdict-loop core UNCHANGED; NO `types.ts` change.

**Corrections vs plan:** the Pi seam is `createAgentSession({ customTools: [createBashToolDefinition(cwd, { spawnHook })] })`, **NOT `baseToolsOverride`** (which is on the low-level `AgentSession` ctor + replaces the whole base set); the synchronous `spawnHook` is downstream of `pi.on('tool_call')` so the gate sees the ORIGINAL command (P6 source-trace + live probe). strict DROPS the unix-socket allowance (loopback-IP only). `/usr/bin/sandbox-exec` absolute path. `canonicalizePath` = `basename(abs)` + `assertSafeProfilePath` rejects `/`.

**Adversarial review** (6 finders×2 refuters, real `sandbox-exec` PoCs): 2 CONFIRMED bugs (canonicalize off-by-one `/w`→`/` whole-FS grant; subpath-`/` over-grant) that 264 passing tests MISSED + 3 hardenings (PATH-shadow, strict unix-socket exfil, hardlink) → all fixed, +10 regression tests. Health: app suite 201→274 (+73); tsc + `npm run build` + `cargo check` all exit 0; all live e2e green under the sandbox.

**Residuals → Phase 113:** cross-platform sandbox (Linux landlock/bwrap + Windows job-objects); confidentiality + daemon residuals (full READ open, `defaults`/`launchctl` escape, loopback local-service); Vercel bash output redaction+cap (pre-existing asymmetry vs Pi); `sandbox-exec` deprecation durability; carried — signed/notarized bundle + A3 keyring + rollback, command palette, Claude SDK adapter, live window-drive. Decision [[os-sandbox-bash-fs-isolation]] (high).
