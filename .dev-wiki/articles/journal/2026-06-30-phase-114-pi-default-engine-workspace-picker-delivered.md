---
title: "Phase 114 delivered — Pi as the default engine + Rust-atomic workspace picker"
date: 2026-06-30
type: journal
phase: 114
tags: [phase-114, pi-default-engine, gui-harness, workspace-picker, tauri, security, host-gate, adversarial-review, delivered]
---

# Phase 114 delivered — Pi default engine (good tools) + workspace picker

## Summary

Resumed at T3 (T1/T2 — flip the default to Pi + harden — were already done, uncommitted) and carried the phase to BUILT + delivered. The dogfood "the tools are awful" complaint was root-caused (a prior session) as an **accidental default**: the embedded agent ran on the Vercel adapter (uncapped bash + whole-file write) only because of a Ph109 bring-up artifact (`main.ts:20 NANA_ENGINE ?? 'vercel'`) — the spec names Pi primary, and Pi already ships the rich capped/paginated suite the gate already covers. So "good tools" = **make Pi the default**, not build a suite for Vercel. This session built the **Rust-atomic workspace picker** (T3–T5) and ran the full gate + adversarial review (T6).

App suite **343/343**, `npm run build` + `cargo check` exit 0. The live Pi e2e + gate-deny tests ran green (localhost:8080 was up).

## What changed

- **T3 — workspace picker.** `pick_workspace` (Rust) opens the native folder dialog via `tauri-plugin-dialog` 2.7.1 (`blocking_pick_folder`, async command off the main thread). **DISCOVERY (verified, not guessed — v2.tauri.app + docs.rs):** the renderer gets **no dialog capability at all** — tighter than the planned "dialog-only grant". App-defined commands are default-allowed for webviews, and a Rust-side plugin call bypasses the webview ACL, so opening the dialog from Rust means the renderer can neither open a dialog nor supply a path. `default.json` stays `core:default` (inert-render audit green).
- **T4 — re-spawn lifecycle.** `BridgeClient.changeWorkspace()` tears down the dead sidecar's in-flight turns + revert waiters and resolves on the fresh `ready`; Rust kills + respawns the sidecar with `NANA_WORKSPACE=chosen` (a fresh process ⇒ fresh `createHostGate(root)` + fresh approved-writes Map). `spawn_engine_host` refactored into `host_script()` + `spawn_sidecar()`. Native round-trip is live-drive-only (cargo check = compile).
- **T5 — UI surface.** Widened the host `ready` to carry `workspaceRoot` + `available` + `sources` (NOT the `systemContext` contents). Header shows the active workspace + **project-blind** state (`WorkspaceIndicator` + `useWorkspace`); "Change workspace…" palette command dispatches through a `ctx.changeWorkspace` callback (no new privileged path).
- **T6 — gate + adversarial review.** See below.

## Problems & solutions (T6 adversarial review)

3 parallel finders (gate-root relocation / gate-coverage+redact / bridge-respawn correctness); **every finding verified against the code by the orchestrator** (subagent prose = candidate-only, per the in-kit leak discipline). **6 confirmed, all fixed:**

- **HIGH — secret-deny was ancestor-blind.** The Ph114-activated grep/find/ls *recurse* (ripgrep/fd `--hidden`) and — unlike bash — are NOT seatbelt-confined. `isDeniedPath` matched only the secret *or descendants*, so `grep ~` / `ls ~/.aws` (the `.aws` directory is an *ancestor* of the denied `credentials` file) read secrets the gate didn't deny. **The activation was the exposure.** Fix: `pathReachesDeniedPath` (ancestor-aware) on the grep/find/glob/ls gate case, checking `args.path ?? workspaceRoot`. New ancestor-deny tests.
- **MED** zombie child (`kill()` без `wait()`) → reap off-thread. **MED** re-entrant `changeWorkspace` clobbered the single `readyWaiter` → `changing` guard. **LOW** non-atomic stdin/child swap → hold the stdin lock across both swaps. **LOW** relative-path cwd divergence after respawn → `spawn_sidecar` sets `current_dir(ws)`. **LOW** unhandled rejection in App's dispatch → `.catch`.

The HIGH finding is the headline: a passing 341-green TDD suite asserts your design; the adversarial review attacks the threat model. 4th confirmation (Ph110/111/112/114) that a finder×refuter review earns its keep on security-boundary changes.

## Health delta

App test count 318 (phase entry) → **343** (+25 across the phase: pi-tools, engine-default, host-gate-search-tools incl. the new ancestor cases, workspace-picker, workspace-change, workspace-surface). tsc 0, cargo check 0, vite build clean. No regression on the gate/inert/redact/visibility rails (99/99).

## Review Gate

Adversarial pre-commit review (above) served as the size-gated review for this Standard phase. 6 confirmed findings fixed inline (SECURITY/DISCOVERY escape hatches).

## Gate Compliance

direction=confirmed (2026-06-30, ledger Phase-114 all_accept A1–A4); delivery=accepted at this debrief. Spec gate satisfied by the ADR-named umbrella `specs/gui-harness-architecture.md`.

## Assumption-Ledger Revisit

A1 **held** (T1 make-or-break passed). **A2 BIT** — the activated recursive grep/find/ls reached secrets via an ancestor root the secret-deny missed; a *new* secret-read hole beyond the general read residual A2 assumed, found+fixed at T6. A3 **held** (config threads). A4 **held** (Rust-atomic worked, tighter than planned). The A2 bite is exactly the detect-after backstop working — a security assumption that read as safe at planning time was disproven by the adversarial review.

## Soft Observations / Phase 115 Candidates

- **#2 conversation memory (the planned Ph115 headline).** The harness has no cross-turn conversation memory yet; this is the next dogfood gap.
- **Renderer-trust hardening (NEW, from the T6 review — pre-existing Ph108/109 gap).** Under "the renderer is potentially-compromised," a compromised renderer can auto-approve a held gate via `engine_send({type:'gate-verdict', approved:true})` (the host trusts the renderer's verdict) and can pop unsolicited native folder dialogs. Neither relocates the gate root, but both undercut the picker's careful guarantee. Candidate: a non-renderer authorization gesture for host-side verdicts. Evidence: finder A's out-of-scope note.
- **Blocking out-of-workspace READ (the standing Ph112 confidentiality residual).** This phase tightened the *secret* class (grep/find/ls can't reach ~/.ssh/~/.aws/keychain); general out-of-ws read is still open. A confidentiality phase could close it.
- **The live window-drive is deferred a 5th time.** Every felt-quality + native-dialog-round-trip claim still rides the maintainer's drive; the picker's runtime is unverified end-to-end. Worth a dedicated drive session before piling on more surface.
