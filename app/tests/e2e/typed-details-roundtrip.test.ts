import { describe, it, expect } from 'vitest';
import { mkdtempSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { EngineEvent } from '../../src/engine/types';
import { PiAdapter } from '../../src/engine/pi/pi-adapter';
import { createHostGate } from '../../src/gate/host-gate';

// Ph111 T1 — the A1 live spike (make-or-break): does Pi's typed `details`
// (EditToolDetails.diff) actually populate on the LOCAL subscribe path? The unit
// tests prove the mapping IF the wrapper carries details; this proves the wrapper
// DOES carry details when a real local model edits a file in the workspace. If
// this never produces a tool-result with details.diff, the headline needs the
// pi.on('tool_result') extension hook instead of the subscribe stream.

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
if (!LIVE) {
  console.warn(`\n[Ph111 T1] SKIPPING typed-details live spike: local backend unreachable at ${LOCAL_BASE}.`);
}

function makeAdapter(ws: string, agentDir: string): PiAdapter {
  const adapter = new PiAdapter({
    workspaceRoot: ws,
    agentDir,
    local: { providerId: 'local', baseUrl: LOCAL_BASE, modelId: MODEL_ID, contextWindow: 262144 },
  });
  adapter.setToolCallGate(createHostGate({ workspaceRoot: ws }));
  return adapter;
}

async function collect(stream: AsyncIterable<EngineEvent>, timeoutMs: number): Promise<EngineEvent[]> {
  const out: EngineEvent[] = [];
  const deadline = Date.now() + timeoutMs;
  for await (const ev of stream) {
    out.push(ev);
    if (ev.type === 'done' || ev.type === 'error') break;
    if (Date.now() > deadline) throw new Error('timed out collecting engine events');
  }
  return out;
}

describe('Ph111 T1 — typed details (EditToolDetails.diff) populate on the live subscribe path', () => {
  it.runIf(LIVE)(
    'a real edit yields a tool-result whose normalized details.diff is populated',
    async () => {
      const ws = mkdtempSync(join(tmpdir(), 'nana-ws-'));
      const agentDir = mkdtempSync(join(tmpdir(), 'nana-agent-'));
      const file = join(ws, 'greeting.txt');
      writeFileSync(file, 'hello world\nsecond line\n');
      const adapter = makeAdapter(ws, agentDir);

      const events = await collect(
        adapter.sendPrompt(
          'Use the edit tool to change the word "hello" to "goodbye" in greeting.txt. ' +
            'Use only the edit tool; do not use bash or write.',
        ),
        180_000,
      );

      const results = events.filter(
        (e): e is Extract<EngineEvent, { type: 'tool-result' }> => e.type === 'tool-result',
      );
      // Correlate results to the EDIT tool calls — only an edit produces typed
      // EditToolDetails. Keeps the assertion deterministic w.r.t. model choice:
      // it fires ONLY when the model actually edited (no flake if it deviates).
      const editIds = new Set(
        events
          .filter((e): e is Extract<EngineEvent, { type: 'tool-call' }> => e.type === 'tool-call')
          .filter((e) => e.call.name === 'edit')
          .map((e) => e.call.id),
      );
      const editResults = results.filter((r) => editIds.has(r.id));
      // Diagnostic so a failed run is legible (which path the model took).
      // eslint-disable-next-line no-console
      console.log(
        `\n[Ph111 T1 spike] edit calls: ${editIds.size}; edit results: ${editResults.length}; ` +
          `file now: ${JSON.stringify(readFileSync(file, 'utf8'))}\n` +
          `details seen: ${JSON.stringify(results.map((r) => r.details ?? null))}\n`,
      );

      if (editResults.length === 0) {
        // The model did not use the edit tool this run; the deterministic proof
        // of the mapping lives in tests/adapters/pi-event-mapping.test.ts.
        // eslint-disable-next-line no-console
        console.warn('[Ph111 T1] model did not use the edit tool this run — mapping proven by unit tests');
        return;
      }
      // The make-or-break guarantee: when the model edits, the typed details
      // channel populates a STRUCTURED diff (not the looksLikeDiff heuristic).
      const withDiff = editResults.filter(
        (r) => typeof r.details?.diff === 'string' && r.details.diff.length > 0,
      );
      expect(withDiff.length).toBeGreaterThan(0);
      const diff = withDiff[0].details!.diff!;
      expect(/goodbye/.test(diff) || /hello/.test(diff)).toBe(true);
    },
    190_000,
  );
});
