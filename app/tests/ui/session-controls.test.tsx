// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { act, createElement, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { BridgeClient, type TauriBridge, type SessionInfo } from '../../src/ui/engine-bridge';
import type { HostOutbound } from '../../src/host/engine-host';
import { ModelChip, ThinkingChip, Chip, useSessionControls } from '../../src/ui/session-controls';
import type { ModelInfo, ThinkingInfo } from '../../src/engine/types';

// Phase 119 T4 — the runtime model picker wiring: the bridge senders + session-info
// routing + the local-model probe surfacing, and the presentational chip.

function mockTauri() {
  const sent: Record<string, unknown>[] = [];
  let handler: ((p: string) => void) | undefined;
  const tauri: TauriBridge = {
    invoke: async (cmd, args) => {
      if (cmd === 'engine_send') sent.push(JSON.parse(String(args.line)) as Record<string, unknown>);
      return undefined;
    },
    listen: async (_e, h) => {
      handler = h;
      return () => {
        handler = undefined;
      };
    },
  };
  return { tauri, sent, emit: (m: HostOutbound) => handler?.(JSON.stringify(m)) };
}

const MODEL: ModelInfo = { providerId: 'local', modelId: 'qwen', label: 'Qwen 3.6', isLocal: true, active: true };

describe('BridgeClient model wiring (Ph119 T4)', () => {
  it('cycle/set model + thinking + requestSessionInfo send the right host inbounds', async () => {
    const m = mockTauri();
    const client = new BridgeClient(m.tauri);
    await client.start();
    await client.requestCycleModel();
    await client.requestSetModel('anthropic', 'claude');
    await client.requestCycleThinking();
    await client.requestSetThinking('high');
    await client.requestSessionInfo();
    expect(m.sent).toEqual([
      { type: 'cycle-model' },
      { type: 'set-model', providerId: 'anthropic', modelId: 'claude' },
      { type: 'cycle-thinking' },
      { type: 'set-thinking', level: 'high' },
      { type: 'request-session-info' },
    ]);
  });

  it('routes session-info to onSessionInfo listeners + caches the latest', async () => {
    const m = mockTauri();
    const client = new BridgeClient(m.tauri);
    await client.start();
    const seen: SessionInfo[] = [];
    client.onSessionInfo((s) => seen.push(s));
    m.emit({
      type: 'session-info',
      model: MODEL,
      models: [MODEL],
      thinking: null,
      templates: [{ name: 'review', description: 'code review', content: 'Review the diff.' }],
      skills: [{ name: 'deploy', description: 'deploy helper' }],
    });
    expect(seen).toHaveLength(1);
    expect(seen[0].model?.modelId).toBe('qwen');
    expect(seen[0].templates.map((t) => t.name)).toEqual(['review']); // T7: command sources route through
    expect(seen[0].skills.map((s) => s.name)).toEqual(['deploy']);
    expect(client.currentSessionInfo?.model?.modelId).toBe('qwen');
  });

  it('surfaces the local-model probe from ready into workspace info', async () => {
    const m = mockTauri();
    const client = new BridgeClient(m.tauri);
    await client.start();
    m.emit({
      type: 'ready',
      workspaceRoot: '/ws',
      available: true,
      sources: [],
      localModel: { ok: false, models: [], detail: 'unreachable' },
    });
    expect(client.currentWorkspace?.localModel).toEqual({ ok: false, models: [], detail: 'unreachable' });
  });
});

describe('useSessionControls hook (Ph119 T4)', () => {
  it('requests session-info at mount and exposes the current model + a cycle action', async () => {
    const m = mockTauri();
    const client = new BridgeClient(m.tauri);
    await client.start();

    const sink = { current: null as ReturnType<typeof useSessionControls> | null };
    function Harness() {
      const v = useSessionControls(client);
      useEffect(() => {
        sink.current = v;
      });
      sink.current = v;
      return null;
    }
    const container = document.createElement('div');
    document.body.appendChild(container);
    const root = createRoot(container);
    await act(async () => {
      root.render(createElement(Harness));
    });

    // Mount triggered a request-session-info…
    expect(m.sent.some((l) => l.type === 'request-session-info')).toBe(true);
    // …and a subsequent session-info flows into the hook.
    const thinking: ThinkingInfo = { level: 'medium', levels: ['low', 'medium', 'high'], supported: true };
    await act(async () => {
      m.emit({ type: 'session-info', model: MODEL, models: [MODEL], thinking, templates: [], skills: [] });
    });
    expect(sink.current!.model?.modelId).toBe('qwen');
    expect(sink.current!.thinking?.level).toBe('medium');

    // cycleModel + cycleThinking send their inbounds.
    await act(async () => {
      sink.current!.cycleModel();
      sink.current!.cycleThinking();
    });
    expect(m.sent.some((l) => l.type === 'cycle-model')).toBe(true);
    expect(m.sent.some((l) => l.type === 'cycle-thinking')).toBe(true);

    act(() => root.unmount());
  });
});

describe('ModelChip / Chip (Ph119 T4)', () => {
  it('renders the model label + local tag, and a placeholder when unknown', () => {
    const html = renderToStaticMarkup(createElement(ModelChip, { model: MODEL, onCycle: () => {} }));
    expect(html).toContain('Qwen 3.6');
    expect(html).toContain('local');
    expect(html).toContain('data-testid="model-chip"');

    const none = renderToStaticMarkup(createElement(ModelChip, { model: null, onCycle: () => {} }));
    expect(none).toContain('—');
  });

  it('a clickable chip renders as a button (reused by the T5 thinking toggle)', () => {
    const html = renderToStaticMarkup(
      createElement(Chip, { label: 'thinking', value: 'high', onClick: () => {}, testId: 'c' }),
    );
    expect(html).toContain('<button');
    expect(html).toContain('high');
  });
});

describe('ThinkingChip (Ph119 T5)', () => {
  it('renders the level as a clickable button when the model supports thinking', () => {
    const thinking: ThinkingInfo = { level: 'high', levels: ['low', 'medium', 'high'], supported: true };
    const html = renderToStaticMarkup(createElement(ThinkingChip, { thinking, onCycle: () => {} }));
    expect(html).toContain('data-testid="thinking-chip"');
    expect(html).toContain('high');
    expect(html).toContain('<button'); // clickable when supported
  });

  it('renders "off" as an INERT span when the model does not support thinking', () => {
    const thinking: ThinkingInfo = { level: 'medium', levels: [], supported: false };
    const html = renderToStaticMarkup(createElement(ThinkingChip, { thinking, onCycle: () => {} }));
    expect(html).toContain('off'); // not applicable → shown as off
    expect(html).not.toContain('<button'); // inert — no misleading no-op click
  });

  it('renders a placeholder before the first session-info (null)', () => {
    const html = renderToStaticMarkup(createElement(ThinkingChip, { thinking: null, onCycle: () => {} }));
    expect(html).toContain('—');
  });
});
