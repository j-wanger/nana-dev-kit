import type { MemoryMount } from '../memory/mcp-memory';

// Phase 119 T8 (A3 SAFE default) — HOST-ORCHESTRATED memory retrieval.
//
// nana's stance, documented here (the "CLI-over-MCP" stance): the memory MCP
// server stays HOST-ORCHESTRATED — the HOST calls memory_search at turn start and
// injects the results into the model's CONTEXT. It is NOT registered as a
// model-facing tool. Two reasons:
//   1. Safety. A model-facing memory_* tool would be a tool the model calls
//      directly, which would need its own gate carve-out (allow the memory calls
//      through). That carve-out is the A3 don't-know — DEFERRED this phase. Keeping
//      memory host-orchestrated needs NO carve-out: the model never calls it.
//   2. The general preference — prefer GATE-GOVERNED CLI tools (read/bash/edit/…,
//      all intercepted by the host gate) over model-facing MCP servers. An MCP
//      tool the model invokes sits OUTSIDE the CLI-tool gate path; the memory spine
//      is the one MCP we keep, and we keep it on the HOST side of the gate.
//
// Retrieval is FAIL-OPEN: a memory outage/timeout must never block a turn (distinct
// from the STARTUP health probe, which is loud — MemoryMount.requireAvailable). A
// turn runs memoryless rather than not at all.

/** The minimal host-side memory retrieval seam (injected → testable). */
export interface MemoryRetriever {
  /** Return a formatted context section for `query`, or '' when nothing/unavailable. */
  retrieve(query: string): Promise<string>;
}

const SECTION_HEADER = '# Retrieved memory (host-orchestrated — prior decisions, corrections, preferences)';

/**
 * Pure formatter: project memory_search results to a context section. Reads the
 * defensive `result.memory.content` shape the MCP server returns; skips malformed
 * entries. Empty in → '' (no section, no NaN/empty header noise).
 */
export function formatMemorySection(results: readonly unknown[]): string {
  const items = results
    .map((r) => {
      const content = (r as { memory?: { content?: unknown } })?.memory?.content;
      return typeof content === 'string' ? content.trim() : '';
    })
    .filter(Boolean);
  if (items.length === 0) return '';
  return [SECTION_HEADER, '', ...items.map((c) => `- ${c}`)].join('\n');
}

/**
 * The real retriever: search the host-side MemoryMount and format. Fail-open — any
 * search error/timeout yields '' (the turn runs memoryless). Takes only the
 * `search` surface so it is trivially faked in tests.
 */
export class McpMemoryRetriever implements MemoryRetriever {
  private disabled = false;

  constructor(
    private readonly mount: Pick<MemoryMount, 'search'>,
    private readonly limit = 5,
    /** Hard cap on a retrieval (incl. the first-turn server spawn/connect) — the
     *  turn should not stall on memory. On timeout: fail-open + self-disable. */
    private readonly timeoutMs = 5000,
  ) {}

  async retrieve(query: string): Promise<string> {
    if (this.disabled || !query.trim()) return '';
    try {
      // Bound the whole retrieval (the first turn includes the server spawn/connect)
      // so a slow/hung memory server can't stall the turn — the "fail-open on
      // timeout" the class promises, actually enforced (Ph119 review nit 2).
      const results = await Promise.race([
        this.mount.search(query, { limit: this.limit }),
        new Promise<never>((_, reject) =>
          setTimeout(() => reject(new Error('memory search timed out')), this.timeoutMs),
        ),
      ]);
      return formatMemorySection(results);
    } catch {
      // Fail-open (the turn runs memoryless), AND self-disable: a missing/broken/slow
      // memory server would otherwise re-spawn Python or re-stall on every turn. One
      // failure disables retrieval for the session; the maintainer restarts to re-enable.
      this.disabled = true;
      return '';
    }
  }
}
