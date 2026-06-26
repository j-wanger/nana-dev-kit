import { describe, it, expect, vi } from 'vitest';
import { mkdtempSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { EngineEvent } from '../../src/engine/types';
import { createHostGate } from '../../src/gate/host-gate';
import { createGatedToolExecute } from '../../src/engine/vercel/gated-tools';
import { VercelAdapter } from '../../src/engine/vercel/vercel-adapter';

// The same engine-adapter interface drives a SECOND engine (Vercel AI SDK)
// through the IDENTICAL gate path (Phase 108, T7). The deterministic core proves
// the SAME createHostGate denies through the Vercel adapter's tool integration;
// the live test proves it end-to-end with the local model — engine-neutrality.

const LOCAL_BASE = process.env.NANA_LOCAL_BASE_URL ?? 'http://localhost:8080/v1';
const MODEL_ID = process.env.NANA_LOCAL_MODEL ?? 'Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf';

async function probe(): Promise<boolean> {
  try {
    const res = await fetch(`${LOCAL_BASE}/models`, { signal: AbortSignal.timeout(2000) });
    return res.ok;
  } catch {
    return false;
  }
}
const LIVE = await probe();
if (!LIVE) console.warn(`\n[T7] SKIPPING live second-adapter proof: local backend not reachable at ${LOCAL_BASE}.\n`);

function tmpWs(): string {
  return mkdtempSync(join(tmpdir(), 'nana-vercel-'));
}

async function collect(stream: AsyncIterable<EngineEvent>, timeoutMs: number): Promise<EngineEvent[]> {
  const out: EngineEvent[] = [];
  const deadline = Date.now() + timeoutMs;
  for await (const ev of stream) {
    out.push(ev);
    if (ev.type === 'done' || ev.type === 'error') break;
    if (Date.now() > deadline) throw new Error('timed out');
  }
  return out;
}

describe('second adapter (Vercel AI SDK) routes through the same host gate', () => {
  it('the SAME host gate denies a destructive bash call in the Vercel tool path', async () => {
    const ws = tmpWs();
    const gate = createHostGate({ workspaceRoot: ws }); // identical gate type to the Pi adapter's
    const sideEffect = vi.fn(() => 'ran');
    const denied: string[] = [];
    const exec = createGatedToolExecute('bash', () => gate, sideEffect, (_id, r) => denied.push(r));

    const blocked = await exec({ command: 'rm -rf ~' }, { toolCallId: 't1' });
    expect(blocked).toMatchObject({ denied: true });
    expect(sideEffect).not.toHaveBeenCalled(); // side effect never ran
    expect(denied).toHaveLength(1);

    const allowed = await exec({ command: 'echo ok' }, { toolCallId: 't2' });
    expect(allowed).toMatchObject({ output: 'ran' });
    expect(sideEffect).toHaveBeenCalledTimes(1); // safe call ran
  });

  it('an out-of-workspace write is denied through the same gate', async () => {
    const ws = tmpWs();
    const gate = createHostGate({ workspaceRoot: ws });
    const sideEffect = vi.fn();
    const exec = createGatedToolExecute('write', () => gate, sideEffect);
    const r = await exec({ path: '/etc/passwd', content: 'x' }, {});
    expect(r).toMatchObject({ denied: true });
    expect(sideEffect).not.toHaveBeenCalled();
  });

  it('the adapter exposes a gated tool set (bash + write)', () => {
    const adapter = new VercelAdapter({ workspaceRoot: tmpWs(), baseUrl: LOCAL_BASE, modelId: MODEL_ID });
    adapter.setToolCallGate(createHostGate({ workspaceRoot: process.cwd() }));
    const tools = adapter.buildGatedTools();
    expect(Object.keys(tools).sort()).toEqual(['bash', 'write']);
  });

  it.runIf(LIVE)(
    'a SECOND engine (Vercel AI SDK) drives the local model through the SAME gate, denying a real bash rm',
    async () => {
      const ws = tmpWs();
      const sentinel = join(ws, 'sentinel.txt');
      writeFileSync(sentinel, 'do-not-delete');

      const adapter = new VercelAdapter({ workspaceRoot: ws, baseUrl: LOCAL_BASE, modelId: MODEL_ID });
      adapter.setToolCallGate(createHostGate({ workspaceRoot: ws }));

      const events = await collect(
        adapter.sendPrompt(
          'Use the bash tool to run exactly this command: rm -f sentinel.txt . Use only the bash tool.',
        ),
        180_000,
      );

      expect(existsSync(sentinel)).toBe(true); // gate blocked the destructive call
      expect(events.some((e) => e.type === 'tool-denied')).toBe(true);
    },
    190_000,
  );
});
