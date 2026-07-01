import { createInterface } from 'node:readline';
import { resolve } from 'node:path';
import { buildAdapter } from './build-adapter';
import { createHostGate } from '../gate/host-gate';
import { CheckpointStore } from '../gate/checkpoint/checkpoint';
import { EngineHost, type HostInbound, type HostOutbound } from './engine-host';
import { assembleContext, type ContextSource } from '../context/assembly';
import { SpendCeiling } from '../control/spend';
import { probeLocalEndpoint } from '../engine/pi/pi-adapter';
import { MemoryMount } from '../memory/mcp-memory';
import { McpMemoryRetriever } from '../context/memory-context';

// The Node engine-host SIDECAR entry (Phase 109, T6). The Tauri Rust shell spawns
// this as `node engine-host.mjs`; it reads HostInbound JSON lines from stdin and
// writes HostOutbound JSON lines to stdout (one per line). All real wiring lives
// here; EngineHost holds the transport-agnostic logic (unit-tested separately).
// Engine selection (Pi default, Vercel fallback) lives in ./build-adapter so it
// is importable by tests without main()'s side effects.

async function main(): Promise<void> {
  const workspaceRoot = resolve(process.env.NANA_WORKSPACE ?? process.cwd());
  const checkpoint = new CheckpointStore();
  const send = (msg: HostOutbound): void => {
    process.stdout.write(`${JSON.stringify(msg)}\n`);
  };

  // Phase 119 T2: an OPTIONAL enforced spend ceiling, wired only when
  // NANA_SPEND_CEILING (USD) is set. The engine reports the authoritative
  // cumulative cost via the meter feed; the host pauses a new turn once the
  // ceiling is exceeded. Unset (and on the local $0 model) it is absent → no
  // change. The price table is empty here because the ceiling is reconciled
  // against Pi's own cost, not re-derived from tokens.
  const ceilingEnv = Number(process.env.NANA_SPEND_CEILING);
  const spendCeiling =
    Number.isFinite(ceilingEnv) && ceilingEnv > 0 ? new SpendCeiling(ceilingEnv, {}) : undefined;

  // Phase 119 T8 (A3 safe default): host-orchestrated memory retrieval. Lazy — the
  // MemoryMount connects on the first search, so startup is NOT blocked; the
  // retriever fails open + self-disables if the server is unavailable. Model-facing
  // memory is NOT wired (no gate carve-out). Opt out with NANA_NO_MEMORY=1.
  const memory =
    process.env.NANA_NO_MEMORY === '1'
      ? undefined
      : // Cap the first-turn spawn/connect (4s) so a missing/slow memory server
        // doesn't stall the first prompt; the retriever adds its own 5s retrieval
        // cap and self-disables after one failure (Ph119 review nit 2).
        new McpMemoryRetriever(new MemoryMount({ startupTimeoutMs: 4000 }));

  const host = new EngineHost({
    adapter: buildAdapter(workspaceRoot),
    workspaceRoot,
    baseGate: createHostGate({ workspaceRoot }),
    send,
    snapshot: (p) => checkpoint.snapshot(p),
    revert: (p) => checkpoint.revert(p),
    spendCeiling,
    memory,
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

  // Snapshot the active workspace + project-blind state for the surface (T5). The
  // per-turn assembly (EngineHost) re-reads the files; this one-shot read only
  // feeds the header which file(s) were found and whether the agent is running
  // project-blind. Defensive: a read failure here must not stop the window from
  // becoming ready (the per-turn path surfaces the real error loudly).
  let available = false;
  let sources: ContextSource[] = [];
  try {
    const a = assembleContext(workspaceRoot);
    available = a.available;
    sources = a.sources;
  } catch {
    /* leave project-blind; per-turn assembly reports the real failure */
  }

  // Ph119 T4 — launch-time local-endpoint probe. On the default local backend,
  // warn the surface if the model is down/unreachable (the #1 "nothing happens"
  // failure). Fails fast (a refused connection is near-instant; the 2s cap only
  // bites a slow server) and never throws — a down endpoint is a clean ok:false.
  let localModel: { ok: boolean; models: string[]; detail?: string } | undefined;
  const engine = process.env.NANA_ENGINE ?? 'pi';
  if (engine === 'pi' || engine === 'vercel') {
    const baseUrl = process.env.NANA_LOCAL_BASE_URL ?? 'http://localhost:8080/v1';
    localModel = await probeLocalEndpoint(baseUrl);
  }

  send({ type: 'ready', workspaceRoot, available, sources, localModel });
}

void main();
