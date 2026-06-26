import { describe, it, expect } from 'vitest';
import { MemoryMount, MemoryUnavailableError } from '../../src/memory/mcp-memory';

// With the memory server unavailable, startup surfaces a loud memory-unavailable
// state and refuses to run silently memoryless (Phase 108, T4) — the exact class
// that silently dropped memory for 30+ phases of the predecessor kit.

describe('memory unavailable is surfaced loudly, never swallowed', () => {
  it('healthProbe reports unavailable (with a reason) when the server cannot start', async () => {
    const mount = new MemoryMount({
      command: '/nonexistent/python-xyz-does-not-exist',
      startupTimeoutMs: 5_000,
    });
    const health = await mount.healthProbe();
    expect(health.available).toBe(false);
    expect(health.reason).toBeTruthy();
    await mount.close();
  });

  it('requireAvailable throws MemoryUnavailableError — startup cannot proceed silently', async () => {
    const mount = new MemoryMount({
      command: '/nonexistent/python-xyz-does-not-exist',
      startupTimeoutMs: 5_000,
    });
    await expect(mount.requireAvailable()).rejects.toThrow(MemoryUnavailableError);
    await mount.close();
  });

  it('a process that does not speak MCP is detected as unavailable, not hung forever', async () => {
    // `/usr/bin/true` exits immediately and never speaks the MCP handshake.
    const mount = new MemoryMount({ command: '/usr/bin/true', args: [], startupTimeoutMs: 4_000 });
    const health = await mount.healthProbe();
    expect(health.available).toBe(false);
    await mount.close();
  });
});
