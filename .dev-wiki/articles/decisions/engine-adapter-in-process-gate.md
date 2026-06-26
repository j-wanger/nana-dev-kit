---
title: "Embed the agent engine in-process behind an app-owned adapter; the security gate lives at the tool-call site"
aliases: [engine-adapter-in-process-gate, in-process-gate, engine-adapter, app-owned-adapter, gui-harness-engine]
category: decisions
tags: [gui-harness, engine-adapter, security-gate, tool-call-interception, pi-sdk, claude-agent-sdk, vercel-ai-sdk, tauri, acp, in-process, phase-108]
parents: [phase-108-gui-harness-v1-thin-slice]
created: 2026-06-26
updated: 2026-06-26
source: plan
confidence: high
---

## Context

The kit is re-platforming from a terminal/skill harness into a GUI-primary, model-agnostic desktop dev harness (spec `specs/gui-harness-architecture.md`, nana:approved 2026-06-26, Rev 2). The load-bearing architectural question: **what is the swappable model boundary, and where does the security gate live?**

The kit's posture is *deterministic validators at boundaries* — for an agent harness the highest-value boundary is a **pre-execution gate**: deny or modify a destructive tool call (e.g. `bash rm`) BEFORE its side effects land. The design pressure was to make that boundary an external wire protocol or server so the engine could be swapped freely. Primary sources were checked (2026-06) to test whether any standard external boundary can actually own that gate.

## Decision

**Embed a model-agnostic agent engine IN-PROCESS behind an app-owned `EngineAdapter` interface; the security gate runs in-process at the tool-call site.** The "swappable boundary" is an **internal adapter interface the app owns** (≥2 implementations), NOT a wire protocol or external server.

- **Primary engine = Pi SDK** (`@earendil-works/pi-coding-agent`), gate via its `tool_call` hook (deny `{block:true}`, modify `event.input`, schema-reject malformed args).
- **Second adapter = Claude Agent SDK** (`canUseTool`) — proves engine-neutrality (one gate path, two engines).
- **Fallback = Vercel AI SDK** (build-the-loop) — kept only as the deeper escape hatch; do not rebuild commodity plumbing.

Verified against primary sources, each killing an external-boundary alternative:
- **ACP-as-boundary — rejected:** ACP permission is agent-discretion ("MAY", no enforcement); agents do local I/O outside the protocol, so the host cannot guarantee pre-execution interception.
- **opencode-HTTP-server-primary — rejected:** the agent loop runs in opencode's process; the gate would be opencode's, not the host's.
- **Goose-daemon / Paseo-supervisor — rejected:** each runs the agent in its own process and only relays its permission prompts (Paseo also AGPL-3.0); no host-owned gate.
- **Build-the-loop-from-scratch on Vercel AI SDK — kept as fallback only:** rebuilds commodity agent-loop plumbing the amplifier-null family says is low-value floor (+0.25); adopt an engine, don't build the loop.

Shell = Tauri (Rust); keychain via keyring-rs + an audited capability manifest. Surface = assistant-ui (custom runtime → the adapter) + Vercel AI Elements dev components. The Python MCP memory server ports as-is via MCP stdio.

## Consequences

- **A host can only own a pre-execution gate if the agent loop runs in the host's own process** — this is the architectural invariant the whole v1 thin slice (Phase 108) is built around; security/gate is built FIRST (T2 key-store deny, T3 in-process tool_call gate + bypass-resistance).
- The boundary is now an app-maintained interface, not a third-party contract: every new engine costs one adapter, but the gate logic is written ONCE and reused (T7 proves a second engine reuses it; T8 normalizes per-adapter tool calls to one internal representation feeding the single gate chokepoint).
- **Un-bypassability is empirical, not assumed** ([[HEU-012]] — verify by firing): the Pi `tool_call` hook's interception is an architectural INFERENCE, not a vendor security guarantee. T3 is the make-or-break spike (a same-name custom tool shadowing a built-in, and an unregistered tool, must not suppress the host gate). If it fails empirically → STOP-and-escalate: swap primary to the Claude Agent SDK (vendor-guaranteed `canUseTool`) or build-the-loop on Vercel AI SDK, behind the same adapter interface (ledger A1).
- **Open-core risk on Pi (ledger A4):** Earendil is VC-backed; RFC-0015 reserves future Fair Source/proprietary layers. Mitigation = pin a Pi version; the engine-neutral adapter is itself the escape hatch (switch the primary adapter, or pin-and-fork the last MIT core).
- Key custody is a deferred don't-know (ledger A3, revisit-status: open): keyring-rs+Tauri+agent-deny on macOS is unproven; T2 spikes it EARLY before the key rail is built on it. If it fails → a separate non-agent-reachable credential helper, NEVER plaintext.
- UI/felt quality stays UNMEASURABLE in-kit (Ph59/80 carve-out) — ships on the maintainer's judgment at the delivery gate; tests assert MECHANICS only (the security rails are exit-criteria tests, not claims).

## Spec

`specs/gui-harness-architecture.md` (nana:approved 2026-06-26, Rev 2). Ledger Phase-108 (all_accept:false — A3 keyring-rs deferred don't-know; A1/A2/A4 accept).
