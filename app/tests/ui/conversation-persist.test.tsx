// @vitest-environment jsdom
import { describe, it, expect, beforeEach } from 'vitest';
import { act, createElement, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { useChatRuntime, type WorkspaceSource } from '../../src/ui/chat-runtime';
import { saveConversation, loadConversation } from '../../src/ui/conversation-store';
import type { EngineAdapter } from '../../src/engine/adapter';
import type { EngineEvent } from '../../src/engine/types';
import type { UiMessage } from '../../src/ui/chat-binding';
import type { WorkspaceInfo } from '../../src/ui/engine-bridge';

// Phase 115, T3 — persist-on-settle + restore-on-first-ready + clear-on-new, with
// an OPTIONAL workspace source. The existing chat-runtime tests (no workspace arg)
// must stay green: persistence is disabled when no source is supplied.

type HookValue = ReturnType<typeof useChatRuntime>;

function mountHook(
  engine: EngineAdapter,
  workspace: WorkspaceSource | undefined,
  sink: { current: HookValue | null },
) {
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

/** An adapter that COUNTS every sendPrompt — proves restore issues zero engine sends. */
function countingAdapter(counter: { sends: number }): EngineAdapter {
  return {
    id: 'fake',
    setToolCallGate() {},
    async *sendPrompt(): AsyncIterable<EngineEvent> {
      counter.sends++;
      yield { type: 'done' };
    },
  };
}

const wsInfo = (root: string): WorkspaceInfo => ({ root, available: true, sources: [] });

/** A source that emits a known root immediately (like the bridge after a ready). */
function staticWorkspace(root: string): WorkspaceSource {
  const info = wsInfo(root);
  return {
    get currentWorkspace() {
      return info;
    },
    onWorkspace(l) {
      l(info);
      return () => {};
    },
  };
}

/** A source that knows no workspace yet (pre-ready) and never emits. */
function blindWorkspace(): WorkspaceSource {
  return {
    get currentWorkspace() {
      return null;
    },
    onWorkspace() {
      return () => {};
    },
  };
}

const convKeys = () => Object.keys(localStorage).filter((k) => k.startsWith('nana.conv.v1:'));

describe('conversation persistence wiring (T3)', () => {
  beforeEach(() => localStorage.clear());

  it('restores the stored thread for the workspace on first ready', async () => {
    const seeded: UiMessage[] = [
      {
        role: 'assistant',
        text: 'prior',
        done: true,
        toolCalls: [{ id: 'e1', name: 'edit', status: 'done', details: { diff: '+ hi' } }],
      },
    ];
    saveConversation('/ws/a', seeded);
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), staticWorkspace('/ws/a'), sink);
    await flush();
    // the restored edit tool call surfaces as a diff artifact => messages were loaded
    expect(sink.current!.artifacts.length).toBe(1);
    expect(sink.current!.artifacts[0].kind).toBe('diff');
    act(() => root.unmount());
  });

  it('persists the conversation after a turn settles', async () => {
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), staticWorkspace('/ws/a'), sink);
    await flush();
    await act(async () => {
      await sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'read a.ts' }] });
    });
    await flush();
    const persisted = loadConversation('/ws/a');
    expect(persisted.length).toBe(2); // user + assistant
    expect((persisted[0] as { role: string }).role).toBe('user');
    act(() => root.unmount());
  });

  it('newConversation clears the persisted entry for the active workspace', async () => {
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), staticWorkspace('/ws/a'), sink);
    await flush();
    await act(async () => {
      await sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'read a.ts' }] });
    });
    await flush();
    expect(loadConversation('/ws/a').length).toBe(2);
    await act(async () => {
      sink.current!.newConversation();
    });
    await flush(2);
    expect(loadConversation('/ws/a')).toEqual([]);
    expect(sink.current!.artifacts.length).toBe(0);
    act(() => root.unmount());
  });

  it('does NOT persist under a null key (workspace unknown before first ready)', async () => {
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), blindWorkspace(), sink);
    await flush();
    await act(async () => {
      await sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'read a.ts' }] });
    });
    await flush();
    expect(convKeys()).toEqual([]); // nothing written under any conversation key
    act(() => root.unmount());
  });

  it('with NO workspace source, persistence is disabled (no writes)', async () => {
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), undefined, sink);
    await flush();
    await act(async () => {
      await sink.current!.runtime.thread.append({ role: 'user', content: [{ type: 'text', text: 'read a.ts' }] });
    });
    await flush();
    expect(convKeys()).toEqual([]);
    act(() => root.unmount());
  });
});

describe('restart-divergence marker — restore DISPLAY-ONLY + reset marker (Ph119 T3, A2)', () => {
  beforeEach(() => localStorage.clear());

  const seeded: UiMessage[] = [{ role: 'assistant', text: 'prior thread', done: true, toolCalls: [] }];

  it('restoring a NON-EMPTY thread issues ZERO engine sends and flags the divergence marker', async () => {
    saveConversation('/ws/a', seeded);
    const counter = { sends: 0 };
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(countingAdapter(counter), staticWorkspace('/ws/a'), sink);
    await flush();
    // The load-bearing no-bypass invariant: a restore is a localStorage read, never
    // an engine send. The persistent engine is fresh, so nothing replays into it.
    expect(counter.sends).toBe(0);
    // The thread is displayed against that fresh engine → the marker is shown.
    expect(sink.current!.restoredNotice).toBe(true);
    act(() => root.unmount());
  });

  it('restoring an EMPTY workspace (no prior thread) shows NO marker — there is no divergence', async () => {
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), staticWorkspace('/ws/empty'), sink);
    await flush();
    expect(sink.current!.restoredNotice).toBe(false);
    act(() => root.unmount());
  });

  it('newConversation clears the marker (engine + display both reset — no divergence)', async () => {
    saveConversation('/ws/a', seeded);
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(oneToolCallAdapter(), staticWorkspace('/ws/a'), sink);
    await flush();
    expect(sink.current!.restoredNotice).toBe(true);
    await act(async () => {
      sink.current!.newConversation();
    });
    await flush(2);
    expect(sink.current!.restoredNotice).toBe(false);
    act(() => root.unmount());
  });
});

describe('submitPrompt goes through the gated turn path (Ph119 T7 no-bypass)', () => {
  beforeEach(() => localStorage.clear());

  it('a prompt-template submit drives engine.sendPrompt (the gated path), like the composer', async () => {
    const counter = { sends: 0 };
    const sink = { current: null as HookValue | null };
    const { root } = mountHook(countingAdapter(counter), staticWorkspace('/ws/a'), sink);
    await flush();
    // submitPrompt is what a prompt-template / skill palette command calls.
    await act(async () => {
      sink.current!.submitPrompt('Please review the diff.');
    });
    await flush();
    // It ran a real turn THROUGH engine.sendPrompt — no un-gated side channel.
    expect(counter.sends).toBe(1);
    act(() => root.unmount());
  });
});
