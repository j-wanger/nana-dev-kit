import type { EngineAdapter } from '../engine/adapter';
import type { EngineEvent, ToolCallGate, NormalizedToolCall } from '../engine/types';
import { ConfirmationBroker } from '../gate/confirm/broker';
import { createConfirmingGate } from '../gate/confirm/confirming-gate';
import { bashOutOfWorkspaceWriteTargets } from '../gate/host-gate';
import { recordApprovedWrites } from '../gate/sandbox/approved-writes';
import { assembleContext } from '../context/assembly';

// The Node engine-HOST (Phase 109, T6). It runs in the Node layer (NOT the
// webview) and composes the whole daily loop behind a line-oriented JSON
// protocol: context-assembly (A2) + the EngineAdapter + the confirming-gate
// (axis 1) + the confirmation broker + revert (axis 2). The Tauri Rust shell
// spawns it and proxies this protocol to/from the webview; the webview's
// BridgeAdapter speaks it via Tauri invoke + events. This class is transport-
// agnostic (it takes a `send` callback and is fed inbound messages), so it is
// fully unit-testable without a process, a window, or a live model.

/** Webview -> host. */
export type HostInbound =
  | { type: 'prompt'; turnId: string; text: string }
  | { type: 'gate-verdict'; callId: string; approved: boolean }
  | { type: 'revert'; path: string }
  | { type: 'interrupt'; turnId: string };

/** Host -> webview. */
export type HostOutbound =
  | { type: 'ready' }
  | { type: 'engine-event'; turnId: string; event: EngineEvent }
  | { type: 'gate-pending'; callId: string; toolName: string; diff: string; summary: string; path?: string }
  | { type: 'revert-result'; path: string; ok: boolean; error?: string }
  | { type: 'error'; message: string };

export interface EngineHostDeps {
  adapter: EngineAdapter;
  workspaceRoot: string;
  /** The base host policy (createHostGate); the host wraps it in the confirming-gate. */
  baseGate: ToolCallGate;
  /** Emit one outbound message (the transport writes it as a stdout line / Tauri event). */
  send: (msg: HostOutbound) => void;
  /** T4: snapshot a path's pre-mutation bytes when an approved write/edit is about to land. */
  snapshot?: (path: string) => void;
  /** T4: one-action revert to pre-edit bytes (CheckpointStore.revert). */
  revert?: (path: string) => void;
  /** Injectable for tests; defaults to the real workspace assembler (A2). */
  assemble?: (root: string) => { systemContext: string };
}

export class EngineHost {
  private readonly broker = new ConfirmationBroker();
  private readonly gate: ToolCallGate;
  private readonly turns = new Map<string, AbortController>();

  constructor(private readonly deps: EngineHostDeps) {
    this.gate = createConfirmingGate(deps.baseGate, this.broker, {
      onApprove: (call: NormalizedToolCall) => {
        // Snapshot a write/edit's target BEFORE it lands, so the approved
        // mutation is one-action revertible (axis 2). Bash/other tools have no
        // single target path here.
        const path = typeof call.args.path === 'string' ? call.args.path : undefined;
        if (path) this.deps.snapshot?.(path);
        // Phase 112 C1-preserve: an APPROVED out-of-workspace bash write must
        // also be permitted by the OS sandbox for this one command — record its
        // target(s) so the bash executor folds them into the per-command profile.
        if (call.name === 'bash' && typeof call.args.command === 'string') {
          recordApprovedWrites(
            call.args.command,
            bashOutOfWorkspaceWriteTargets(call.args.command, this.deps.workspaceRoot),
          );
        }
      },
    });
    deps.adapter.setToolCallGate(this.gate);
    // A held destructive call surfaces to the UI (axis 1 — preview & approve).
    this.broker.onPending((p) =>
      deps.send({
        type: 'gate-pending',
        callId: p.callId,
        toolName: p.toolName,
        diff: p.diff,
        summary: p.summary,
        path: p.path,
      }),
    );
  }

  /** Process one inbound message. */
  async handle(msg: HostInbound): Promise<void> {
    switch (msg.type) {
      case 'prompt':
        return this.runTurn(msg.turnId, msg.text);
      case 'gate-verdict':
        this.broker.resolve(msg.callId, msg.approved);
        return;
      case 'revert':
        return this.doRevert(msg.path);
      case 'interrupt':
        this.turns.get(msg.turnId)?.abort();
        // A held gate await must not outlive a cancelled turn.
        this.broker.rejectAll();
        return;
    }
  }

  private async runTurn(turnId: string, text: string): Promise<void> {
    const ac = new AbortController();
    this.turns.set(turnId, ac);
    const assemble = this.deps.assemble ?? assembleContext;
    const { systemContext } = assemble(this.deps.workspaceRoot);
    try {
      for await (const event of this.deps.adapter.sendPrompt(text, {
        signal: ac.signal,
        systemContext,
      })) {
        this.deps.send({ type: 'engine-event', turnId, event });
        if (event.type === 'done' || event.type === 'error') break;
      }
    } catch (e) {
      this.deps.send({
        type: 'engine-event',
        turnId,
        event: { type: 'error', error: e instanceof Error ? e.message : String(e) },
      });
    } finally {
      this.turns.delete(turnId);
    }
  }

  private doRevert(path: string): void {
    try {
      if (!this.deps.revert) throw new Error('revert not wired');
      this.deps.revert(path);
      this.deps.send({ type: 'revert-result', path, ok: true });
    } catch (e) {
      this.deps.send({
        type: 'revert-result',
        path,
        ok: false,
        error: e instanceof Error ? e.message : String(e),
      });
    }
  }
}
