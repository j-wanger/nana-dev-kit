import { describe, it, expect } from 'vitest';
import { mkdtempSync, existsSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join } from 'node:path';
import { MemoryMount } from '../../src/memory/mcp-memory';

// The Python MCP memory server mounts and round-trips: a memory written via the
// app is read back after a session restart (Phase 108, T4). Uses an isolated
// temp DB (MEMORY_PROJECT_DIR) so the maintainer's real memory is untouched.

const VENV = join(homedir(), '.claude/memory_server/.venv/bin/python3');
const HAVE_SERVER = existsSync(VENV);
if (!HAVE_SERVER) {
  console.warn(`\n[T4] SKIPPING memory round-trip: memory server venv not found at ${VENV}.\n`);
}

describe('MCP memory mount: write -> restart -> read back', () => {
  it.runIf(HAVE_SERVER)(
    'a memory written via the mount survives a session restart',
    async () => {
      const projectDir = mkdtempSync(join(tmpdir(), 'nana-mem-'));
      const marker = `nanaharnessroundtrip${Date.now()}`;
      const content = `Phase 108 memory roundtrip sentinel ${marker} works end to end`;

      // Session 1: connect, prove availability, write.
      const mount1 = new MemoryMount({ projectDir, startupTimeoutMs: 30_000 });
      await mount1.requireAvailable();
      const stored = await mount1.store(content, { category: 'fact', tags: ['phase-108', 'roundtrip'] });
      expect(stored).toBeTruthy();
      await mount1.close();

      // Session 2 ("restart"): a fresh client/process on the SAME DB reads it back.
      const mount2 = new MemoryMount({ projectDir, startupTimeoutMs: 30_000 });
      const results = await mount2.search(marker, { limit: 5 });
      await mount2.close();

      expect(results.length).toBeGreaterThan(0);
      expect(results.some((r) => JSON.stringify(r).includes(marker))).toBe(true);
    },
    90_000,
  );
});
