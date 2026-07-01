import type { EngineAdapter } from '../engine/adapter';
import type {
  EngineEvent,
  ToolCallGate,
  NormalizedToolCall,
  ModelInfo,
  ThinkingInfo,
  TemplateInfo,
  SkillInfo,
} from '../engine/types';
import { ConfirmationBroker } from '../gate/confirm/broker';
import { createConfirmingGate } from '../gate/confirm/confirming-gate';
import { bashOutOfWorkspaceWriteTargets } from '../gate/host-gate';
import { recordApprovedWrites } from '../gate/sandbox/approved-writes';
import { assembleContext, type ContextSource } from '../context/assembly';
import type { SpendCeiling } from '../control/spend';
import type { MemoryRetriever } from '../context/memory-context';

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
  | { type: 'interrupt'; turnId: string }
  // Phase 119 T1: reset the engine conversation (crash-isolation recovery / a
  // fresh thread). No-op on adapters without a persistent session.
  | { type: 'new-conversation' }
  // Phase 119 T2: manually compact the engine context. No-op on adapters without
  // a compactable session.
  | { type: 'compact' }
  // Phase 119 T4: model switcher. cycle-model rotates; set-model picks one; both
  // emit an updated `session-info`. request-session-info populates the chip.
  | { type: 'cycle-model' }
  | { type: 'set-model'; providerId: string; modelId: string }
  | { type: 'request-session-info' }
  // Phase 119 T5: thinking-level toggle. Both emit an updated `session-info`.
  | { type: 'cycle-thinking' }
  | { type: 'set-thinking'; level: string };

/** Host -> webview. */
export type HostOutbound =
  // `ready` carries the active workspace + the PROJECT-BLIND state (T5): which
  // project-instruction files were found (sources) and whether any were
  // (available). It deliberately does NOT carry the assembled `systemContext`
  // string — that holds the full AGENTS.md/CLAUDE.md/rules CONTENTS and must never
  // leak into the webview chrome; only the root + per-file sizes cross.
  // `localModel` (Ph119 T4): the launch-time local-endpoint probe — present only
  // on the local backend. `ok:false` means the default model is down/unreachable
  // (the surface warns). Additive/optional; absent on the hosted path.
  | {
      type: 'ready';
      workspaceRoot: string;
      available: boolean;
      sources: ContextSource[];
      localModel?: { ok: boolean; models: string[]; detail?: string };
    }
  | { type: 'engine-event'; turnId: string; event: EngineEvent }
  | { type: 'gate-pending'; callId: string; toolName: string; diff: string; summary: string; path?: string }
  | { type: 'revert-result'; path: string; ok: boolean; error?: string }
  // Phase 119 T4/T5/T7: the runtime model + thinking state + the loaded prompt
  // templates & skills (palette commands). Emitted after a change and on request.
  // `model`/`thinking` null before the session is built.
  | {
      type: 'session-info';
      model: ModelInfo | null;
      models: ModelInfo[];
      thinking: ThinkingInfo | null;
      templates: TemplateInfo[];
      skills: SkillInfo[];
    }
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
  /**
   * Phase 119 T2: the enforced spend ceiling (optional). When present, the host
   * reconciles it against the engine's authoritative cumulative cost (the
   * context-usage meter feed) and HARD-PAUSES a new turn once the ceiling is
   * exceeded — a visible pause, not an advisory number. Absent (and on the local
   * $0 model) it never trips; existing wiring is unchanged.
   */
  spendCeiling?: SpendCeiling;
  /**
   * Phase 119 T8 (A3 safe default): host-orchestrated memory retrieval. When
   * present, the host searches memory for each prompt and injects the results into
   * the turn's context — NOT a model-facing tool (no gate carve-out). Fail-open:
   * a memory outage runs the turn memoryless. Absent → no memory injection.
   */
  memory?: MemoryRetriever;
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
      case 'new-conversation':
        // Release any held gate await from the abandoned thread, then reset the
        // engine's cross-turn session (gate re-attaches on rebuild). No-op if the
        // adapter has no persistent session.
        this.broker.rejectAll();
        await this.runMutation('new-conversation', () => this.deps.adapter.newConversation?.());
        return;
      case 'compact':
        // Manually compact the engine context (a session mutation; the gate
        // survives it). No-op if the adapter is not compactable.
        await this.runMutation('compact', () => this.deps.adapter.compact?.());
        return;
      case 'cycle-model':
        // A gate-surviving mutation; re-surface the updated model state.
        await this.runMutation('cycle-model', () => this.deps.adapter.cycleModel?.());
        await this.emitSessionInfo();
        return;
      case 'set-model':
        await this.runMutation('set-model', () => this.deps.adapter.setModel?.(msg.providerId, msg.modelId));
        await this.emitSessionInfo();
        return;
      case 'request-session-info':
        await this.emitSessionInfo();
        return;
      case 'cycle-thinking':
        await this.runMutation('cycle-thinking', () => this.deps.adapter.cycleThinkingLevel?.());
        await this.emitSessionInfo();
        return;
      case 'set-thinking':
        await this.runMutation('set-thinking', () => this.deps.adapter.setThinkingLevel?.(msg.level));
        await this.emitSessionInfo();
        return;
    }
  }

  /**
   * Run a session-config mutation (compact / model / thinking / new-conversation)
   * DEFENSIVELY. A failure must NOT propagate to host.handle()'s caller, because
   * main.ts turns an unhandled handle() rejection into a top-level `error` that the
   * bridge broadcasts to — and closes — EVERY in-flight turn (Ph119 review nit 1:
   * hitting "Compact" mid-stream would otherwise nuke the running turn). Log to
   * stderr (the sidecar's diagnostic channel, separate from the stdout protocol);
   * the follow-up session-info re-emit shows the unchanged state. A common benign
   * compact (nothing-to-compact) is already swallowed at the adapter.
   */
  private async runMutation(label: string, fn: () => Promise<unknown> | undefined): Promise<void> {
    try {
      await fn();
    } catch (e) {
      process.stderr.write(`[nana] ${label} failed: ${e instanceof Error ? e.message : String(e)}\n`);
    }
  }

  /** Ph119 T4/T5: push the current model + thinking state to the surface (the picker
   *  chips). Feature-detected + resilient — an adapter without model/thinking support
   *  (or a build failure) sends nulls rather than crashing the host. */
  private async emitSessionInfo(): Promise<void> {
    try {
      const model = (await this.deps.adapter.currentModel?.()) ?? null;
      const models = (await this.deps.adapter.listModels?.()) ?? [];
      const thinking = (await this.deps.adapter.thinkingInfo?.()) ?? null;
      const templates = (await this.deps.adapter.listPromptTemplates?.()) ?? [];
      const skills = (await this.deps.adapter.listSkills?.()) ?? [];
      this.deps.send({ type: 'session-info', model, models, thinking, templates, skills });
    } catch {
      this.deps.send({ type: 'session-info', model: null, models: [], thinking: null, templates: [], skills: [] });
    }
  }

  private async runTurn(turnId: string, text: string): Promise<void> {
    const ac = new AbortController();
    this.turns.set(turnId, ac);
    const assemble = this.deps.assemble ?? assembleContext;
    try {
      // Ph119 T2: hard-pause the turn if the spend ceiling is already exceeded —
      // a visible pause (an error engine-event), enforced BEFORE any spend, not
      // an advisory number. Local $0 never trips this.
      if (this.deps.spendCeiling?.exceeded()) {
        const s = this.deps.spendCeiling.status();
        this.deps.send({
          type: 'engine-event',
          turnId,
          event: {
            type: 'error',
            error: `spend ceiling reached: $${s.spentUsd.toFixed(4)} >= $${s.ceilingUsd.toFixed(4)} — confirmation required to continue`,
          },
        });
        return;
      }
      // INSIDE the try: a context-assembly failure must surface as a turn error
      // (a visible engine-event), not reject host.handle() — which would leave the
      // UI hung on "working…" forever (no done/error ever reaches the turn).
      const { systemContext } = assemble(this.deps.workspaceRoot);
      // Ph119 T8: host-orchestrated memory retrieval, appended to the context.
      // Fail-open (retrieve() swallows its own errors; the guard is belt-and-
      // suspenders) — a memory outage must not fail the turn.
      let memorySection = '';
      if (this.deps.memory) {
        try {
          memorySection = await this.deps.memory.retrieve(text);
        } catch {
          memorySection = '';
        }
      }
      const fullContext = memorySection ? `${systemContext}\n\n---\n\n${memorySection}` : systemContext;
      for await (const event of this.deps.adapter.sendPrompt(text, {
        signal: ac.signal,
        systemContext: fullContext,
      })) {
        // Ph119 T2: reconcile the ceiling against the engine's authoritative
        // cumulative cost as it streams (monotonic — a lower late reading can't
        // un-pause). The NEXT turn is what the exceeded-check above blocks.
        if (event.type === 'context-usage') {
          this.deps.spendCeiling?.noteCumulativeCost(event.costUsd);
        }
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
