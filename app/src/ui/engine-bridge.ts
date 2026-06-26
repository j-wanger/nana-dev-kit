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

/** The minimal Tauri surface the bridge needs; injected so it is testable without a window. */
export interface TauriBridge {
  invoke(cmd: string, args: Record<string, unknown>): Promise<unknown>;
  /** Subscribe to a Tauri event; resolves with an unlisten fn. */
  listen(event: string, handler: (payload: string) => void): Promise<() => void>;
}

const HOST_EVENT = 'host-message';
const SEND_CMD = 'engine_send';

export class BridgeClient implements EngineAdapter {
  readonly id = 'bridge';
  private turnSeq = 0;
  private readonly turns = new Map<string, EventQueue>();
  private readonly gateListeners = new Set<(p: GatePending) => void>();
  private readonly revertWaiters = new Map<string, (r: RevertResult) => void>();
  private unlisten?: () => void;

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

  /** Surface a held destructive call to the gate-confirm UI (T3). Returns an unsubscribe. */
  onGatePending(listener: (p: GatePending) => void): () => void {
    this.gateListeners.add(listener);
    return () => this.gateListeners.delete(listener);
  }

  /** Post the human's verdict for a held call (T3). */
  respondGate(callId: string, approved: boolean): Promise<void> {
    return this.send({ type: 'gate-verdict', callId, approved });
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
      case 'ready':
      case 'error':
        break;
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
