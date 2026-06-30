import type { EngineAdapter, SendPromptOptions } from '../engine/adapter';
import type { EngineEvent, ToolCallGate } from '../engine/types';
import type { HostOutbound } from '../host/engine-host';
import { EventQueue } from '../engine/event-queue';

// Webview-side bridge to the Node engine-host (Phase 109, T6). The engine is
// Node-only and unreachable from the webview directly, so the Rust shell spawns
// the host and relays its line protocol: every HostOutbound line arrives as one
// 'host-message' Tauri event; commands go out via the `engine_send` Tauri
// command (Rust writes them to the host's stdin). This client implements
// EngineAdapter so useChatRuntime is unchanged — but the in-process gate runs
// HOST-side, so setToolCallGate is a no-op here. It also exposes the gate-confirm
// (T3) and revert (T4) channels the surface needs.

export interface GatePending {
  callId: string;
  toolName: string;
  diff: string;
  summary: string;
  /** Target file path for a write/edit hold (so an approved edit is revertible — axis 2). */
  path?: string;
}
export interface RevertResult {
  ok: boolean;
  error?: string;
}

/**
 * The active workspace + project-blind state, surfaced from the host `ready`
 * (Phase 114, T5). `available` is false when no AGENTS.md/CLAUDE.md/.claude/rules
 * context was found — the agent is running project-blind. `sources` lists the
 * contributing files + sizes only; the systemContext CONTENTS never cross.
 */
export interface WorkspaceInfo {
  root: string;
  available: boolean;
  sources: { path: string; bytes: number }[];
}

/** The minimal Tauri surface the bridge needs; injected so it is testable without a window. */
export interface TauriBridge {
  invoke(cmd: string, args: Record<string, unknown>): Promise<unknown>;
  /** Subscribe to a Tauri event; resolves with an unlisten fn. */
  listen(event: string, handler: (payload: string) => void): Promise<() => void>;
}

const HOST_EVENT = 'host-message';
const SEND_CMD = 'engine_send';
const PICK_WORKSPACE_CMD = 'pick_workspace';

export class BridgeClient implements EngineAdapter {
  readonly id = 'bridge';
  private turnSeq = 0;
  private readonly turns = new Map<string, EventQueue>();
  private readonly gateListeners = new Set<(p: GatePending) => void>();
  private readonly revertWaiters = new Map<string, (r: RevertResult) => void>();
  private unlisten?: () => void;
  /** Armed during changeWorkspace; resolved by the fresh sidecar's `ready` (T4). */
  private readyWaiter?: () => void;
  /** Guards against a re-entrant changeWorkspace clobbering readyWaiter (T6 review). */
  private changing = false;
  /** Active workspace + project-blind state from the latest `ready` (T5). */
  private workspace?: WorkspaceInfo;
  private readonly workspaceListeners = new Set<(w: WorkspaceInfo) => void>();

  constructor(private readonly tauri: TauriBridge) {}

  /** Subscribe to host messages. Call once after construction. */
  async start(): Promise<void> {
    this.unlisten = await this.tauri.listen(HOST_EVENT, (payload) => this.route(payload));
  }

  stop(): void {
    this.unlisten?.();
    this.unlisten = undefined;
  }

  // The in-process gate runs in the Node host, not the webview; transport facade.
  setToolCallGate(_gate: ToolCallGate): void {
    /* no-op by design */
  }

  async *sendPrompt(prompt: string, options: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
    const turnId = `t${++this.turnSeq}`;
    const queue = new EventQueue();
    this.turns.set(turnId, queue);

    const interrupt = () => void this.send({ type: 'interrupt', turnId });
    if (options.signal) {
      if (options.signal.aborted) interrupt();
      else options.signal.addEventListener('abort', interrupt, { once: true });
    }

    await this.send({ type: 'prompt', turnId, text: prompt });
    try {
      yield* queue.stream();
    } finally {
      this.turns.delete(turnId);
    }
  }

  /** The active workspace + project-blind state, or null before the first ready (T5). */
  get currentWorkspace(): WorkspaceInfo | null {
    return this.workspace ?? null;
  }

  /** Subscribe to workspace changes; fires immediately with the current value if known (T5). */
  onWorkspace(listener: (w: WorkspaceInfo) => void): () => void {
    this.workspaceListeners.add(listener);
    if (this.workspace) listener(this.workspace);
    return () => this.workspaceListeners.delete(listener);
  }

  /** Surface a held destructive call to the gate-confirm UI (T3). Returns an unsubscribe. */
  onGatePending(listener: (p: GatePending) => void): () => void {
    this.gateListeners.add(listener);
    return () => this.gateListeners.delete(listener);
  }

  /** Post the human's verdict for a held call (T3). */
  respondGate(callId: string, approved: boolean): Promise<void> {
    return this.send({ type: 'gate-verdict', callId, approved });
  }

  /**
   * Change the active workspace (Phase 114, T4). Rust opens the native folder
   * dialog and, if a folder is chosen, kills + re-spawns the Node sidecar with
   * NANA_WORKSPACE=<chosen> — a fresh process, so a fresh createHostGate(root) and
   * a fresh approved-writes Map: the new gate boundary is the chosen folder and no
   * prior in-workspace approval carries over. The webview supplies NO path (it
   * cannot relocate the gate root); the choice is made only in the native dialog.
   *
   * The old sidecar is dead, so its in-flight turns and revert waiters will never
   * settle — we tear them down (ending their streams) so the UI never hangs, then
   * reconnect to the fresh sidecar by resolving on its `ready` handshake. The
   * host-message subscription itself is stable across the respawn (same Tauri
   * AppHandle + event name; Rust re-wires the new child's stdout to it), so it is
   * not re-listened. Resolves with the chosen root, or null if the user cancelled
   * (no respawn — the running session is left untouched).
   */
  async changeWorkspace(): Promise<string | null> {
    // Re-entrancy guard: a second call while one is in flight would overwrite the
    // single readyWaiter, orphaning the first promise (and double-spawning the
    // sidecar). Ignore overlapping calls (Ph114 review, F2).
    if (this.changing) return null;
    this.changing = true;
    try {
      const chosen = (await this.tauri.invoke(PICK_WORKSPACE_CMD, {})) as string | null;
      if (chosen == null) return null;
      this.teardown('workspace changed');
      const ready = new Promise<void>((resolve) => {
        this.readyWaiter = resolve;
      });
      await ready;
      return chosen;
    } finally {
      this.changing = false;
    }
  }

  /** Close every in-flight turn + revert waiter so a dead sidecar can't hang them. */
  private teardown(reason: string): void {
    for (const q of this.turns.values()) {
      q.push({ type: 'error', error: reason });
      q.close();
    }
    this.turns.clear();
    for (const w of this.revertWaiters.values()) w({ ok: false, error: reason });
    this.revertWaiters.clear();
  }

  /** Request a one-action revert and await the host's result (T4). */
  revert(path: string): Promise<RevertResult> {
    return new Promise<RevertResult>((resolve) => {
      this.revertWaiters.set(path, resolve);
      void this.send({ type: 'revert', path });
    });
  }

  private send(msg: Record<string, unknown>): Promise<void> {
    return this.tauri.invoke(SEND_CMD, { line: JSON.stringify(msg) }) as Promise<void>;
  }

  private route(payload: string): void {
    let msg: HostOutbound;
    try {
      msg = JSON.parse(payload) as HostOutbound;
    } catch {
      return; // ignore malformed lines
    }
    switch (msg.type) {
      case 'engine-event': {
        const q = this.turns.get(msg.turnId);
        if (q) {
          q.push(msg.event);
          if (msg.event.type === 'done' || msg.event.type === 'error') q.close();
        }
        break;
      }
      case 'gate-pending': {
        const pending: GatePending = {
          callId: msg.callId,
          toolName: msg.toolName,
          diff: msg.diff,
          summary: msg.summary,
          path: msg.path,
        };
        for (const l of this.gateListeners) l(pending);
        break;
      }
      case 'revert-result': {
        const w = this.revertWaiters.get(msg.path);
        if (w) {
          this.revertWaiters.delete(msg.path);
          w({ ok: msg.ok, error: msg.error });
        }
        break;
      }
      case 'error': {
        // A top-level host error is not tied to a turnId. Surface it on every
        // in-flight turn and close them, so the UI never hangs on "working…"
        // (the assemble-in-try fix makes most errors turn-scoped; this is the
        // backstop for a genuinely host-level failure).
        for (const q of this.turns.values()) {
          q.push({ type: 'error', error: msg.message });
          q.close();
        }
        break;
      }
      case 'ready': {
        // Surface the active workspace + project-blind state to the header (T5).
        this.workspace = {
          root: msg.workspaceRoot,
          available: msg.available,
          sources: msg.sources,
        };
        for (const l of this.workspaceListeners) l(this.workspace);
        // The first sidecar's ready is otherwise unobserved; a re-spawn (T4) arms
        // a waiter so changeWorkspace resolves once the fresh sidecar is live.
        const w = this.readyWaiter;
        if (w) {
          this.readyWaiter = undefined;
          w();
        }
        break;
      }
    }
  }
}

/** Build a BridgeClient over the real Tauri APIs (webview only; lazy import). */
export async function createBridgeClient(): Promise<BridgeClient> {
  const [{ invoke }, { listen }] = await Promise.all([
    import('@tauri-apps/api/core'),
    import('@tauri-apps/api/event'),
  ]);
  const tauri: TauriBridge = {
    invoke: (cmd, args) => invoke(cmd, args),
    listen: (event, handler) => listen<string>(event, (e) => handler(e.payload)),
  };
  const client = new BridgeClient(tauri);
  await client.start();
  return client;
}
