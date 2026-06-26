import { describe, it, expect, vi } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { NoopAdapter } from '../src/engine/noop-adapter';
import type { EngineAdapter } from '../src/engine/adapter';
import type { EngineEvent, NormalizedToolCall, ToolCallGate } from '../src/engine/types';

const here = dirname(fileURLToPath(import.meta.url));

async function collect(stream: AsyncIterable<EngineEvent>): Promise<EngineEvent[]> {
  const out: EngineEvent[] = [];
  for await (const ev of stream) out.push(ev);
  return out;
}

describe('EngineAdapter contract', () => {
  it('NoopAdapter structurally satisfies the EngineAdapter interface', () => {
    const adapter: EngineAdapter = new NoopAdapter();
    expect(typeof adapter.id).toBe('string');
    expect(typeof adapter.setToolCallGate).toBe('function');
    expect(typeof adapter.sendPrompt).toBe('function');
  });

  it('streams an echo of the prompt and terminates with done', async () => {
    const adapter = new NoopAdapter();
    const events = await collect(adapter.sendPrompt('hello'));
    expect(events.some((e) => e.type === 'text-delta' && e.delta.includes('hello'))).toBe(true);
    expect(events.at(-1)).toEqual({ type: 'done' });
  });

  it('routes every tool call through the host gate BEFORE the side effect (allow)', async () => {
    const sideEffect = vi.fn(() => 'ran');
    const call: NormalizedToolCall = { id: 't1', name: 'write', args: { path: 'a.txt' } };
    const adapter = new NoopAdapter({ scriptedTools: [{ call, run: sideEffect }] });

    const seen: NormalizedToolCall[] = [];
    const gate: ToolCallGate = (c) => {
      seen.push(c);
      return { action: 'allow' };
    };
    adapter.setToolCallGate(gate);

    const events = await collect(adapter.sendPrompt('go'));
    expect(seen).toEqual([call]); // gate was consulted
    expect(sideEffect).toHaveBeenCalledOnce(); // allowed -> ran
    expect(events.some((e) => e.type === 'tool-result' && e.id === 't1')).toBe(true);
  });

  it('a denied tool call never runs its side effect (the load-bearing invariant)', async () => {
    const sideEffect = vi.fn(() => 'ran');
    const call: NormalizedToolCall = { id: 't2', name: 'bash', args: { cmd: 'rm -rf /' } };
    const adapter = new NoopAdapter({ scriptedTools: [{ call, run: sideEffect }] });
    adapter.setToolCallGate(() => ({ action: 'deny', reason: 'destructive' }));

    const events = await collect(adapter.sendPrompt('go'));
    expect(sideEffect).not.toHaveBeenCalled(); // side effect blocked pre-execution
    const denied = events.find((e) => e.type === 'tool-denied');
    expect(denied).toMatchObject({ type: 'tool-denied', id: 't2', reason: 'destructive' });
    expect(events.some((e) => e.type === 'tool-result')).toBe(false);
  });

  it('a modify decision rewrites the args the side effect receives', async () => {
    const received: Record<string, unknown>[] = [];
    const call: NormalizedToolCall = { id: 't3', name: 'write', args: { path: 'a.txt' } };
    const adapter = new NoopAdapter({
      scriptedTools: [
        {
          call,
          run: (args) => {
            received.push(args);
            return 'ok';
          },
        },
      ],
    });
    adapter.setToolCallGate(() => ({ action: 'modify', args: { path: 'safe/a.txt' } }));

    await collect(adapter.sendPrompt('go'));
    expect(received).toEqual([{ path: 'safe/a.txt' }]); // original args discarded
  });

  it('honors an already-aborted signal without running tools', async () => {
    const sideEffect = vi.fn(() => 'ran');
    const call: NormalizedToolCall = { id: 't4', name: 'bash', args: {} };
    const adapter = new NoopAdapter({ scriptedTools: [{ call, run: sideEffect }] });
    const controller = new AbortController();
    controller.abort();

    const events = await collect(adapter.sendPrompt('go', { signal: controller.signal }));
    expect(sideEffect).not.toHaveBeenCalled();
    expect(events.at(-1)).toEqual({ type: 'error', error: 'aborted' });
  });

  it('the Tauri build target exists (src-tauri scaffold present)', () => {
    const cargo = resolve(here, '../src-tauri/Cargo.toml');
    const conf = resolve(here, '../src-tauri/tauri.conf.json');
    expect(existsSync(cargo)).toBe(true);
    expect(existsSync(conf)).toBe(true);
    const confJson = JSON.parse(readFileSync(conf, 'utf8'));
    expect(confJson.build).toBeTruthy(); // a build target is declared
  });
});
