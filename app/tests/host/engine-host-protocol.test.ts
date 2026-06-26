import { describe, it, expect } from 'vitest';
import { EngineHost, type HostOutbound } from '../../src/host/engine-host';
import type { EngineAdapter, SendPromptOptions } from '../../src/engine/adapter';
import type { EngineEvent, ToolCallGate } from '../../src/engine/types';
import { createHostGate } from '../../src/gate/host-gate';

// T6: the webview<->Node-engine bridge PROTOCOL, tested transport-free. A fake
// adapter drives scripted turns and actually CALLS the injected gate, so the
// gate-hold round-trip (axis 1) is exercised end to end through the protocol.

const tick = () => new Promise((r) => setTimeout(r, 0));
const reasonOf = (d: { action: string; reason?: string }): string =>
  d.action === 'deny' && d.reason ? d.reason : 'denied by gate';

class FakeAdapter implements EngineAdapter {
  readonly id = 'fake';
  gate?: ToolCallGate;
  lastSystemContext?: string;
  constructor(
    private readonly script: (ctx: { gate: ToolCallGate; signal?: AbortSignal }) => AsyncGenerator<EngineEvent>,
  ) {}
  setToolCallGate(g: ToolCallGate): void {
    this.gate = g;
  }
  async *sendPrompt(_prompt: string, opts: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
    this.lastSystemContext = opts.systemContext;
    if (!this.gate) throw new Error('gate not set');
    yield* this.script({ gate: this.gate, signal: opts.signal });
  }
}

function evtTypes(sent: HostOutbound[]): string[] {
  return sent.filter((m) => m.type === 'engine-event').map((m) => (m as Extract<HostOutbound, { type: 'engine-event' }>).event.type);
}

describe('engine-host protocol (T6)', () => {
  it('streams a plain turn as engine-events tagged with the turnId, and passes assembled context (A2)', async () => {
    const sent: HostOutbound[] = [];
    const adapter = new FakeAdapter(async function* () {
      yield { type: 'text-delta', delta: 'Hello' };
      yield { type: 'done' };
    });
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      assemble: () => ({ systemContext: 'PROJECT CTX' }),
    });
    await host.handle({ type: 'prompt', turnId: 't1', text: 'hi' });
    expect(adapter.lastSystemContext).toBe('PROJECT CTX');
    expect(evtTypes(sent)).toEqual(['text-delta', 'done']);
    expect(sent.every((m) => m.type !== 'engine-event' || (m as { turnId: string }).turnId === 't1')).toBe(true);
  });

  it('holds a confirmable destructive call, surfaces gate-pending, snapshots + allows on approve', async () => {
    const sent: HostOutbound[] = [];
    const snapshots: string[] = [];
    const adapter = new FakeAdapter(async function* ({ gate }) {
      yield { type: 'text-delta', delta: 'writing config…' };
      const d = await gate({ id: 'tc1', name: 'write', args: { path: '/etc/cron.d/x', content: 'new' } });
      if (d.action === 'allow') {
        yield { type: 'tool-call', call: { id: 'tc1', name: 'write', args: {} } };
        yield { type: 'tool-result', id: 'tc1', result: 'ok' };
      } else {
        yield { type: 'tool-denied', id: 'tc1', reason: reasonOf(d) };
      }
      yield { type: 'done' };
    });
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      snapshot: (p) => snapshots.push(p),
      assemble: () => ({ systemContext: 'CTX' }),
    });
    const turn = host.handle({ type: 'prompt', turnId: 't1', text: 'write config' });
    await tick();
    const pending = sent.find((m) => m.type === 'gate-pending') as Extract<HostOutbound, { type: 'gate-pending' }>;
    expect(pending).toMatchObject({ callId: 'tc1', toolName: 'write' });
    expect(pending.diff).toContain('+new'); // axis-1 preview of the proposed content

    await host.handle({ type: 'gate-verdict', callId: 'tc1', approved: true });
    await turn;
    expect(snapshots).toEqual(['/etc/cron.d/x']); // snapshotted before it landed (axis 2)
    expect(evtTypes(sent)).toEqual(['text-delta', 'tool-call', 'tool-result', 'done']);
  });

  it('denies a held call on a reject verdict (no snapshot, tool-denied surfaced)', async () => {
    const sent: HostOutbound[] = [];
    const snapshots: string[] = [];
    const adapter = new FakeAdapter(async function* ({ gate }) {
      const d = await gate({ id: 'tc9', name: 'bash', args: { command: 'rm -rf /' } });
      yield d.action === 'allow'
        ? { type: 'tool-call', call: { id: 'tc9', name: 'bash', args: {} } }
        : { type: 'tool-denied', id: 'tc9', reason: reasonOf(d) };
      yield { type: 'done' };
    });
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      snapshot: (p) => snapshots.push(p),
    });
    const turn = host.handle({ type: 'prompt', turnId: 't1', text: 'rm' });
    await tick();
    expect(sent.some((m) => m.type === 'gate-pending')).toBe(true);
    await host.handle({ type: 'gate-verdict', callId: 'tc9', approved: false });
    await turn;
    expect(snapshots).toEqual([]); // never approved => never snapshotted
    expect(evtTypes(sent)).toEqual(['tool-denied', 'done']);
  });

  it('reverts a path on a revert command and reports the result', async () => {
    const sent: HostOutbound[] = [];
    const reverted: string[] = [];
    const host = new EngineHost({
      adapter: new FakeAdapter(async function* () { yield { type: 'done' }; }),
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      revert: (p) => reverted.push(p),
    });
    await host.handle({ type: 'revert', path: '/ws/a.ts' });
    expect(reverted).toEqual(['/ws/a.ts']);
    expect(sent).toContainEqual({ type: 'revert-result', path: '/ws/a.ts', ok: true });
  });

  it('reports a revert failure rather than throwing', async () => {
    const sent: HostOutbound[] = [];
    const host = new EngineHost({
      adapter: new FakeAdapter(async function* () { yield { type: 'done' }; }),
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      revert: () => { throw new Error('no checkpoint'); },
    });
    await host.handle({ type: 'revert', path: '/ws/a.ts' });
    expect(sent).toContainEqual({ type: 'revert-result', path: '/ws/a.ts', ok: false, error: 'no checkpoint' });
  });

  it('interrupt aborts the turn signal and releases any held gate', async () => {
    const sent: HostOutbound[] = [];
    let sawAbort = false;
    const adapter = new FakeAdapter(async function* ({ gate, signal }) {
      signal?.addEventListener('abort', () => { sawAbort = true; });
      const d = await gate({ id: 'h', name: 'bash', args: { command: 'rm -rf x' } });
      yield { type: 'tool-denied', id: 'h', reason: reasonOf(d) };
      yield { type: 'done' };
    });
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
    });
    const turn = host.handle({ type: 'prompt', turnId: 't1', text: 'rm' });
    await tick();
    expect(sent.some((m) => m.type === 'gate-pending')).toBe(true);
    await host.handle({ type: 'interrupt', turnId: 't1' });
    await turn;
    expect(sawAbort).toBe(true);
    // the held call was released as denied, so the turn completed
    expect(evtTypes(sent)).toContain('done');
  });
});
