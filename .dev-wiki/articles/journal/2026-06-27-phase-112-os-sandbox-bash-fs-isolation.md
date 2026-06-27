---
title: "Phase 112 — OS-sandbox bash filesystem isolation: BUILT + adversarially reviewed (6/6 tasks, READY FOR COMPLETION)"
aliases: []
category: journal
tags: [security, gate, host-gate, bash, sandbox, seatbelt, sandbox-exec, engine-adapter, pi-sdk, phase-112]
parents: [phase-112-os-sandbox-bash-fs-isolation]
created: 2026-06-27
updated: 2026-06-27
source: debrief
duration: unknown
---

# Phase 112 — OS-sandbox bash filesystem isolation: BUILT + adversarially reviewed

## What Happened

The named follow-on of [[host-gate-out-of-workspace-hardening]] — it closes the documented Ph111 residual: string-gating arbitrary bash is INCOMPLETE BY NATURE (`python3 -c` / `node -e` / `base64 -d` / env indirection evade a literal-text pattern). Planned + implemented + adversarially reviewed in one session; 6/6 tasks `[x]`.

Shipped a **per-command macOS seatbelt (`/usr/bin/sandbox-exec`) enforcement layer BELOW the Ph111 string-gate**, at the bash EXECUTION site for BOTH adapters through ONE chokepoint. NEW module `app/src/gate/sandbox/` — `seatbelt.ts` (profile builder `buildProfile` strict+integrity, `$TMPDIR` pinned from the TRUSTED host env, `escapeSBPL`+char-reject, `wrapBashArgv` argv-form, `runSandboxedBash` single chokepoint, `isSandboxAvailable` cached) + `approved-writes.ts` (the C1 per-command registry). Bash execution now routes through the chokepoint on darwin for both adapters; no-op off-darwin (the Ph111 string-gate remains). **NO `types.ts` / engine-contract change** — the wrap is at the execution site, not the gate contract.

**T1 (the front-loaded de-risking spike, 49 tests) PROVED A1/A4/A5 HELD:** 18 evasion vectors blocked at the syscall layer, confinement INHERITS transitively to subprocesses (python/node/base64/env-indirection children), STRICT is viable for a basic shell + DNS (only 2 mach names needed). The `defaults write` positive-control ESCAPED (the documented residual — confirms the test can see an escape). **A2 BIT-partially:** npm/pip/cargo caches were denied at first → fixed by allowing `~/.npm`/`~/.cache`/`~/.cargo` in the `integrity` profile (A2 "minimal caches" wording); in `strict` they stay denied by design.

T2 wired Pi (`customTools` + `spawnHook`), T3 wired Vercel (`runBash`), T4 the C1-preserve approved-writes channel, T5 the no-bypass invariant + non-darwin fallback + SBPL-injection hardening, T6 the integration e2e + adversarial review + full gate.

## Decisions Made

- [[os-sandbox-bash-fs-isolation]] (high, EXISTS — Consequences updated with what shipped + the corrections): per-command seatbelt below the string-gate, one chokepoint, both adapters, engine-neutral, verdict-loop core unchanged.

## Problems Solved

- **The Pi seam was misidentified at plan time.** The plan assumed `baseToolsOverride`; the T1/P6 source-trace + live probe found the real seam is `createAgentSession({ customTools: [createBashToolDefinition(cwd, { spawnHook })] })`. `baseToolsOverride` is on the low-level `AgentSession` ctor and replaces the WHOLE base toolset. The synchronous `spawnHook` is DOWNSTREAM of `pi.on('tool_call')`, so the gate + Ph110/111 visibility provably see the ORIGINAL command, not the `sandbox-exec` wrapper. (DISCOVERY escape hatch — corrected before integration.)
- **Two REAL security bugs the 264 passing tests MISSED, caught by the adversarial PoC review** (SECURITY escape hatch, fixed inline): (1) `canonicalizePath` off-by-one mapped `/w`→`/` = a whole-filesystem write grant → fixed with `basename(abs)` + `assertSafeProfilePath` rejecting `/`; (2) a `(subpath "/")` over-grant → reject `/`. Plus 3 dismissed-but-hardened: PATH-shadow (`/usr/bin/sandbox-exec` absolute path), the strict unix-socket Docker-daemon-socket exfil + DNS-leak (DROPPED unix-socket from strict, loopback-IP only), hardlink (seatbelt blocks the `ln`). +10 regression tests.
- **C1-PRESERVE wired** without touching the verdict-loop core: approval threads the target into per-command `extraWrites` (consume-once, command-keyed; engine-host `onApprove` records, the executor consumes). Out-of-workspace bash writes stay confirmable → approve-then-succeed, OS-enforced.

## Open Questions

- None unresolved. The T1 spike resolved A1/A4/A5; the three judgment calls (strict-drops-unix-socket, integrity-allows-caches, default strict) were made and flagged to the maintainer in the delivery report.

## Artifacts Changed

- `app/src/gate/sandbox/seatbelt.ts` + `approved-writes.ts` (NEW module — profile builder + chokepoint + C1 registry)
- `app/src/engine/pi/pi-adapter.ts` (Pi `customTools` + `spawnHook` substitution)
- `app/src/engine/vercel/vercel-adapter.ts` (`runBash` through the chokepoint)
- `app/src/gate/host-gate.ts` (exported `bashOutOfWorkspaceWriteTargets` + extracted `isOutsidePath`)
- `app/src/host/engine-host.ts` (`onApprove` records approved out-of-ws bash writes)
- `app/tests/sandbox/seatbelt-spike.test.ts` (49) + `adapters/{pi-sandbox,vercel-sandbox}.test.ts` (6+2) + `gate/{sandbox-approved-writes,sandbox-no-bypass}.test.ts` (8+8)

## Related

- [[phase-112-os-sandbox-bash-fs-isolation|Phase 112 — OS-sandbox bash filesystem isolation]] -- parent phase
- [[host-gate-out-of-workspace-hardening]] -- the Ph111 hardening this completes
- [[engine-adapter-in-process-gate]] -- per-command TS keeps it engine-neutral
- [[gate-confirm-approve-loop]] -- the verdict-loop core left UNCHANGED

## Soft Observations / Phase 113 Candidates

- The adversarial pre-commit review (6 finders×2 refuters running real `sandbox-exec` PoCs) caught 2 REAL bugs (canonicalize off-by-one whole-FS grant; subpath-`/` over-grant) that 264 passing tests MISSED — reaffirms + extends the Ph110/111 "adversarial-review-on-security-boundary-phases" discipline; the **empirical-PoC finder (run the attack, not speculate) is the high-signal variant**. | Phase 113: keep the empirical-PoC adversarial review for any future gate/sandbox change. | this journal + [[os-sandbox-bash-fs-isolation]] Outcome.
- Vercel bash output is un-redacted/uncapped (a pre-existing asymmetry vs Pi's `extractToolText` redact+cap). | Phase 113: align the adapters' output rail (redact + cap Vercel bash output). | active-phase.md scope OUT.
- Cross-platform (Linux/Windows) + confidentiality (deny-read) + daemon-residual closure need a stronger isolation primitive (container/VM). | Phase 113: the natural direction if the threat model expands beyond write-integrity-on-darwin. | [[os-sandbox-bash-fs-isolation]] HONEST RESIDUALS.

### Retro Check (Phases 108-112)

| Dimension | Findings | Signal |
|-----------|----------|--------|
| 1. Recurring Blockers | 0 | none |
| 2. Decision Reversals | 0 | none |
| 3. User Corrections | 2 (A3 C1-preserve, A5 strict — at the direction gate, the gate working as intended) | low |

Recommendations:
- No systemic issue. The two user corrections are direction-gate reframes (C1-preserve over C1-drop; strict over integrity-only) — the assumption gate working as designed, not a reliability gap. Carry the empirical-PoC adversarial review forward as standing discipline for security-boundary phases (it has now caught real bugs in Ph110, Ph111, and Ph112 that the passing test suites missed).
