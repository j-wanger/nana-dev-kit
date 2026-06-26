import { describe, it, expect } from 'vitest';
import { BridgeClient, type TauriBridge, type GatePending } from '../../src/ui/engine-bridge';
import type { HostOutbound } from '../../src/host/engine-host';
import type { EngineEvent } from '../../src/engine/types';

// T6: the webview BridgeClient over a mocked Tauri surface (no window). It
// implements EngineAdapter (so useChatRuntime is unchanged) and routes the host
// line protocol: engine-event -> the turn stream; gate-pending -> the UI; revert.

const tick = () => new Promise((r) => setTimeout(r, 0));

function mockTauri() {
  const sent: Array<{ cmd: string; line: Record<string, unknown> }> = [];
  let handler: ((payload: string) => void) | undefined;
  const tauri: TauriBridge = {
    invoke: async (cmd, args) => {
      sent.push({ cmd, line: JSON.parse(String(args.line)) as Record<string, unknown> });
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
    sent,
    emit: (msg: HostOutbound) => handler?.(JSON.stringify(msg)),
    emitRaw: (payload: string) => handler?.(payload),
  };
}

describe('BridgeClient (T6)', () => {
  it('sends a prompt and streams engine-events for that turn until done', async () => {
    const { tauri, sent, emit } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();

    const events: EngineEvent[] = [];
    const consume = (async () => {
      for await (const ev of client.sendPrompt('build it')) events.push(ev);
    })();
    await tick();

    const prompt = sent.find((s) => s.line.type === 'prompt');
    expect(prompt?.line.text).toBe('build it');
    const turnId = String(prompt?.line.turnId);

    emit({ type: 'engine-event', turnId, event: { type: 'text-delta', delta: 'On it' } });
    emit({ type: 'engine-event', turnId, event: { type: 'done' } });
    await consume;

    expect(events).toEqual([{ type: 'text-delta', delta: 'On it' }, { type: 'done' }]);
  });

  it('does not deliver another turn’s events into this turn', async () => {
    const { tauri, sent, emit } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();
    const events: EngineEvent[] = [];
    const consume = (async () => {
      for await (const ev of client.sendPrompt('x')) events.push(ev);
    })();
    await tick();
    const turnId = String(sent.find((s) => s.line.type === 'prompt')?.line.turnId);
    emit({ type: 'engine-event', turnId: 'OTHER', event: { type: 'text-delta', delta: 'leak' } });
    emit({ type: 'engine-event', turnId, event: { type: 'done' } });
    await consume;
    expect(events).toEqual([{ type: 'done' }]); // the foreign-turn delta never arrived
  });

  it('sends an interrupt command when the turn signal aborts', async () => {
    const { tauri, sent } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();
    const ac = new AbortController();
    const consume = (async () => {
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      for await (const _ of client.sendPrompt('long task', { signal: ac.signal })) {
        /* drain */
      }
    })();
    await tick();
    ac.abort();
    await tick();
    expect(sent.some((s) => s.line.type === 'interrupt')).toBe(true);
    // close the turn so the consumer settles
    const turnId = String(sent.find((s) => s.line.type === 'prompt')?.line.turnId);
    mockClose(client, turnId);
    await consume.catch(() => {});
  });

  it('surfaces a gate-pending to onGatePending listeners (axis 1)', async () => {
    const { tauri, emit } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();
    const seen: GatePending[] = [];
    client.onGatePending((p) => seen.push(p));
    emit({ type: 'gate-pending', callId: 'c1', toolName: 'bash', diff: '$ rm -rf x', summary: 'destructive' });
    expect(seen).toEqual([{ callId: 'c1', toolName: 'bash', diff: '$ rm -rf x', summary: 'destructive' }]);
  });

  it('respondGate posts a verdict command', async () => {
    const { tauri, sent } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();
    await client.respondGate('c1', true);
    expect(sent).toContainEqual({ cmd: 'engine_send', line: { type: 'gate-verdict', callId: 'c1', approved: true } });
  });

  it('revert sends a command and resolves on the host result', async () => {
    const { tauri, sent, emit } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();
    const p = client.revert('/ws/a.ts');
    await tick();
    expect(sent.some((s) => s.line.type === 'revert' && s.line.path === '/ws/a.ts')).toBe(true);
    emit({ type: 'revert-result', path: '/ws/a.ts', ok: true });
    await expect(p).resolves.toEqual({ ok: true, error: undefined });
  });

  it('ignores a malformed host message without throwing', async () => {
    const { tauri, emitRaw } = mockTauri();
    const client = new BridgeClient(tauri);
    await client.start();
    expect(() => emitRaw('{not json')).not.toThrow();
  });
});

// Helper: close a turn's queue from outside (the test for interrupt needs to let
// the consumer settle without a real 'done' from a host).
function mockClose(client: BridgeClient, turnId: string): void {
  // Reach into the private turn map via the documented host protocol instead of
  // private access: emit a done event for the turn.
  // (BridgeClient routes engine-event 'done' -> queue.close().)
  (client as unknown as { route(p: string): void }).route(
    JSON.stringify({ type: 'engine-event', turnId, event: { type: 'done' } } satisfies HostOutbound),
  );
}
