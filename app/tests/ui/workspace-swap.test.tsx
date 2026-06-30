// @vitest-environment jsdom
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { act, createElement, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { useChatRuntime, type WorkspaceSource } from '../../src/ui/chat-runtime';
import { saveConversation, loadConversation } from '../../src/ui/conversation-store';
import type { EngineAdapter, SendPromptOptions } from '../../src/engine/adapter';
import type { EngineEvent } from '../../src/engine/types';
import type { UiMessage } from '../../src/ui/chat-binding';
import type { WorkspaceInfo } from '../../src/ui/engine-bridge';

// Phase 115, T4 — the SECURITY-CRITICAL path. On a workspace change the thread
// must SWAP (persist the outgoing, load the incoming) so the prior workspace's
// conversation never leaks into the new workspace's fresh gate. A same-root
// re-ready is a no-op, a mid-turn change is deferred (no clobber), and the whole
// swap/restore is display-only — it never sends to the engine (no-bypass).

type HookValue = ReturnType<typeof useChatRuntime>;

function mountHook(engine: EngineAdapter, workspace: WorkspaceSource, sink: { current: HookValue | null }) {
  function Harness() {
    const value = useChatRuntime(engine, workspace);
    useEffect(() => {
      sink.current = value;
    });
    sink.current = value;
    return null;
  }
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  act(() => root.render(createElement(Harness)));
  return { root };
}

async function flush(times = 12) {
  for (let i = 0; i < times; i++) {
    await act(async () => {
      await new Promise((r) => setTimeout(r, 5));
    });
  }
}

/** Streams one completed read tool call -> a `terminal` artifact. */
function readAdapter(): EngineAdapter {
  return {
    id: 'fake',
    setToolCallGate() {},
    async *sendPrompt(): AsyncIterable<EngineEvent> {
      yield { type: 'tool-call', call: { id: 't1', name: 'read', args: { path: 'a.ts' } } };
      yield { type: 'tool-result', id: 't1', result: 'contents' };
      yield { type: 'done' };
    },
  };
}

/** Hangs until aborted (to test mid-turn behavior). */
function hangingAdapter(): EngineAdapter {
  return {
    id: 'fake-hang',
    setToolCallGate() {},
    async *sendPrompt(_p: string, opts: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
      yield { type: 'tool-call', call: { id: 'h1', name: 'bash', args: { command: 'sleep' } } };
      await new Promise<void>((resolve) => {
        if (opts.signal?.aborted) return resolve();
        opts.signal?.addEventListener('abort', () => resolve(), { once: true });
      });
      yield { type: 'error', error: 'aborted' };
      yield { type: 'done' };
    },
  };
}

const wsInfo = (root: string): WorkspaceInfo => ({ root, available: true, sources: [] });

/** A workspace source whose active root can be changed via emit(). */
function dynamicWorkspace(initial: string) {
  let current = wsInfo(initial);
  const listeners = new Set<(w: WorkspaceInfo) => void>();
  const source: WorkspaceSource = {
    get currentWorkspace() {
      return current;
    },
    onWorkspace(l) {
      listeners.add(l);
      if (current) l(current);
      return () => listeners.delete(l);
    },
  };
  return {
    source,
    emit(root: string) {
      current = wsInfo(root);
      listeners.forEach((l) => l(current));
    },
  };
}

const diffThread = (): UiMessage[] => [
  { role: 'assistant', text: '', done: true, toolCalls: [{ id: 'd1', name: 'edit', status: 'done', details: { diff: '+ x' } }] },
];

describe('workspace swap-no-leak + display-only (T4)', () => {
  beforeEach(() => localStorage.clear());

  it('swaps the thread on a workspace change — no stale cross-workspace leak', async () => {
    saveConversation('/ws/r2', diffThread()); // R2 already has a (different) conversation
    const ws = dynamicWorkspace('/ws/r1');
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(readAdapter(), ws.source, sink);
    await flush();
    // a turn in R1 -> a terminal artifact, persisted under R1
    await act(async () => {
      await sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'read' }] });
    });
    await flush();
    expect(sink.current!.artifacts.map((a) => a.kind)).toEqual(['terminal']);
    expect(loadConversation('/ws/r1').length).toBe(2); // R1 persisted

    // switch to R2 -> R1's thread must be GONE from view, R2's diff loaded
    await act(async () => {
      ws.emit('/ws/r2');
    });
    await flush();
    expect(sink.current!.artifacts.map((a) => a.kind)).toEqual(['diff']); // R2 only — no R1 'terminal'
    expect(loadConversation('/ws/r1').length).toBe(2); // R1 still safely persisted
    act(() => root.unmount());
  });

  it('treats a same-root re-ready as a no-op (does not reload / clobber)', async () => {
    const ws = dynamicWorkspace('/ws/r1');
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(readAdapter(), ws.source, sink);
    await flush();
    await act(async () => {
      await sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'read' }] });
    });
    await flush();
    expect(sink.current!.artifacts.map((a) => a.kind)).toEqual(['terminal']);

    // diverge the persisted store, then re-emit the SAME root. A no-op must NOT
    // reload (which would replace the live 'terminal' view with the stored 'diff').
    saveConversation('/ws/r1', diffThread());
    await act(async () => {
      ws.emit('/ws/r1');
    });
    await flush();
    expect(sink.current!.artifacts.map((a) => a.kind)).toEqual(['terminal']); // unchanged — no reload
    act(() => root.unmount());
  });

  it('defers a mid-turn workspace change until the turn settles (no clobber)', async () => {
    saveConversation('/ws/r2', diffThread());
    const ws = dynamicWorkspace('/ws/r1');
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(hangingAdapter(), ws.source, sink);
    await flush();
    await act(async () => {
      void sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'long' }] });
    });
    await flush(3);
    expect(sink.current!.isRunning).toBe(true);

    // change workspace mid-turn -> must be DEFERRED (R2 not loaded yet)
    await act(async () => {
      ws.emit('/ws/r2');
    });
    await flush(2);
    expect(sink.current!.isRunning).toBe(true); // turn untorn
    expect(sink.current!.artifacts.length).toBe(0); // R2 NOT loaded mid-turn

    // settle the turn -> the deferred swap applies
    await act(async () => {
      sink.current!.stop();
    });
    await flush();
    expect(sink.current!.artifacts.map((a) => a.kind)).toEqual(['diff']); // R2 now loaded
    act(() => root.unmount());
  });

  it('swap/restore is display-only — it issues ZERO engine sends', async () => {
    saveConversation('/ws/r1', diffThread());
    saveConversation('/ws/r2', diffThread());
    const sendPrompt = vi.fn(async function* (): AsyncIterable<EngineEvent> {
      yield { type: 'done' };
    });
    const engine: EngineAdapter = { id: 'spy', setToolCallGate() {}, sendPrompt };
    const ws = dynamicWorkspace('/ws/r1');
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(engine, ws.source, sink);
    await flush(); // restore R1
    await act(async () => {
      ws.emit('/ws/r2'); // swap to R2
    });
    await flush();
    expect(sendPrompt).not.toHaveBeenCalled(); // restore + swap never drove the engine
    act(() => root.unmount());
  });
});
