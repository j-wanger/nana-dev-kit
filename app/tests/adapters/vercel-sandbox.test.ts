import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { mkdtempSync, rmSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { VercelAdapter } from '../../src/engine/vercel/vercel-adapter';
import type { GatedToolResult } from '../../src/engine/vercel/gated-tools';

// The AI-SDK tool().execute is typed with ToolExecutionOptions; the underlying
// function is exactly createGatedToolExecute's simpler signature — cast to it.
type GatedExec = (args: Record<string, unknown>, opts?: { toolCallId?: string }) => Promise<GatedToolResult>;
const bashExec = (adapter: VercelAdapter): GatedExec =>
  adapter.buildGatedTools().bash.execute as unknown as GatedExec;

// Phase 112 T3 — the Vercel adapter's bash runs through the same seatbelt
// chokepoint. The decisive case is a `python -c` write that the host STRING-gate
// ALLOWS (no redirect/tee/cp syntax to detect) — exactly the Ph111 residual — and
// that the OS sandbox must block. Darwin-only (off-darwin runBash is unwrapped).

const onDarwin = describe.runIf(process.platform === 'darwin');

onDarwin('Vercel adapter sandbox integration (T3)', () => {
  let WS = '';
  let OUT = '';
  beforeAll(() => {
    WS = mkdtempSync('/tmp/sb-t3-ws-');
    OUT = mkdtempSync('/tmp/sb-t3-out-');
  });
  afterAll(() => {
    if (WS) rmSync(WS, { recursive: true, force: true });
    if (OUT) rmSync(OUT, { recursive: true, force: true });
  });

  const adapter = () => new VercelAdapter({ workspaceRoot: WS, baseUrl: 'http://localhost:1/v1', modelId: 'x' });

  it('a gate-ALLOWED python -c out-of-workspace write is OS-denied by the sandbox', async () => {
    const exec = bashExec(adapter());
    const target = join(OUT, 'vercel_evasion');
    // The host gate allows this (no detectable write syntax); the sandbox blocks it.
    const evasion = `python3 -c 'open("${target}","w").write("x")'`;
    await exec({ command: evasion }, { toolCallId: 't1' }).catch(() => {});
    expect(existsSync(target)).toBe(false);
  });

  it('an in-workspace bash write still succeeds through the sandbox (control)', async () => {
    const exec = bashExec(adapter());
    const okTarget = join(WS, 'vercel_ok');
    const res = await exec({ command: `echo x > '${okTarget}'` }, { toolCallId: 't2' });
    expect(res.denied).toBeUndefined();
    expect(existsSync(okTarget)).toBe(true);
  });
});
