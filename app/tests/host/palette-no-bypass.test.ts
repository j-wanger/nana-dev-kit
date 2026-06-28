import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';

// T5 (axis 3) — the no-bypass invariant. The command palette + keyboard layer
// must add NO new privileged path to the host. Two structural guards (the
// Ph112 no-bypass discipline, source-text asserted so a future regression trips
// it): (1) the host's inbound message contract did not grow a gate/approval
// channel; (2) the new UI command modules cannot reach the host except through
// injected ctx callbacks — they do not import the bridge/transport at all.

const SRC = join(__dirname, '../../src');

function read(rel: string): string {
  return readFileSync(join(SRC, rel), 'utf8');
}

describe('palette no-bypass invariant (T5)', () => {
  it('HostInbound union is unchanged (or grew only by a benign non-gate `reset`)', () => {
    const src = read('host/engine-host.ts');
    // Bound the union by the next declaration so the `;` field-separators inside
    // each member object don't truncate the capture.
    const m = src.match(/export type HostInbound =([\s\S]*?)export type HostOutbound/);
    expect(m, 'HostInbound union must be findable').toBeTruthy();
    const block = m![1];
    const types = Array.from(block.matchAll(/type:\s*'([^']+)'/g)).map((x) => x[1]);

    const ORIGINAL = ['prompt', 'gate-verdict', 'revert', 'interrupt'];
    // every original inbound message still present
    for (const t of ORIGINAL) expect(types).toContain(t);
    // nothing outside the allowed set (the only permitted growth is a benign `reset`)
    const ALLOWED = new Set([...ORIGINAL, 'reset']);
    for (const t of types) expect(ALLOWED.has(t), `unexpected HostInbound member: ${t}`).toBe(true);
    // the ONLY gate/approval inbound is the pre-existing gate-verdict — no new one
    const gateLike = types.filter((t) => /gate|approv|verdict|allow|deny|confirm/i.test(t));
    expect(gateLike).toEqual(['gate-verdict']);
  });

  it('the new command modules do NOT import the bridge/transport (callbacks-only reach)', () => {
    for (const f of ['ui/commands.ts', 'ui/command-palette.tsx', 'ui/use-command-shortcuts.ts']) {
      const src = read(f);
      expect(src, `${f} must not import the engine bridge`).not.toMatch(/engine-bridge/);
      expect(src, `${f} must not touch the Tauri transport`).not.toMatch(/@tauri-apps|engine_send/);
      // no host-message construction (a privileged channel) — only ctx callbacks
      expect(src, `${f} must not post a gate-verdict`).not.toMatch(/gate-verdict/);
    }
  });
});
