import { describe, it, expect } from 'vitest';
import { EngineHost, type HostOutbound } from '../../src/host/engine-host';
import type { EngineAdapter, SendPromptOptions } from '../../src/engine/adapter';
import type { EngineEvent, ToolCallGate } from '../../src/engine/types';
import { createHostGate } from '../../src/gate/host-gate';
import { SpendCeiling } from '../../src/control/spend';

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

  it('a context-assembly failure surfaces as a turn error, not a rejected/hung turn (dogfood fix #5)', async () => {
    const sent: HostOutbound[] = [];
    const host = new EngineHost({
      adapter: new FakeAdapter(async function* () { yield { type: 'done' }; }),
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      assemble: () => { throw new Error('cannot read project context'); },
    });
    // Must RESOLVE, not reject — a rejection would leave the UI hung on "working…"
    // forever (no done/error ever reaches the turn).
    await expect(host.handle({ type: 'prompt', turnId: 't1', text: 'hi' })).resolves.toBeUndefined();
    const errEvt = sent.find(
      (m) => m.type === 'engine-event' && (m as Extract<HostOutbound, { type: 'engine-event' }>).event.type === 'error',
    ) as Extract<HostOutbound, { type: 'engine-event' }> | undefined;
    expect(errEvt, 'an error engine-event is surfaced for the turn').toBeTruthy();
    expect((errEvt!.event as { error: string }).error).toContain('cannot read project context');
  });

  it('routes a compact inbound to adapter.compact (Ph119 T2)', async () => {
    let compacted = 0;
    const adapter: EngineAdapter = {
      id: 'fake',
      setToolCallGate() {},
      async *sendPrompt() {
        yield { type: 'done' };
      },
      async compact() {
        compacted++;
      },
    };
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: () => {},
    });
    await host.handle({ type: 'compact' });
    expect(compacted).toBe(1);
  });

  it('cycle-model / set-model route to the adapter and re-emit session-info (Ph119 T4)', async () => {
    const sent: HostOutbound[] = [];
    const calls: string[] = [];
    const adapter: EngineAdapter = {
      id: 'fake',
      setToolCallGate() {},
      async *sendPrompt() {
        yield { type: 'done' };
      },
      async cycleModel() {
        calls.push('cycle');
        return { providerId: 'anthropic', modelId: 'claude', label: 'claude', isLocal: false, active: true };
      },
      async setModel(p, m) {
        calls.push(`set:${p}/${m}`);
        return true;
      },
      async currentModel() {
        return { providerId: 'local', modelId: 'qwen', label: 'qwen', isLocal: true, active: true };
      },
      async listModels() {
        return [
          { providerId: 'local', modelId: 'qwen', label: 'qwen', isLocal: true, active: true },
          { providerId: 'anthropic', modelId: 'claude', label: 'claude', isLocal: false, active: false },
        ];
      },
    };
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
    });

    await host.handle({ type: 'cycle-model' });
    await host.handle({ type: 'set-model', providerId: 'anthropic', modelId: 'claude' });
    await host.handle({ type: 'request-session-info' });

    expect(calls).toEqual(['cycle', 'set:anthropic/claude']);
    const infos = sent.filter((m) => m.type === 'session-info') as Extract<HostOutbound, { type: 'session-info' }>[];
    expect(infos).toHaveLength(3); // one per cycle/set/request
    expect(infos[0].models.map((m) => m.modelId)).toEqual(['qwen', 'claude']);
    expect(infos[0].model?.modelId).toBe('qwen');
  });

  it('cycle-thinking / set-thinking route to the adapter and re-emit session-info with thinking (Ph119 T5)', async () => {
    const sent: HostOutbound[] = [];
    const calls: string[] = [];
    const adapter: EngineAdapter = {
      id: 'fake',
      setToolCallGate() {},
      async *sendPrompt() {
        yield { type: 'done' };
      },
      async cycleThinkingLevel() {
        calls.push('cycle');
        return 'high';
      },
      async setThinkingLevel(l) {
        calls.push(`set:${l}`);
      },
      async thinkingInfo() {
        return { level: 'high', levels: ['low', 'medium', 'high'], supported: true };
      },
    };
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
    });

    await host.handle({ type: 'cycle-thinking' });
    await host.handle({ type: 'set-thinking', level: 'low' });

    expect(calls).toEqual(['cycle', 'set:low']);
    const infos = sent.filter((m) => m.type === 'session-info') as Extract<HostOutbound, { type: 'session-info' }>[];
    expect(infos).toHaveLength(2);
    expect(infos[0].thinking).toEqual({ level: 'high', levels: ['low', 'medium', 'high'], supported: true });
  });

  it('session-info carries the loaded prompt templates + skills (Ph119 T7)', async () => {
    const sent: HostOutbound[] = [];
    const adapter: EngineAdapter = {
      id: 'fake',
      setToolCallGate() {},
      async *sendPrompt() {
        yield { type: 'done' };
      },
      async listPromptTemplates() {
        return [{ name: 'review', description: 'code review', content: 'Review the diff.' }];
      },
      async listSkills() {
        return [{ name: 'deploy', description: 'deploy helper' }];
      },
    };
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
    });
    await host.handle({ type: 'request-session-info' });
    const info = sent.find((m) => m.type === 'session-info') as Extract<HostOutbound, { type: 'session-info' }>;
    expect(info.templates.map((t) => t.name)).toEqual(['review']);
    expect(info.skills.map((s) => s.name)).toEqual(['deploy']);
  });

  it('emitSessionInfo is resilient — an adapter without model support sends nulls (Ph119 T4)', async () => {
    const sent: HostOutbound[] = [];
    const host = new EngineHost({
      adapter: new FakeAdapter(async function* () {
        yield { type: 'done' };
      }),
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
    });
    await host.handle({ type: 'request-session-info' });
    const info = sent.find((m) => m.type === 'session-info') as Extract<HostOutbound, { type: 'session-info' }>;
    expect(info).toMatchObject({ model: null, models: [] });
  });

  it('a session-mutation FAILURE (compact throws) does NOT propagate out of handle() — no turn-nuke (review nit 1)', async () => {
    const adapter: EngineAdapter = {
      id: 'fake',
      setToolCallGate() {},
      async *sendPrompt() {
        yield { type: 'done' };
      },
      async compact() {
        throw new Error('pi refused to compact mid-generation');
      },
    };
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: () => {},
    });
    // Must RESOLVE (the failure is caught + logged), not reject — a rejection would
    // become main.ts's top-level `error` that the bridge broadcasts to every turn.
    await expect(host.handle({ type: 'compact' })).resolves.toBeUndefined();
  });

  it('a new-conversation inbound resets the engine and releases held gate awaits (Ph119 T1)', async () => {
    let reset = 0;
    const adapter: EngineAdapter = {
      id: 'fake',
      setToolCallGate() {},
      async *sendPrompt() {
        yield { type: 'done' };
      },
      async newConversation() {
        reset++;
      },
    };
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: () => {},
    });
    await host.handle({ type: 'new-conversation' });
    expect(reset).toBe(1);
  });

  it('hard-pauses a new turn (error event) when the spend ceiling is exceeded, without running the engine (Ph119 T2)', async () => {
    const sent: HostOutbound[] = [];
    let ran = false;
    const adapter = new FakeAdapter(async function* () {
      ran = true;
      yield { type: 'done' };
    });
    const ceiling = new SpendCeiling(0.01, {});
    ceiling.noteCumulativeCost(1.0); // already over
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      spendCeiling: ceiling,
      assemble: () => ({ systemContext: '' }),
    });
    await host.handle({ type: 'prompt', turnId: 't1', text: 'hi' });
    expect(ran).toBe(false); // the engine was never reached
    const err = sent.find(
      (m) => m.type === 'engine-event' && (m as Extract<HostOutbound, { type: 'engine-event' }>).event.type === 'error',
    ) as Extract<HostOutbound, { type: 'engine-event' }> | undefined;
    expect(err, 'a spend-ceiling pause surfaces as a turn error').toBeTruthy();
    expect((err!.event as { error: string }).error).toMatch(/spend ceiling/i);
  });

  it('notes the engine cumulative cost from the context-usage meter feed (Ph119 T2)', async () => {
    const adapter = new FakeAdapter(async function* () {
      yield { type: 'context-usage', percent: 10, tokens: 100, contextWindow: 1000, costUsd: 0.7 };
      yield { type: 'done' };
    });
    const ceiling = new SpendCeiling(0.5, {});
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: () => {},
      spendCeiling: ceiling,
      assemble: () => ({ systemContext: '' }),
    });
    await host.handle({ type: 'prompt', turnId: 't1', text: 'hi' });
    expect(ceiling.spentUsd).toBeCloseTo(0.7, 5);
    expect(ceiling.exceeded()).toBe(true); // the next turn would pause
  });

  it('injects HOST-ORCHESTRATED memory into the turn context (Ph119 T8, A3)', async () => {
    const adapter = new FakeAdapter(async function* () {
      yield { type: 'done' };
    });
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: () => {},
      assemble: () => ({ systemContext: 'BASE CONTEXT' }),
      memory: { retrieve: async (q) => `# Retrieved memory\n- relevant to: ${q}` },
    });
    await host.handle({ type: 'prompt', turnId: 't1', text: 'fix the auth bug' });
    // The turn's context is base + the retrieved memory (host-side; not a model tool).
    expect(adapter.lastSystemContext).toContain('BASE CONTEXT');
    expect(adapter.lastSystemContext).toContain('relevant to: fix the auth bug');
  });

  it('a memory retrieval FAILURE does not break the turn — it runs memoryless (fail-open, Ph119 T8)', async () => {
    const sent: HostOutbound[] = [];
    const adapter = new FakeAdapter(async function* () {
      yield { type: 'text-delta', delta: 'hi' };
      yield { type: 'done' };
    });
    const host = new EngineHost({
      adapter,
      workspaceRoot: '/ws',
      baseGate: createHostGate({ workspaceRoot: '/ws' }),
      send: (m) => sent.push(m),
      assemble: () => ({ systemContext: 'BASE CONTEXT' }),
      memory: {
        retrieve: async () => {
          throw new Error('memory server down');
        },
      },
    });
    await host.handle({ type: 'prompt', turnId: 't1', text: 'go' });
    expect(evtTypes(sent)).toEqual(['text-delta', 'done']); // the turn completed normally
    expect(adapter.lastSystemContext).toBe('BASE CONTEXT'); // memoryless, no injection
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
