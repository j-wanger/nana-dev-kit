import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createBashTool } from '@earendil-works/pi-coding-agent';
import { makeSandboxSpawnHook, mapPiStreamEvent, piSandboxCustomTools } from '../../src/engine/pi/pi-adapter';

// Phase 112 T2 — Pi adapter integration. The sandbox wrap lives in the bash
// tool's spawnHook (inside execute()), strictly downstream of the host gate
// (pi.on('tool_call')) and the Ph110/111 visibility surface (tool_execution_start).
// These pin both the wrap correctness AND the gate-sees-original invariant.

describe('Pi adapter sandbox integration (T2)', () => {
  it('spawnHook wraps the command in sandbox-exec and does NOT mutate the input ctx', () => {
    const hook = makeSandboxSpawnHook('/tmp/ws-x', 'integrity');
    const ctx = { command: 'echo hi', cwd: '/tmp/ws-x', env: {} as NodeJS.ProcessEnv };
    const out = hook(ctx);
    expect(out.command).toContain('sandbox-exec -p');
    expect(out.command).toContain("'echo hi'"); // the original, shell-quoted
    expect(ctx.command).toBe('echo hi'); // input ctx untouched (cannot affect what the gate saw)
  });

  it('Pi passes the tool-call command to the spawnHook BYTE-IDENTICAL (C1 command-match holds)', async () => {
    // C1-preserve keys the approved-target by command: the gate records
    // call.args.command and the spawnHook later consumes ctx.command. This holds
    // only if Pi does NOT normalize the command between those points. Prove the
    // executor passes params.command through to the spawnHook unchanged (a no-op
    // operations stub avoids a real spawn).
    let seen: string | undefined;
    const tool = createBashTool('/tmp', {
      spawnHook: (ctx) => {
        seen = ctx.command;
        return ctx;
      },
      operations: { exec: async () => ({ exitCode: 0 }) },
    });
    const cmd = 'echo C1_MARKER && echo x > /out/f';
    await tool.execute('tc', { command: cmd }, undefined, undefined);
    expect(seen).toBe(cmd);
  });

  it('gate + visibility see the ORIGINAL command (mapPiStreamEvent is upstream of the wrap)', () => {
    const ev = mapPiStreamEvent({
      type: 'tool_execution_start',
      toolName: 'bash',
      toolCallId: 't1',
      args: { command: 'echo x > /outside/f' },
    } as Parameters<typeof mapPiStreamEvent>[0]);
    expect(ev).toEqual({
      type: 'tool-call',
      call: { id: 't1', name: 'bash', args: { command: 'echo x > /outside/f' } },
    });
  });

  const onDarwin = describe.runIf(process.platform === 'darwin');
  onDarwin('on darwin (sandbox active)', () => {
    let WS = '';
    let OUT = '';
    beforeAll(() => {
      WS = mkdtempSync('/tmp/sb-t2-ws-');
      OUT = mkdtempSync('/tmp/sb-t2-out-');
    });
    afterAll(() => {
      if (WS) rmSync(WS, { recursive: true, force: true });
      if (OUT) rmSync(OUT, { recursive: true, force: true });
    });

    it('piSandboxCustomTools returns a custom bash tool that overrides the builtin', () => {
      const tools = piSandboxCustomTools(WS, 'strict');
      expect(tools).toHaveLength(1);
      expect(tools[0].name).toBe('bash');
    });

    it('the wired spawnHook output confines an out-of-workspace write (python -c evasion)', () => {
      const hook = makeSandboxSpawnHook(WS, 'integrity');
      const target = join(OUT, 'wired_blocked');
      const wrapped = hook({ command: `python3 -c 'open("${target}","w").write("x")'`, cwd: WS, env: process.env });
      spawnSync('/bin/bash', ['-c', wrapped.command], { encoding: 'utf8' });
      expect(existsSync(target)).toBe(false);
    });

    it('the wired spawnHook allows an in-workspace write (control)', () => {
      const hook = makeSandboxSpawnHook(WS, 'integrity');
      const target = join(WS, 'wired_ok');
      const wrapped = hook({ command: `echo x > '${target}'`, cwd: WS, env: process.env });
      spawnSync('/bin/bash', ['-c', wrapped.command], { encoding: 'utf8' });
      expect(existsSync(target)).toBe(true);
    });
  });
});
