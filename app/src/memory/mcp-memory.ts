import { homedir } from 'node:os';
import { join } from 'node:path';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

// Mount of the existing Python MCP memory server (Phase 108, T4). The server
// ports AS-IS (decision: the memory spine is not rewritten) — this is a stdio
// MCP client that spawns `python -m memory_server` and exposes store/search.
// A startup health probe surfaces unavailability/schema-mismatch LOUDLY so the
// harness never runs silently memoryless (the exact failure that silently
// dropped memory for 30+ phases of the predecessor kit).

export class MemoryUnavailableError extends Error {
  constructor(reason: string) {
    super(`memory server unavailable: ${reason}`);
    this.name = 'MemoryUnavailableError';
  }
}

export interface MemoryMountConfig {
  /** Python interpreter that has the memory server's deps. Default: ~/.claude venv. */
  command?: string;
  /** Args. Default: ['-m', 'memory_server']. */
  args?: string[];
  /** Working dir for the server. Default: ~/.claude. */
  cwd?: string;
  /** PYTHONPATH so `-m memory_server` resolves. Default: ~/.claude. */
  pythonPath?: string;
  /** MEMORY_PROJECT_DIR — point at a temp dir to isolate the DB (tests). */
  projectDir?: string;
  /** Spawn/connect timeout. Default: 15s. */
  startupTimeoutMs?: number;
}

export interface MemoryHealth {
  available: boolean;
  reason?: string;
  tools?: string[];
}

const REQUIRED_TOOLS = ['memory_store', 'memory_search'] as const;

function cleanEnv(extra: Record<string, string>): Record<string, string> {
  const base: Record<string, string> = {};
  for (const [k, v] of Object.entries(process.env)) {
    if (typeof v === 'string') base[k] = v;
  }
  return { ...base, ...extra };
}

function withTimeout<T>(p: Promise<T>, ms: number, label: string): Promise<T> {
  return Promise.race([
    p,
    new Promise<T>((_, reject) => setTimeout(() => reject(new Error(`${label} timed out after ${ms}ms`)), ms)),
  ]);
}

/**
 * Parse a FastMCP tool result. FastMCP returns a tool's value as a text block
 * (JSON) and, when the tool has an output schema, also as `structuredContent`.
 * Crucially, a NON-object return (e.g. memory_search's `list`) is wrapped as
 * `structuredContent: { result: <value> }` — so we must unwrap that single
 * `result` key, or callers see an object where they expect an array.
 */
function parseToolResult(result: unknown): unknown {
  const r = result as { structuredContent?: unknown; content?: Array<{ type: string; text?: string }> };
  const sc = r.structuredContent;
  if (sc !== undefined && sc !== null) {
    if (
      typeof sc === 'object' &&
      !Array.isArray(sc) &&
      'result' in (sc as Record<string, unknown>) &&
      Object.keys(sc as Record<string, unknown>).length === 1
    ) {
      return (sc as { result: unknown }).result; // unwrap FastMCP's list wrapper
    }
    return sc;
  }
  const text = r.content?.find((c) => c.type === 'text')?.text;
  if (text === undefined) return undefined;
  try {
    return JSON.parse(text);
  } catch {
    return text;
  }
}

export class MemoryMount {
  private client: Client | null = null;
  private transport: StdioClientTransport | null = null;
  private readonly cfg: Required<Omit<MemoryMountConfig, 'projectDir'>> & { projectDir?: string };

  constructor(config: MemoryMountConfig = {}) {
    const home = homedir();
    this.cfg = {
      command: config.command ?? process.env.NANA_MEMORY_PYTHON ?? join(home, '.claude/memory_server/.venv/bin/python3'),
      args: config.args ?? ['-m', 'memory_server'],
      cwd: config.cwd ?? join(home, '.claude'),
      pythonPath: config.pythonPath ?? join(home, '.claude'),
      startupTimeoutMs: config.startupTimeoutMs ?? 15_000,
      projectDir: config.projectDir,
    };
  }

  async connect(): Promise<void> {
    if (this.client) return;
    const env = cleanEnv({
      PYTHONPATH: this.cfg.pythonPath,
      ...(this.cfg.projectDir ? { MEMORY_PROJECT_DIR: this.cfg.projectDir } : {}),
    });
    this.transport = new StdioClientTransport({
      command: this.cfg.command,
      args: this.cfg.args,
      cwd: this.cfg.cwd,
      env,
      stderr: 'ignore',
    });
    const client = new Client({ name: 'nana-harness', version: '0.1.0' });
    await withTimeout(client.connect(this.transport), this.cfg.startupTimeoutMs, 'memory connect');
    this.client = client;
  }

  /** Detect unavailability/schema-mismatch. Never throws — returns a status to surface loudly. */
  async healthProbe(): Promise<MemoryHealth> {
    try {
      await this.connect();
      const { tools } = await withTimeout(this.client!.listTools(), this.cfg.startupTimeoutMs, 'listTools');
      const names = tools.map((t) => t.name);
      const missing = REQUIRED_TOOLS.filter((r) => !names.includes(r));
      if (missing.length > 0) {
        return { available: false, reason: `schema mismatch: missing tools ${missing.join(', ')}`, tools: names };
      }
      return { available: true, tools: names };
    } catch (e) {
      return { available: false, reason: e instanceof Error ? e.message : String(e) };
    }
  }

  /** Startup guard: refuse to run silently memoryless. Throws loudly if unavailable. */
  async requireAvailable(): Promise<void> {
    const health = await this.healthProbe();
    if (!health.available) throw new MemoryUnavailableError(health.reason ?? 'unknown');
  }

  async store(content: string, opts: Record<string, unknown> = {}): Promise<unknown> {
    await this.connect();
    const result = await this.client!.callTool({ name: 'memory_store', arguments: { content, ...opts } });
    return parseToolResult(result);
  }

  async search(query: string, opts: Record<string, unknown> = {}): Promise<unknown[]> {
    await this.connect();
    const result = await this.client!.callTool({ name: 'memory_search', arguments: { query, ...opts } });
    const parsed = parseToolResult(result);
    return Array.isArray(parsed) ? parsed : [];
  }

  async close(): Promise<void> {
    await this.client?.close();
    this.client = null;
    this.transport = null;
  }
}
