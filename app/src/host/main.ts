import { createInterface } from 'node:readline';
import { resolve } from 'node:path';
import { buildAdapter } from './build-adapter';
import { createHostGate } from '../gate/host-gate';
import { CheckpointStore } from '../gate/checkpoint/checkpoint';
import { EngineHost, type HostInbound, type HostOutbound } from './engine-host';
import { assembleContext, type ContextSource } from '../context/assembly';

// The Node engine-host SIDECAR entry (Phase 109, T6). The Tauri Rust shell spawns
// this as `node engine-host.mjs`; it reads HostInbound JSON lines from stdin and
// writes HostOutbound JSON lines to stdout (one per line). All real wiring lives
// here; EngineHost holds the transport-agnostic logic (unit-tested separately).
// Engine selection (Pi default, Vercel fallback) lives in ./build-adapter so it
// is importable by tests without main()'s side effects.

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

  send({ type: 'ready', workspaceRoot, available, sources });
}

main();
