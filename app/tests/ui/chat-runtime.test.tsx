// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { act, createElement, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { useChatRuntime } from '../../src/ui/chat-runtime';
import type { EngineAdapter, SendPromptOptions } from '../../src/engine/adapter';
import type { EngineEvent } from '../../src/engine/types';

// T2 (axis 3): the runtime hook now ALSO surfaces the control state the command
// registry (T1) consumes — isRunning + stop + newConversation — and a
// new-conversation action that aborts any in-flight turn and clears the
// conversation. Conversation state is UI-side only (both adapters are stateless
// across sendPrompt — Pi rebuilds an in-memory session per call, Vercel passes
// only `prompt`), so a fresh conversation is a store clear with NO host reset
// and NO new bridge message (the no-bypass invariant, T5).

type HookValue = ReturnType<typeof useChatRuntime>;

/** Render the real hook, capturing its latest return into `sink` each render. */
function mountHook(engine: EngineAdapter, sink: { current: HookValue | null }) {
  function Harness() {
    const value = useChatRuntime(engine);
    useEffect(() => {
      sink.current = value;
    });
    sink.current = value;
    return null;
  }
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  root.render(createElement(Harness));
  return { root, container };
}

async function flush(times = 12) {
  for (let i = 0; i < times; i++) {
    await act(async () => {
      await new Promise((r) => setTimeout(r, 5));
    });
  }
}

/** A fake adapter that streams a single completed tool call, then done. */
function oneToolCallAdapter(): EngineAdapter {
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

describe('useChatRuntime control surface (T2)', () => {
  it('returns runtime, artifacts, isRunning, stop, newConversation', async () => {
    const sink: { current: HookValue | null } = { current: null };
    const { root } = mountHook(oneToolCallAdapter(), sink);
    await act(async () => {});

    const v = sink.current!;
    expect(v.runtime).toBeTruthy();
    expect(Array.isArray(v.artifacts)).toBe(true);
    expect(typeof v.isRunning).toBe('boolean');
    expect(typeof v.stop).toBe('function');
    expect(typeof v.newConversation).toBe('function');

    act(() => root.unmount());
  });

  it('new-conversation clears the conversation (artifacts emptied) after a turn', async () => {
    const sink: { current: HookValue | null } = { current: null };
    const { root } = mountHook(oneToolCallAdapter(), sink);
    await act(async () => {});

    // Drive a turn through the real assistant-ui runtime → onNew → fake stream.
    await act(async () => {
      await sink.current!.runtime.thread.append({
        role: 'user',
        content: [{ type: 'text', text: 'read a.ts' }],
      });
    });
    await flush();

    // The completed tool call surfaced as an artifact => the store has content.
    expect(sink.current!.artifacts.length).toBe(1);
    expect(sink.current!.isRunning).toBe(false);

    // New conversation wipes the store → the artifact feed empties.
    await act(async () => {
      sink.current!.newConversation();
    });
    await flush(2);
    expect(sink.current!.artifacts.length).toBe(0);

    act(() => root.unmount());
  });

  it('stop() aborts an in-flight turn (the adapter sees an aborted signal)', async () => {
    let capturedSignal: AbortSignal | undefined;
    const hanging: EngineAdapter = {
      id: 'fake-hang',
      setToolCallGate() {},
      async *sendPrompt(_p: string, opts: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
        capturedSignal = opts.signal;
        yield { type: 'tool-call', call: { id: 'h1', name: 'bash', args: { command: 'sleep' } } };
        // hang until aborted
        await new Promise<void>((resolve) => {
          if (opts.signal?.aborted) return resolve();
          opts.signal?.addEventListener('abort', () => resolve(), { once: true });
        });
        yield { type: 'error', error: 'aborted' };
        yield { type: 'done' };
      },
    };

    const sink: { current: HookValue | null } = { current: null };
    const { root } = mountHook(hanging, sink);
    await act(async () => {});

    await act(async () => {
      void sink.current!.runtime.thread.append({
        role: 'user',
        content: [{ type: 'text', text: 'long task' }],
      });
    });
    await flush(3);
    expect(sink.current!.isRunning).toBe(true);

    await act(async () => {
      sink.current!.stop();
    });
    await flush();

    expect(capturedSignal?.aborted).toBe(true);
    expect(sink.current!.isRunning).toBe(false);

    act(() => root.unmount());
  });
});
