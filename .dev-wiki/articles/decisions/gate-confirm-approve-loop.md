---
title: "Real human-confirm approve-loop via a host-owned ConfirmationBroker + a confirmingGate on the existing setToolCallGate seam"
aliases: [gate-confirm-approve-loop, confirming-gate, confirmation-broker, approve-loop]
category: decisions
tags: [gui-harness, security, gate, confirming-gate, confirmation-broker, checkpoint, revert, phase-109]
parents: [phase-109-felt-quality-surface]
created: 2026-06-26
updated: 2026-06-26
source: debrief
confidence: high
---

## Context

Phase 108's security gate only ever **auto-denied** destructive actions. The gate could return a deny carrying the reason "requires explicit human confirmation," but there was **no resolution path** — a held call never reached a human, so the "confirm before it lands" affordance (axis 1, preview-and-approve) was aspirational. Phase 109's whole felt-quality thesis is making the security rails *felt*; an approve-loop that can't actually surface a held call to the UI and resolve on a verdict is the load-bearing missing piece. Constraint #4 of the plan said "gate logic UNCHANGED — UI wires to surface events only," but the gate had no surface event to wire to.

## Decision

**A host-owned `ConfirmationBroker` + a `confirmingGate` injected through the EXISTING `setToolCallGate` seam — additive host wiring, gate CORE unchanged.** Constraint #4 relaxed (maintainer-approved): "UI-only" → "UI + host broker; gate CORE / checkpoint / engine unchanged."

- `confirmingGate` wraps the base host-gate. A **confirmable** deny becomes an unresolved `Promise<GateDecision>` — a shape that is **already legal and already awaited by every adapter** (so no adapter change). The pending promise is parked in a `ConfirmationBroker` that surfaces it (the action + a computed diff) to the UI and resolves it on the human verdict: approve → `allow` (the side effect proceeds), deny → `deny` (no side effect). Allow/deny only in v1 — no modify/edit (the per-engine asymmetry).
- **SECURITY-CRITICAL invariant:** only the **literal marker** "requires explicit human confirmation" is confirmable. Secret/key-store reads/writes deny with *different* reasons ("is denied" / "path denied") and stay **HARD-denied** — never surfaced for approval. Matched as an exact string and **tested against the REAL gate** (not a mock), so a marker drift can't silently turn a hard-deny into an approvable action.
- **snapshot-on-approve** wires `CheckpointStore` (Ph108-tested) at the approval moment, so an approved mutation is one-action revertible (axis 2). `CheckpointStore` had been an unwired library; the approve point is the natural dispatch moment to snapshot.
- Files: `src/gate/confirm/{broker,confirming-gate,diff}.ts`. Composes with the turn `AbortSignal` so a cancel rejects any outstanding broker promise.

## Alternatives considered

- **Pure-UI dialog reading existing gate events (the original plan, rejected):** there were no held-call events to read — the gate auto-denied with no parked promise. A UI-only approach had nothing to subscribe to.
- **Make every deny confirmable (rejected — unsafe):** would surface secret/key-store denials for human approval, defeating the hard-deny rail. The literal-marker allowlist keeps the security-critical denials non-negotiable.
- **Modify/edit verdicts in v1 (deferred):** the per-engine asymmetry (Pi mutates `event.input`, Vercel doesn't) makes a uniform modify path non-trivial; allow/deny is the minimum that makes axis 1 real.

## Consequences

- Axis 1 (preview-and-approve) is now real: a held destructive call blocks, surfaces to the UI with a diff, and proceeds or aborts on the human verdict.
- The security boundary is **tightened, not loosened** — the confirmable set is a literal-marker allowlist verified against the real gate; key-store/secret denials remain hard.
- The broker is engine-neutral and host-side; the bridge sidecar ([[webview-engine-bridge]]) composes it, so both the Pi and Vercel adapters honor the held promise unchanged.
- Axis 2 (one-action revert) is unblocked via snapshot-on-approve.

## Source

Phase 109 debrief (2026-06-26). Discovered refinement of plan constraint #4, maintainer-approved (real-approve-loop). Built on [[engine-adapter-in-process-gate]] (the host gate + `setToolCallGate` seam + `CheckpointStore`). Sibling: [[webview-engine-bridge]] (the sidecar that hosts the broker). Memory: the security marker invariant is stored as a `harvest-constraint`.
