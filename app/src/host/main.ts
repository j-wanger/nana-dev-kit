import { createInterface } from 'node:readline';
import { resolve } from 'node:path';
import { VercelAdapter } from '../engine/vercel/vercel-adapter';
import { PiAdapter } from '../engine/pi/pi-adapter';
import type { EngineAdapter } from '../engine/adapter';
import { createHostGate } from '../gate/host-gate';
import { CheckpointStore } from '../gate/checkpoint/checkpoint';
import { EngineHost, type HostInbound, type HostOutbound } from './engine-host';

// The Node engine-host SIDECAR entry (Phase 109, T6). The Tauri Rust shell spawns
// this as `node engine-host.cjs`; it reads HostInbound JSON lines from stdin and
// writes HostOutbound JSON lines to stdout (one per line). All real wiring lives
// here; EngineHost holds the transport-agnostic logic (unit-tested separately).
// Defaults to a LOCAL OpenAI-compatible backend (no key/billing/ToS — the Ph108
// provider pivot); override via env.

function buildAdapter(workspaceRoot: string): EngineAdapter {
  const baseUrl = process.env.NANA_LOCAL_BASE_URL ?? 'http://localhost:8080/v1';
  const modelId = process.env.NANA_MODEL_ID ?? 'local-model';
  const engine = process.env.NANA_ENGINE ?? 'vercel';
  if (engine === 'pi') {
    return new PiAdapter({
      workspaceRoot,
      local: { providerId: 'local', baseUrl, modelId, contextWindow: 262144 },
    });
  }
  return new VercelAdapter({ workspaceRoot, baseUrl, modelId });
}

function main(): void {
  const workspaceRoot = resolve(process.env.NANA_WORKSPACE ?? process.cwd());
  const checkpoint = new CheckpointStore();
  const send = (msg: HostOutbound): void => {
    process.stdout.write(`${JSON.stringify(msg)}\n`);
  };

  const host = new EngineHost({
    adapter: buildAdapter(workspaceRoot),
    workspaceRoot,
    baseGate: createHostGate({ workspaceRoot }),
    send,
    snapshot: (p) => checkpoint.snapshot(p),
    revert: (p) => checkpoint.revert(p),
  });

  const rl = createInterface({ input: process.stdin });
  rl.on('line', (line) => {
    const trimmed = line.trim();
    if (!trimmed) return;
    let msg: HostInbound;
    try {
      msg = JSON.parse(trimmed) as HostInbound;
    } catch {
      send({ type: 'error', message: `bad inbound line: ${trimmed.slice(0, 80)}` });
      return;
    }
    void host
      .handle(msg)
      .catch((e) => send({ type: 'error', message: e instanceof Error ? e.message : String(e) }));
  });

  send({ type: 'ready' });
}

main();
