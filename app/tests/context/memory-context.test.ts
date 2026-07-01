import { describe, it, expect } from 'vitest';
import { formatMemorySection, McpMemoryRetriever } from '../../src/context/memory-context';
import { PI_TOOL_ALLOWLIST } from '../../src/engine/pi/pi-adapter';

// Phase 119 T8 (A3 safe default) — memory retrieval is HOST-ORCHESTRATED: the host
// searches memory and injects the results into CONTEXT, and NO memory_* tool is
// registered for the model to call (which would need a gate carve-out, deferred).
// Retrieval is FAIL-OPEN — a memory outage runs the turn memoryless, never blocks it.

describe('formatMemorySection (Ph119 T8)', () => {
  it('formats memory_search results into a context section', () => {
    const results = [
      { memory: { content: 'Decision A: prefer X.' }, score: 0.9 },
      { memory: { content: 'Correction: Y not Z.' }, score: 0.8 },
    ];
    const s = formatMemorySection(results);
    expect(s).toContain('# Retrieved memory');
    expect(s).toContain('- Decision A: prefer X.');
    expect(s).toContain('- Correction: Y not Z.');
  });

  it('returns "" for no results (no empty-header noise)', () => {
    expect(formatMemorySection([])).toBe('');
  });

  it('skips malformed entries (missing content)', () => {
    const s = formatMemorySection([{ score: 1 }, { memory: {} }, { memory: { content: 'ok' } }]);
    expect(s).toContain('- ok');
    expect(s.match(/^- /gm)).toHaveLength(1); // exactly one bullet
  });
});

describe('McpMemoryRetriever (Ph119 T8)', () => {
  it('searches then formats', async () => {
    const r = new McpMemoryRetriever({ search: async () => [{ memory: { content: 'M1' } }] });
    expect(await r.retrieve('a query')).toContain('- M1');
  });

  it('an empty query does not search and yields ""', async () => {
    let called = 0;
    const r = new McpMemoryRetriever({
      search: async () => {
        called++;
        return [];
      },
    });
    expect(await r.retrieve('   ')).toBe('');
    expect(called).toBe(0);
  });

  it('fail-open + self-disable: a search error yields "" and disables further searches', async () => {
    let calls = 0;
    const r = new McpMemoryRetriever({
      search: async () => {
        calls++;
        if (calls === 1) throw new Error('memory server down');
        return [{ memory: { content: 'M' } }];
      },
    });
    expect(await r.retrieve('q1')).toBe(''); // the error is swallowed (fail-open)
    expect(await r.retrieve('q2')).toBe(''); // disabled — the working search is never reached
    expect(calls).toBe(1);
  });

  it('a HANGING search times out (fail-open) and self-disables — no turn stall (review nit 2)', async () => {
    let calls = 0;
    const r = new McpMemoryRetriever(
      {
        search: () => {
          calls++;
          return new Promise<unknown[]>(() => {}); // never resolves (a hung server)
        },
      },
      5,
      20, // 20ms timeout
    );
    expect(await r.retrieve('q1')).toBe(''); // timed out → fail-open
    expect(await r.retrieve('q2')).toBe(''); // disabled after the timeout
    expect(calls).toBe(1);
  });
});

describe('memory stays HOST-ORCHESTRATED — NO model-facing memory tool (Ph119 T8, A3)', () => {
  it('the Pi tool allowlist registers NO memory tool', () => {
    for (const name of PI_TOOL_ALLOWLIST) expect(name).not.toMatch(/memory/i);
    // Pinned: the model's tool set is the file/search set only — memory is host-only.
    expect([...PI_TOOL_ALLOWLIST]).toEqual(['read', 'bash', 'edit', 'write', 'grep', 'find', 'ls']);
  });
});
