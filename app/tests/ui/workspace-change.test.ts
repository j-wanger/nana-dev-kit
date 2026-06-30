import { describe, it, expect } from 'vitest';
import { BridgeClient, type TauriBridge } from '../../src/ui/engine-bridge';
import type { HostOutbound } from '../../src/host/engine-host';
import type { EngineEvent } from '../../src/engine/types';

// Phase 114, T4 (A4) — workspace re-spawn lifecycle, observed TS-side. Rust opens
// the native folder dialog and, on a chosen folder, kills + re-spawns the Node
// sidecar with NANA_WORKSPACE=<chosen> (a fresh process → fresh createHostGate(root)
// + fresh approved-writes Map — NOT asserted here, that is the Rust/live-drive
// half). What IS observable on the bridge: it triggers the respawn via
// `pick_workspace` (no webview-supplied path), tears down the dead sidecar's
// in-flight turns/waiters so the UI never hangs, and resolves only once the fresh
// sidecar re-announces `ready`. A cancelled dialog leaves the running session
// untouched.

const tick = () => new Promise((r) => setTimeout(r, 0));

function mockTauri(opts: { pick?: string | null } = {}) {
  const invokes: Array<{ cmd: string; args: Record<string, unknown> }> = [];
  const sentLines: Array<Record<string, unknown>> = [];
  let handler: ((payload: string) => void) | undefined;
  const tauri: TauriBridge = {
    invoke: async (cmd, args) => {
      invokes.push({ cmd, args });
      if (cmd === 'pick_workspace') return opts.pick ?? null;
      if (cmd === 'engine_send') sentLines.push(JSON.parse(String(args.line)) as Record<string, unknown>);
      return undefined;
    },
    listen: async (_event, h) => {
      handler = h;
      return () => {
        handler = undefined;
      };
    },
  };
  return {
    tauri,
    invokes,
    sentLines,
    emit: (msg: HostOutbound) => handler?.(JSON.stringify(msg)),
  };
}

describe('BridgeClient.changeWorkspace — re-spawn lifecycle (Phase 114 T4, A4)', () => {
  it('invokes pick_workspace (no path arg), tears down the dead sidecar’s in-flight turn, and resolves on the fresh ready', async () => {
    const m = mockTauri({ pick: '/picked/ws' });
    const client = new BridgeClient(m.tauri);
    await client.start();

    // An in-flight turn against the OLD sidecar.
    const events: EngineEvent[] = [];
    const consume = (async () => {
      for await (const ev of client.sendPrompt('work')) events.push(ev);
    })();
    await tick();
    const turnId = String(m.sentLines.find((l) => l.type === 'prompt')?.turnId);
    m.emit({ type: 'engine-event', turnId, event: { type: 'text-delta', delta: 'mid' } });
    await tick();

    const changing = client.changeWorkspace();
    await tick();

    // The respawn command was invoked, and the webview supplied NO path argument.
    const pick = m.invokes.find((i) => i.cmd === 'pick_workspace');
    expect(pick).toBeDefined();
    expect(pick!.args).toEqual({});

    // The old sidecar is dead: its in-flight turn is torn down (the stream ends)
    // rather than hanging the UI forever on "working…".
    await consume;
    expect(events).toEqual([
      { type: 'text-delta', delta: 'mid' },
      { type: 'error', error: 'workspace changed' },
    ]);

    // changeWorkspace stays pending until the fresh sidecar re-announces ready…
    let resolved = false;
    void changing.then(() => {
      resolved = true;
    });
    await tick();
    expect(resolved).toBe(false);

    // …the fresh ready completes the reconnect and yields the chosen root.
    m.emit({ type: 'ready', workspaceRoot: '/picked/ws', available: true, sources: [] });
    await expect(changing).resolves.toBe('/picked/ws');

    // The reconnected session is functional: a fresh prompt streams to done.
    const e2: EngineEvent[] = [];
    const consume2 = (async () => {
      for await (const ev of client.sendPrompt('again')) e2.push(ev);
    })();
    await tick();
    const t2 = String(m.sentLines.filter((l) => l.type === 'prompt').at(-1)?.turnId);
    m.emit({ type: 'engine-event', turnId: t2, event: { type: 'done' } });
    await consume2;
    expect(e2).toEqual([{ type: 'done' }]);
  });

  it('ignores a re-entrant changeWorkspace — no clobbered ready waiter, no double respawn (T6 review F2)', async () => {
    const m = mockTauri({ pick: '/picked/ws' });
    const client = new BridgeClient(m.tauri);
    await client.start();

    const first = client.changeWorkspace();
    const second = client.changeWorkspace(); // re-entrant while the first is in flight
    await tick();

    // The second call is ignored immediately — only ONE pick_workspace/respawn.
    await expect(second).resolves.toBeNull();
    expect(m.invokes.filter((i) => i.cmd === 'pick_workspace')).toHaveLength(1);

    // The first call still resolves on the fresh ready (its waiter was not clobbered).
    m.emit({ type: 'ready', workspaceRoot: '/picked/ws', available: true, sources: [] });
    await expect(first).resolves.toBe('/picked/ws');
  });

  it('returns null and leaves the running session untouched when the dialog is cancelled', async () => {
    const m = mockTauri({ pick: null });
    const client = new BridgeClient(m.tauri);
    await client.start();

    const events: EngineEvent[] = [];
    const consume = (async () => {
      for await (const ev of client.sendPrompt('work')) events.push(ev);
    })();
    await tick();
    const turnId = String(m.sentLines.find((l) => l.type === 'prompt')?.turnId);
    m.emit({ type: 'engine-event', turnId, event: { type: 'text-delta', delta: 'mid' } });

    await expect(client.changeWorkspace()).resolves.toBeNull();

    // No teardown on cancel: the live turn finishes normally.
    m.emit({ type: 'engine-event', turnId, event: { type: 'done' } });
    await consume;
    expect(events).toEqual([
      { type: 'text-delta', delta: 'mid' },
      { type: 'done' },
    ]);
  });
});
