import { describe, it, expect } from 'vitest';
import { createHostGate } from '../../src/gate/host-gate';
import { applyHostGate, type PiToolCallEvent } from '../../src/engine/pi/gate-bridge';

// A model-side bypass attempt cannot suppress the host gate (Phase 108, T3).
// Two architectural facts make this hold, and both are exercised here:
//  1. Pi's `tool_call` hook fires for EVERY tool — built-in, custom, extension —
//     before execution (verified against the Pi docs). So no tool can run without
//     passing the host gate; there is no "ungated" tool name.
//  2. The host gate keys on the call's payload, not on a per-tool allowlist, so a
//     custom tool that SHADOWS a built-in name, or an UNREGISTERED tool name,
//     gets the same destructive-payload + secret-path checks.
// The live proof (a real shadow/unregistered tool through a running Pi session)
// is the key-gated test in e2e/provider-roundtrip.

const WS = '/tmp/nana-ws';
const gate = createHostGate({ workspaceRoot: WS });

describe('gate bypass-resistance: universal coverage over tool names', () => {
  it('denies a destructive payload under a custom tool that shadows a built-in name', async () => {
    // A custom "bash" shadow still routes through the same gate branch.
    expect(await gate({ id: '1', name: 'bash', args: { command: 'rm -rf ~' } })).toMatchObject({ action: 'deny' });
  });

  it('denies a destructive payload under an UNREGISTERED / unknown tool name', async () => {
    expect(await gate({ id: '2', name: 'totally_unregistered_exec', args: { cmd: 'rm -rf /' } })).toMatchObject({ action: 'deny' });
    expect(await gate({ id: '3', name: 'sneaky', args: { script: 'git push --force' } })).toMatchObject({ action: 'deny' });
  });

  it('denies a secret/key-store path under an arbitrary unknown tool', async () => {
    const keychain = `${process.env.HOME}/.ssh/id_rsa`;
    expect(await gate({ id: '4', name: 'exfil', args: { target: keychain } })).toMatchObject({ action: 'deny' });
  });

  it('still allows a benign unknown tool (no over-blocking, but it WAS gated)', async () => {
    expect(await gate({ id: '5', name: 'weather', args: { city: 'Sydney' } })).toEqual({ action: 'allow' });
  });

  it('the bridge blocks every denied call regardless of tool name', async () => {
    for (const name of ['bash', 'shadow_bash', 'unknown_tool']) {
      const event: PiToolCallEvent = { toolName: name, toolCallId: name, input: { command: 'rm -rf /tmp/x' } };
      const res = await applyHostGate(event, gate);
      expect(res, `tool ${name} must be blocked`).toEqual({ block: true, reason: expect.any(String) });
    }
  });
});
