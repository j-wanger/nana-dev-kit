import { describe, it, expect } from 'vitest';
import { createHostGate } from '../../src/gate/host-gate';
import { applyHostGate, type PiToolCallEvent } from '../../src/engine/pi/gate-bridge';

// The in-process pre-execution gate denies a seeded destructive tool call BEFORE
// any side effect (Phase 108, T3). Pi's documented contract guarantees that a
// `tool_call` handler returning { block: true } prevents the tool from executing
// — so proving the gate returns block (and the bridge maps it correctly) proves
// "no side effect" at the dispatch site. The live end-to-end (real model emits
// `bash rm` -> file survives) is the key-gated test in e2e/provider-roundtrip.

const WS = '/tmp/nana-ws';
const gate = createHostGate({ workspaceRoot: WS });

describe('host gate: destructive-action policy', () => {
  it('denies a `bash rm`', async () => {
    expect(await gate({ id: '1', name: 'bash', args: { command: 'rm -rf /tmp/x' } })).toMatchObject({
      action: 'deny',
    });
  });

  it('denies `git push` and force operations', async () => {
    expect(await gate({ id: '2', name: 'bash', args: { command: 'git push origin main' } })).toMatchObject({ action: 'deny' });
    expect(await gate({ id: '3', name: 'bash', args: { command: 'git push --force' } })).toMatchObject({ action: 'deny' });
    expect(await gate({ id: '4', name: 'bash', args: { command: 'git reset --hard HEAD~1' } })).toMatchObject({ action: 'deny' });
  });

  it('denies a write outside the workspace root', async () => {
    expect(await gate({ id: '5', name: 'write', args: { path: '/etc/passwd', content: 'x' } })).toMatchObject({ action: 'deny' });
  });

  it('denies reads/writes of a secret/key-store path', async () => {
    const keychain = `${process.env.HOME}/Library/Keychains/login.keychain-db`;
    expect(await gate({ id: '6', name: 'read', args: { path: keychain } })).toMatchObject({ action: 'deny' });
  });

  it('schema-rejects (never coerces) malformed args', async () => {
    expect(await gate({ id: '7', name: 'bash', args: { command: 123 } })).toMatchObject({ action: 'deny' });
    expect(await gate({ id: '8', name: 'write', args: {} })).toMatchObject({ action: 'deny' });
  });

  it('allows safe in-workspace operations', async () => {
    expect(await gate({ id: '9', name: 'read', args: { path: `${WS}/src/main.ts` } })).toEqual({ action: 'allow' });
    expect(await gate({ id: '10', name: 'write', args: { path: `${WS}/src/out.ts`, content: 'x' } })).toEqual({ action: 'allow' });
    expect(await gate({ id: '11', name: 'bash', args: { command: 'ls -la' } })).toEqual({ action: 'allow' });
  });
});

describe('Pi gate-bridge: maps decisions onto Pi’s tool_call contract', () => {
  it('deny -> { block: true } and leaves event.input untouched', async () => {
    const event: PiToolCallEvent = { toolName: 'bash', toolCallId: 'a', input: { command: 'rm -rf /tmp/x' } };
    const res = await applyHostGate(event, gate);
    expect(res).toEqual({ block: true, reason: expect.any(String) });
    expect(event.input).toEqual({ command: 'rm -rf /tmp/x' }); // unchanged on deny
  });

  it('modify -> mutates event.input in place and returns undefined', async () => {
    const event: PiToolCallEvent = { toolName: 'write', toolCallId: 'b', input: { path: 'a.txt', content: 'hi' } };
    const res = await applyHostGate(event, () => ({ action: 'modify', args: { path: 'safe/a.txt' } }));
    expect(res).toBeUndefined();
    expect(event.input).toEqual({ path: 'safe/a.txt' }); // replaced in place, original keys gone
  });

  it('allow -> returns undefined and leaves event.input untouched', async () => {
    const event: PiToolCallEvent = { toolName: 'read', toolCallId: 'c', input: { path: `${WS}/x.ts` } };
    const res = await applyHostGate(event, gate);
    expect(res).toBeUndefined();
    expect(event.input).toEqual({ path: `${WS}/x.ts` });
  });
});
