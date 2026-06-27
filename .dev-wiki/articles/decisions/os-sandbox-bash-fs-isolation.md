---
title: "OS-sandbox bash filesystem isolation (seatbelt, per-command, below the string-gate)"
aliases: [os-sandbox-bash-fs-isolation, seatbelt-bash-isolation, sandbox-exec-bash, bash-fs-sandbox, per-command-seatbelt]
category: decisions
tags: [security, gate, host-gate, bash, sandbox, seatbelt, sandbox-exec, engine-adapter, pi-sdk, tauri, phase-112]
parents: [phase-112-os-sandbox-bash-fs-isolation]
created: 2026-06-27
updated: 2026-06-27
source: plan
confidence: high
---

## Context

Phase 111 closed the demonstrated host-gate out-of-workspace vectors by string-gating bash write targets, but documented an HONEST RESIDUAL the maintainer accepted as ship-blocking-for-a-follow-on: **string-gating arbitrary bash is INCOMPLETE BY NATURE.** `python3 -c 'open("/outside","w")'`, `node -e fs.writeFileSync`, `base64 -d > /outside`, and `$VAR`-path env indirection all evade a pattern that can only read the literal command text ([[host-gate-out-of-workspace-hardening]] explicitly names OS-sandboxing bash's filesystem as the COMPLETE fix). The Ph111 gate is a deny/confirm DECISION at the tool-call site; it cannot constrain what the spawned shell does after the decision.

The complete fix is an OS-level enforcement layer BELOW the string-gate: confine the bash tool's filesystem WRITES to the workspace at the kernel boundary, where the interpreter the command launches cannot argue its way out. macOS ships `sandbox-exec` (seatbelt / SBPL), verified functional on the dev box. Pi (primary) runs bash INSIDE the SDK (no spawn in our code) but v0.80.2 EXPORTS clean seams (`createAgentSession({ baseToolsOverride })` — "override base tools, for custom runtimes" — plus `BashSpawnHook` / `BashOperations`), so we can substitute a sandbox-wrapped bash WITHOUT forking Pi. Vercel's bash is our own `execSync` (`vercel-adapter.ts:54`) — wrapped directly. Both adapters funnel through ONE guarded chokepoint.

## Decision

Add a **per-command OS-sandbox enforcement layer below the Ph111 string-gate**, macOS-first (seatbelt via `sandbox-exec`), attached at the bash EXECUTION site for BOTH adapters through a single TS chokepoint. A new pure module `app/src/gate/sandbox/seatbelt.ts`:
- `isSandboxAvailable()` — darwin + `sandbox-exec` present, cached;
- `escapeSBPL()` / reject SBPL-significant chars — injection hardening for workspace + model-controlled approved-target paths;
- `buildProfile({ wsRoot, tmpDir, extraWrites, mode })` — `$TMPDIR` PINNED from the TRUSTED host env (NOT the child command env); `strict` = deny file-write outside `{ws, tmp, sinks, extraWrites}` + deny network + deny `mach-lookup` except an empirically-determined minimal allowlist; `integrity` = deny file-write only (kept as the tested fallback);
- `wrapBashArgv(cmd, profile)` → argv `['sandbox-exec','-p',profile,'/bin/bash','-c',cmd]` (argv form avoids re-quoting);
- `runSandboxedBash(...)` — the SINGLE chokepoint both adapters funnel through.

No `types.ts` change — the wrap is at the execution site, not the gate contract. The gate VERDICT-LOOP core (`confirmingGate` / `ConfirmationBroker` / key-store hard-deny — [[gate-confirm-approve-loop]]) stays UNCHANGED. Per-command TS (not a process-wide Rust sidecar) keeps it engine-neutral, honoring [[engine-adapter-in-process-gate]].

### Locked assumption positions (assumption-ledger Phase-112; these shape the build)
- **A1 — accept, spike-gated.** Seatbelt write-deny INHERITS to subprocesses (the python/node child a command spawns is confined too). T1 PROVES it first; STOP-and-escalate if it doesn't.
- **A2 — accept.** Default-deny-write won't break legitimate work — but in tension with A5; T1 determines the minimal mach/network allowlist for a functional shell + DNS.
- **A3 — C1-PRESERVE (maintainer rejected the C1-drop framing).** Confirmable out-of-workspace bash writes STAY: on approval the target threads into `extraWrites`, so the per-command profile expands → approve-then-succeed, OS-enforced, platform-consistent. Needs a gate→executor approved-targets channel.
- **A4 — accept, spike-gated.** Pi `baseToolsOverride` binds in practice AND the `tool_call` gate still sees the ORIGINAL command (not the wrapper). Fallbacks: `BashSpawnHook` → `BashOperations` → gate-modify.
- **A5 — STRICT (maintainer chose strict over integrity-only).** Also tighten network + mach. STOP-escalate to integrity-only if T1 shows strict unusable for normal dev work.

### Alternatives considered + rejected
- **Process-wide Rust sidecar sandbox** — confines the host's OWN infra writes (MCP memory server, logs) and is coarse; rejected for per-command TS.
- **Gate modify-path command rewrite** — leaks the `sandbox-exec` wrapper into the tool-call surface + quoting fragility; rejected (A4 — routing/wrapping stays out of the gate contract).
- **C1-drop** (hard-deny out-of-workspace bash, no approve path) — capability regression + platform inconsistency vs the write/edit confirmable policy; maintainer rejected (A3 = C1-preserve).
- **integrity-only** (write-confine, leave network/mach open) — kept as the TESTED FALLBACK, not the target; maintainer chose strict (A5).

## Consequences

- A new pure module `app/src/gate/sandbox/` + a new `app/tests/sandbox/**` execute-under-profile test class (skip-LOUDLY off-darwin, the live-e2e pattern).
- A gate→executor **approved-targets channel** (keyed by toolCallId/command) so an approved out-of-workspace write expands that command's profile (C1-preserve) — the only new gate-adjacent surface; the verdict-loop core is untouched.
- **HONEST RESIDUALS (carry forward — do NOT over-claim "residual closed"):** exit criteria say "DIRECT bash file-writes confined on darwin", not "the residual is closed." Daemon/XPC-mediated writes (`defaults write` / `launchctl` / `osascript`) and full filesystem READ (local-file disclosure) remain even in strict mode; `sandbox-exec` is Apple-deprecated-but-functional (durability caveat, Chromium-seatbelt precedent); non-darwin has Ph111 string-gating ONLY (Linux landlock/bwrap, Windows job objects are OUT → documented residual); the allowlist can't enumerate every tool cache (tune as dogfooding surfaces breaks).
- **T1 is the de-risking gate.** If inheritance fails OR the Pi seam isn't substitutable through the fallbacks OR strict mode is unusable for a basic shell → STOP-and-escalate (pivot / fall back to integrity-only), do not build on a false foundation.
- Untrusted model-controlled paths reach SBPL → `escapeSBPL` + char-rejection is load-bearing (an unescaped path could break or inject the profile).

## Outcome (BUILT + adversarially reviewed 2026-06-27 — READY FOR COMPLETION)

SHIPPED a per-command macOS seatbelt (`/usr/bin/sandbox-exec`) layer BELOW the Ph111 string-gate, at the bash EXECUTION site for BOTH adapters through ONE chokepoint (`app/src/gate/sandbox/seatbelt.ts` profile builder + chokepoint; `approved-writes.ts` C1 registry). T1 spike PROVED **A1 (inheritance) / A4 (Pi seam binds + gate sees original) / A5 (strict viable, only 2 mach names needed) all HELD**; **A2 BIT-partially** — npm/pip/cargo caches were denied at first → fixed by allowing `~/.npm`/`~/.cache`/`~/.cargo` in the `integrity` profile per the A2 "minimal caches" wording (in `strict` they stay denied by design). C1-PRESERVE landed: approval threads the target into per-command `extraWrites` (consume-once, command-keyed; engine-host `onApprove` records, the executor consumes); the gate verdict-loop core stayed UNCHANGED.

**Corrections vs the plan (all fixed before commit):**
1. The Pi seam is `createAgentSession({ customTools: [createBashToolDefinition(cwd, { spawnHook })] })` — **NOT `baseToolsOverride`** (that's on the low-level `AgentSession` ctor and replaces the whole base toolset). The synchronous `spawnHook` is DOWNSTREAM of `pi.on('tool_call')`, so the gate + Ph110/111 visibility provably see the ORIGINAL command, not the `sandbox-exec` wrapper (P6 source-trace + live probe).
2. `strict` DROPS the unix-socket allowance (loopback-IP only) — closes a Docker-daemon-socket host-escape + a DNS-leak vector (adversarial review).
3. `/usr/bin/sandbox-exec` is invoked by ABSOLUTE path (PATH-shadow fix).
4. `canonicalizePath` uses `basename(abs)` + `assertSafeProfilePath` rejects `/` — an off-by-one had mapped `/w`→`/` = a whole-filesystem write grant (adversarial review, confirmed bug).
5. `(subpath "/")` over-grant rejected (adversarial review, confirmed bug).

**Adversarial pre-commit review** (6 finders × 2 refuters running real `sandbox-exec` PoCs + 1 re-run): 2 CONFIRMED bugs (the canonicalize off-by-one whole-FS grant; the subpath-`/` over-grant) that 264 passing tests MISSED + 3 dismissed-but-hardened (PATH-shadow; strict unix-socket exfil; hardlink) → all fixed, +10 regression tests. The empirical-PoC finder (run the attack, don't speculate) was the high-signal variant — keep it for any future gate/sandbox change.

**Health:** app suite 201 (Ph111 end) → **274** (+73: sandbox-spike 49, pi-sandbox 6, vercel-sandbox 2, sandbox-approved-writes 8, sandbox-no-bypass 8); `tsc` + `npm run build` + `cargo check` all exit 0; all live e2e green under the sandbox; no regressions.

**Residuals carried → Phase 113:** cross-platform sandbox (Linux landlock/bwrap + Windows job-objects); confidentiality + daemon residuals (full READ open, `defaults`/`launchctl` escape, loopback local-service); Vercel bash output redaction+cap (a PRE-EXISTING asymmetry vs Pi); `sandbox-exec` deprecation durability.

## Source

Phase 112 plan (2026-06-27). Direction confirmed at the assumption gate (ledger Phase-112 block: A1 accept-spike-gated, A2 accept, A3 C1-preserve [reject of C1-drop, resolved by revision], A4 accept-spike-gated, A5 strict [reject of integrity-only, resolved by revision]; all_accept:false). The named follow-on of [[host-gate-out-of-workspace-hardening]] (which names OS-sandboxing bash's fs as the complete fix). Per-command TS keeps it engine-neutral — [[engine-adapter-in-process-gate]]. C1-preserve resolves the sandbox-vs-confirm tension; the verdict-loop core stays unchanged — [[gate-confirm-approve-loop]].
