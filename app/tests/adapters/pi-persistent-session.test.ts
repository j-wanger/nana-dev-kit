import { describe, it, expect } from 'vitest';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  isBenignCompactError,
  PiAdapter,
  type MeterSnapshot,
  type PiSessionBuilder,
  type PiSessionHandle,
} from '../../src/engine/pi/pi-adapter';
import type {
  EngineEvent,
  GateDecision,
  ModelInfo,
  NormalizedToolCall,
  SkillInfo,
  TemplateInfo,
  ThinkingInfo,
} from '../../src/engine/types';

// Phase 119 T1 — the persistent-session foundation + the C1 denial-sink decouple.
//
// nana's Pi session USED to be per-turn ephemeral (built + disposed inside every
// sendPrompt), so the felt-quality items (meter, /compact, model/thinking switch)
// had no session to attach to. T1 makes it build-once / reuse-across-turns. The
// make-or-break invariant is that the host gate ([[engine-adapter-in-process-gate]])
// SURVIVES that persistence and routes each denial to the CURRENT turn's stream.
//
// The A1 gate-survival VERIFICATION CHECKPOINT (does Pi v0.80.2 keep the tool_call
// hook attached across setModel/compact/setThinkingLevel) is resolved by reading
// the compiled SDK: `beforeToolCall` is installed ONCE in the AgentSession ctor and
// reads `this._extensionRunner` at call time; only `_buildRuntime` (ctor + reload())
// ever reassigns it — none of the mutation methods do. Verdict: SURVIVES, defer
// nothing. See .dev-wiki/phase-119/checkpoint-a1-gate-survival.md.
//
// These are MECHANICS tests: they drive the adapter's lifecycle over an INJECTED
// fake session so the build-once / reuse / dispose-and-rebuild / denial-routing
// logic is proven WITHOUT a live model (native-runtime behavior is the maintainer
// live-drive). The Ph110 lesson stands — green fixtures prove the reduction, not
// the SDK contract; the live proof of gate-survival on turn 2 of a REAL persistent
// session is the it.runIf(LIVE) test in e2e/provider-roundtrip.

const tick = () => new Promise((r) => setTimeout(r, 0));
const WS = '/tmp/nana-persist-ws';

/** The fake persistent session, plus the test controls to drive one turn. */
interface FakeSession extends PiSessionHandle {
  prompts: string[];
  aborts: number;
  disposed: boolean;
  autoCompaction: boolean | null;
  compacts: number;
  cycles: number;
  setModelCalls: Array<[string, string]>;
  /** The available models the fake reports; the first is the active one. */
  models: ModelInfo[];
  thinking: ThinkingInfo;
  thinkingSets: string[];
  thinkingCycles: number;
  templates: TemplateInfo[];
  skills: SkillInfo[];
  /** The meter snapshot to return; undefined (default) means no context-usage event is emitted. */
  meter: MeterSnapshot | undefined;
  /** Route a mapped engine event to the current turn (as Pi's subscribe would). */
  emit(ev: EngineEvent): void;
  /** Run a tool call through the live gate; a deny surfaces via onDenied (as Pi's tool_call hook would). */
  fireToolCall(call: NormalizedToolCall): Promise<GateDecision>;
  /** Settle the in-flight prompt (turn completes normally). */
  finish(): void;
  /** Reject the in-flight prompt (a mid-turn session error). */
  fail(err: Error): void;
}

/**
 * A builder that returns controllable fake sessions. It wires the SAME seams the
 * real Pi builder does — the gate is resolved at CALL time (getGate) and denials
 * + stream events flow to the adapter-provided onDenied/onEvent (which push to
 * whatever the CURRENT turn is). That is exactly the C1 decouple under test.
 */
function makeFakeBuilder(): { builder: PiSessionBuilder; sessions: FakeSession[] } {
  const sessions: FakeSession[] = [];
  const builder: PiSessionBuilder = async ({ getGate, onDenied, onEvent }) => {
    let resolvePrompt: (() => void) | undefined;
    let rejectPrompt: ((e: Error) => void) | undefined;
    const s: FakeSession = {
      prompts: [],
      aborts: 0,
      disposed: false,
      autoCompaction: null,
      compacts: 0,
      cycles: 0,
      setModelCalls: [],
      models: [],
      thinking: { level: 'medium', levels: ['low', 'medium', 'high'], supported: true },
      thinkingSets: [],
      thinkingCycles: 0,
      templates: [],
      skills: [],
      meter: undefined,
      prompt(text: string) {
        this.prompts.push(text);
        return new Promise<void>((res, rej) => {
          resolvePrompt = res;
          rejectPrompt = rej;
        });
      },
      async abort() {
        this.aborts++;
        resolvePrompt?.(); // a hard interrupt settles the in-flight prompt; the session survives
      },
      dispose() {
        this.disposed = true;
      },
      setAutoCompactionEnabled(enabled: boolean) {
        this.autoCompaction = enabled;
      },
      meterSnapshot() {
        return this.meter;
      },
      async compact() {
        this.compacts++;
      },
      listModels() {
        return this.models;
      },
      currentModel() {
        return this.models.find((m) => m.active) ?? this.models[0];
      },
      async setModel(providerId: string, modelId: string) {
        this.setModelCalls.push([providerId, modelId]);
        const target = this.models.find((m) => m.providerId === providerId && m.modelId === modelId);
        if (!target) return false;
        this.models = this.models.map((m) => ({ ...m, active: m === target }));
        return true;
      },
      async cycleModel() {
        this.cycles++;
        if (this.models.length === 0) return undefined;
        const i = this.models.findIndex((m) => m.active);
        const next = this.models[(i + 1) % this.models.length];
        this.models = this.models.map((m) => ({ ...m, active: m === next }));
        return next;
      },
      thinkingInfo() {
        return this.thinking;
      },
      setThinkingLevel(level: string) {
        this.thinkingSets.push(level);
        this.thinking = { ...this.thinking, level };
      },
      cycleThinkingLevel() {
        this.thinkingCycles++;
        if (!this.thinking.supported || this.thinking.levels.length === 0) return undefined;
        const i = this.thinking.levels.indexOf(this.thinking.level);
        const next = this.thinking.levels[(i + 1) % this.thinking.levels.length];
        this.setThinkingLevel(next); // model Pi: cycle DELEGATES to the setter
        return next;
      },
      listPromptTemplates() {
        return this.templates;
      },
      listSkills() {
        return this.skills;
      },
      emit(ev: EngineEvent) {
        onEvent(ev);
      },
      async fireToolCall(call: NormalizedToolCall) {
        const decision = await getGate()(call);
        if (decision.action === 'deny') onDenied(call.id, decision.reason);
        return decision;
      },
      finish() {
        resolvePrompt?.();
      },
      fail(err: Error) {
        rejectPrompt?.(err);
      },
    };
    sessions.push(s);
    return s;
  };
  return { builder, sessions };
}

/** Drain a sendPrompt stream into an array in the background. */
function drive(stream: AsyncIterable<EngineEvent>): { events: EngineEvent[]; done: Promise<void> } {
  const events: EngineEvent[] = [];
  const done = (async () => {
    for await (const ev of stream) events.push(ev);
  })();
  return { events, done };
}

describe('PiAdapter persistent session — build-once, reuse, auto-compaction', () => {
  it('builds ONE session across turns, enables auto-compaction, and never disposes it between turns', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));

    for (const text of ['a', 'b', 'c']) {
      const t = drive(adapter.sendPrompt(text));
      await tick();
      sessions[0].finish();
      await t.done;
    }

    expect(sessions).toHaveLength(1); // build-once, reused across all three turns
    expect(sessions[0].autoCompaction).toBe(true); // compaction folded into the foundation
    expect(sessions[0].prompts).toEqual(['a', 'b', 'c']);
    expect(sessions[0].disposed).toBe(false);
  });

  it('terminates each turn with a synthesized done event', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));
    const t = drive(adapter.sendPrompt('hi'));
    await tick();
    sessions[0].emit({ type: 'text-delta', delta: 'yo' });
    sessions[0].finish();
    await t.done;
    expect(t.events).toEqual([{ type: 'text-delta', delta: 'yo' }, { type: 'done' }]);
  });
});

describe('PiAdapter persistent session — C1 denial-sink follows the per-turn swap', () => {
  it('a DENIED tool on turn 2 surfaces on turn-2 stream, never on the settled turn-1 stream', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate((c: NormalizedToolCall) =>
      c.name === 'bash' && /\brm\b/.test(String(c.args.command))
        ? { action: 'deny', reason: 'destructive shell command' }
        : { action: 'allow' },
    );

    // Turn 1 runs to completion; capture its events.
    const t1 = drive(adapter.sendPrompt('turn one'));
    await tick();
    sessions[0].finish();
    await t1.done;
    expect(sessions).toHaveLength(1);

    // Turn 2: fire a DENIED tool call mid-turn. The denial-sink is decoupled from
    // the per-turn queue (C1) — the same persistent gate hook must route this to
    // TURN-2's stream, not the captured (now-closed) turn-1 queue.
    const t2 = drive(adapter.sendPrompt('turn two'));
    await tick();
    const decision = await sessions[0].fireToolCall({ id: 'c1', name: 'bash', args: { command: 'rm -rf x' } });
    await tick();
    sessions[0].finish();
    await t2.done;

    expect(decision).toMatchObject({ action: 'deny' });
    expect(sessions).toHaveLength(1); // still one persistent session
    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'c1', reason: 'destructive shell command' });
    // If the sink had been captured per-turn, the denial would have been dropped
    // into the closed turn-1 queue and never appeared anywhere.
    expect(t1.events.some((e) => e.type === 'tool-denied')).toBe(false);
  });

  it('a stream event fired during turn 2 lands on turn-2 stream (subscribe sink also follows the swap)', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));

    const t1 = drive(adapter.sendPrompt('one'));
    await tick();
    sessions[0].finish();
    await t1.done;

    const t2 = drive(adapter.sendPrompt('two'));
    await tick();
    sessions[0].emit({ type: 'text-delta', delta: 'second-turn-token' });
    sessions[0].finish();
    await t2.done;

    expect(t2.events).toContainEqual({ type: 'text-delta', delta: 'second-turn-token' });
    expect(t1.events.some((e) => e.type === 'text-delta')).toBe(false);
  });
});

describe('PiAdapter persistent session — abort keeps the session reusable', () => {
  it('a mid-turn abort ends the turn but does NOT dispose the session; turn N+1 reuses it', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));

    const ac = new AbortController();
    const t1 = drive(adapter.sendPrompt('long running', { signal: ac.signal }));
    await tick();
    ac.abort(); // hard interrupt
    await t1.done;

    expect(sessions[0].aborts).toBe(1); // the interrupt reached the session
    expect(sessions[0].disposed).toBe(false); // but the session survives the turn

    const t2 = drive(adapter.sendPrompt('again'));
    await tick();
    sessions[0].finish();
    await t2.done;

    expect(sessions).toHaveLength(1); // same session
    expect(sessions[0].prompts).toEqual(['long running', 'again']);
  });
});

describe('PiAdapter persistent session — new-conversation recovery (crash isolation)', () => {
  it('a mid-turn session error surfaces, then newConversation rebuilds with the gate re-attached and the next turn works', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate((c: NormalizedToolCall) =>
      /\brm\b/.test(JSON.stringify(c.args)) ? { action: 'deny', reason: 'blocked' } : { action: 'allow' },
    );

    const t1 = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].fail(new Error('session crashed'));
    await t1.done;
    expect(t1.events).toContainEqual({ type: 'error', error: 'session crashed' });

    // Recovery = new-conversation = dispose + rebuild (gate re-attached via a fresh loader factory run).
    await adapter.newConversation();
    expect(sessions[0].disposed).toBe(true); // the crashed session was disposed
    expect(sessions).toHaveLength(2); // a fresh session was built

    // The rebuilt session's gate STILL intercepts — the invariant held across recovery.
    const t2 = drive(adapter.sendPrompt('next'));
    await tick();
    await sessions[1].fireToolCall({ id: 'x', name: 'bash', args: { command: 'rm -rf y' } });
    await tick();
    sessions[1].finish();
    await t2.done;

    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'x', reason: 'blocked' });
  });
});

describe('PiAdapter T2 — context-usage meter feed + manual compact (gate survives)', () => {
  it('emits a context-usage event at turn end when the session has a meter snapshot', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));

    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].meter = { percent: 40, tokens: 8000, contextWindow: 262_144, costUsd: 0 };
    sessions[0].finish();
    await t.done;

    // The context-usage event rides the stream just before done.
    expect(t.events).toContainEqual({
      type: 'context-usage',
      percent: 40,
      tokens: 8000,
      contextWindow: 262_144,
      costUsd: 0,
    });
    expect(t.events.at(-1)).toEqual({ type: 'done' });
  });

  it('emits no context-usage event when there is no snapshot (additive-optional)', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));
    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].finish(); // meter stays undefined
    await t.done;
    expect(t.events.some((e) => e.type === 'context-usage')).toBe(false);
  });

  it('classifies Pi benign compact throws (too small / already compacted) as no-ops, real errors as errors', () => {
    // The live C3 check caught that session.compact() THROWS on a too-small session.
    expect(isBenignCompactError(new Error('Nothing to compact (session too small)'))).toBe(true);
    expect(isBenignCompactError(new Error('Already compacted'))).toBe(true);
    expect(isBenignCompactError(new Error('summarizer request failed: 500'))).toBe(false);
    expect(isBenignCompactError(new Error('network error'))).toBe(false);
  });

  it('adapter.compact() dispatches to the session compact and the gate STILL intercepts after (C3)', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate((c: NormalizedToolCall) =>
      /\brm\b/.test(String(c.args.command)) ? { action: 'deny', reason: 'blocked' } : { action: 'allow' },
    );

    // Establish the session, then compact it (a mutation).
    const t1 = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].finish();
    await t1.done;

    await adapter.compact();
    expect(sessions[0].compacts).toBe(1);
    expect(sessions[0].disposed).toBe(false); // compact does NOT rebuild the session
    expect(sessions).toHaveLength(1); // same persistent session

    // The gate survives the mutation — a denied tool on the next turn still surfaces.
    const t2 = drive(adapter.sendPrompt('after compact'));
    await tick();
    await sessions[0].fireToolCall({ id: 'z', name: 'bash', args: { command: 'rm -rf q' } });
    await tick();
    sessions[0].finish();
    await t2.done;
    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'z', reason: 'blocked' });
  });
});

describe('PiAdapter T4 — model switcher (gate survives setModel/cycleModel)', () => {
  const M = (providerId: string, modelId: string, active: boolean, isLocal = false): ModelInfo => ({
    providerId,
    modelId,
    label: modelId,
    isLocal,
    active,
  });

  function modelAdapter() {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate((c: NormalizedToolCall) =>
      /\brm\b/.test(String(c.args.command)) ? { action: 'deny', reason: 'blocked' } : { action: 'allow' },
    );
    return { adapter, sessions };
  }

  it('lists the available models and reports the active one', async () => {
    const { adapter, sessions } = modelAdapter();
    // build the session by driving a turn, then seed the model list
    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].models = [M('local', 'qwen', true, true), M('anthropic', 'claude', false)];
    sessions[0].finish();
    await t.done;

    const models = await adapter.listModels();
    expect(models.map((m) => m.modelId)).toEqual(['qwen', 'claude']);
    expect((await adapter.currentModel())?.modelId).toBe('qwen');
    expect((await adapter.currentModel())?.isLocal).toBe(true);
  });

  it('setModel switches the active model and the gate STILL intercepts after (C3)', async () => {
    const { adapter, sessions } = modelAdapter();
    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].models = [M('local', 'qwen', true, true), M('anthropic', 'claude', false)];
    sessions[0].finish();
    await t.done;

    const ok = await adapter.setModel('anthropic', 'claude');
    expect(ok).toBe(true);
    expect(sessions[0].setModelCalls).toEqual([['anthropic', 'claude']]);
    expect((await adapter.currentModel())?.modelId).toBe('claude');
    expect(sessions[0].disposed).toBe(false); // setModel does NOT rebuild the session
    expect(sessions).toHaveLength(1);

    // The gate survives the mutation.
    const t2 = drive(adapter.sendPrompt('after'));
    await tick();
    await sessions[0].fireToolCall({ id: 'k', name: 'bash', args: { command: 'rm -rf p' } });
    await tick();
    sessions[0].finish();
    await t2.done;
    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'k', reason: 'blocked' });
  });

  it('setModel returns false for an unknown model id (no change)', async () => {
    const { adapter, sessions } = modelAdapter();
    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].models = [M('local', 'qwen', true, true)];
    sessions[0].finish();
    await t.done;
    expect(await adapter.setModel('nope', 'ghost')).toBe(false);
  });

  it('cycleModel rotates to the next model and the gate STILL intercepts after (C3)', async () => {
    const { adapter, sessions } = modelAdapter();
    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].models = [M('local', 'qwen', true, true), M('anthropic', 'claude', false)];
    sessions[0].finish();
    await t.done;

    const next = await adapter.cycleModel();
    expect(next?.modelId).toBe('claude');
    expect(sessions[0].cycles).toBe(1);
    expect(sessions[0].disposed).toBe(false);

    const t2 = drive(adapter.sendPrompt('after'));
    await tick();
    await sessions[0].fireToolCall({ id: 'k2', name: 'bash', args: { command: 'rm -rf p' } });
    await tick();
    sessions[0].finish();
    await t2.done;
    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'k2', reason: 'blocked' });
  });
});

describe('PiAdapter T5 — thinking-level toggle (gate survives; cycle delegates to the setter)', () => {
  function thinkAdapter() {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate((c: NormalizedToolCall) =>
      /\brm\b/.test(String(c.args.command)) ? { action: 'deny', reason: 'blocked' } : { action: 'allow' },
    );
    return { adapter, sessions };
  }

  async function build(adapter: PiAdapter, sessions: FakeSession[]) {
    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].finish();
    await t.done;
  }

  it('reports the active thinking level + the available levels', async () => {
    const { adapter, sessions } = thinkAdapter();
    await build(adapter, sessions);
    const info = await adapter.thinkingInfo();
    expect(info).toEqual({ level: 'medium', levels: ['low', 'medium', 'high'], supported: true });
  });

  it('setThinkingLevel sets the level and the gate STILL intercepts after (C3)', async () => {
    const { adapter, sessions } = thinkAdapter();
    await build(adapter, sessions);

    await adapter.setThinkingLevel('high');
    expect(sessions[0].thinkingSets).toEqual(['high']);
    expect((await adapter.thinkingInfo()).level).toBe('high');
    expect(sessions[0].disposed).toBe(false);

    const t2 = drive(adapter.sendPrompt('after'));
    await tick();
    await sessions[0].fireToolCall({ id: 'th', name: 'bash', args: { command: 'rm -rf z' } });
    await tick();
    sessions[0].finish();
    await t2.done;
    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'th', reason: 'blocked' });
  });

  it('cycleThinkingLevel DELEGATES to the setter (SELF-VERIFIED) and the gate survives', async () => {
    const { adapter, sessions } = thinkAdapter();
    await build(adapter, sessions);

    const next = await adapter.cycleThinkingLevel();
    expect(next).toBe('high'); // medium -> high
    // The delegation invariant: cycling went THROUGH setThinkingLevel.
    expect(sessions[0].thinkingSets).toContain('high');
    expect(sessions[0].disposed).toBe(false);

    const t2 = drive(adapter.sendPrompt('after'));
    await tick();
    await sessions[0].fireToolCall({ id: 'th2', name: 'bash', args: { command: 'rm -rf z' } });
    await tick();
    sessions[0].finish();
    await t2.done;
    expect(t2.events).toContainEqual({ type: 'tool-denied', id: 'th2', reason: 'blocked' });
  });

  it('cycleThinkingLevel is a no-op (undefined) when the model does not support thinking', async () => {
    const { adapter, sessions } = thinkAdapter();
    await build(adapter, sessions);
    sessions[0].thinking = { level: 'off', levels: [], supported: false };
    expect(await adapter.cycleThinkingLevel()).toBeUndefined();
  });
});

describe('PiAdapter T7 — prompt templates + skills surfaced as command sources', () => {
  it('lists the session prompt templates and skills', async () => {
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: WS, sessionBuilder: builder });
    adapter.setToolCallGate(() => ({ action: 'allow' }));

    const t = drive(adapter.sendPrompt('go'));
    await tick();
    sessions[0].templates = [{ name: 'review', description: 'code review', content: 'Review the diff.' }];
    sessions[0].skills = [{ name: 'deploy', description: 'deploy helper' }];
    sessions[0].finish();
    await t.done;

    expect((await adapter.listPromptTemplates()).map((x) => x.name)).toEqual(['review']);
    expect((await adapter.listPromptTemplates())[0].content).toBe('Review the diff.');
    expect((await adapter.listSkills()).map((x) => x.name)).toEqual(['deploy']);
  });
});

describe('PiAdapter persistent session — workspace-change respawn rebinds the gate to the new root', () => {
  it('a fresh adapter for a new root (the respawn) binds the fail-closed gate to THAT root', async () => {
    // Workspace change stays a sidecar respawn: a new adapter constructed for the
    // new root. With no host gate wired, the fail-closed gate must be bound to the
    // NEW workspaceRoot — an out-of-root write is denied, an in-root write allowed.
    const rootB = mkdtempSync(join(tmpdir(), 'nana-wsB-'));
    const outsideB = join(tmpdir(), `nana-escape-${process.pid}.txt`);
    const { builder, sessions } = makeFakeBuilder();
    const adapter = new PiAdapter({ workspaceRoot: rootB, sessionBuilder: builder });
    // Deliberately NO setToolCallGate — exercise the fail-closed gate bound to rootB.

    const t = drive(adapter.sendPrompt('go'));
    await tick();
    const outOfRoot = await sessions[0].fireToolCall({ id: 'w1', name: 'write', args: { path: outsideB, content: 'x' } });
    const inRoot = await sessions[0].fireToolCall({ id: 'w2', name: 'write', args: { path: join(rootB, 'ok.txt'), content: 'x' } });
    await tick();
    sessions[0].finish();
    await t.done;

    expect(outOfRoot.action).toBe('deny'); // gate is bound to rootB → escape blocked
    expect(inRoot.action).toBe('allow'); // in-root write allowed
  });
});
