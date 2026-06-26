import { describe, it, expect } from 'vitest';
import { join } from 'node:path';
import { createHostGate } from '../../src/gate/host-gate';
import { ConfirmationBroker, type PendingConfirmation } from '../../src/gate/confirm/broker';
import { createConfirmingGate, isConfirmable } from '../../src/gate/confirm/confirming-gate';

// T6/T3 (axis 1 — preview & approve BEFORE it lands). Driven against the REAL
// host-gate so the confirmable-marker match is verified, not mocked. The
// security invariant — a secret/key-store read is a HARD deny, NEVER surfaced
// for human approval — is the load-bearing test here.

const tick = () => new Promise((r) => setTimeout(r, 0));

function setup(home = '/home/test') {
  const broker = new ConfirmationBroker();
  let pending: PendingConfirmation | undefined;
  let parkedCount = 0;
  broker.onPending((p) => {
    pending = p;
    parkedCount += 1;
  });
  const approvals: string[] = [];
  const gate = createConfirmingGate(createHostGate({ workspaceRoot: '/ws', home }), broker, {
    onApprove: (call) => approvals.push(call.id),
  });
  return { broker, gate, get pending() { return pending; }, get parkedCount() { return parkedCount; }, approvals };
}

describe('confirming gate (T6/T3)', () => {
  it('parks a destructive bash and resolves ALLOW on approve (with onApprove for revert-snapshot)', async () => {
    const s = setup();
    const decision = s.gate({ id: 'c1', name: 'bash', args: { command: 'rm -rf build' } });
    await tick();
    expect(s.pending?.callId).toBe('c1');
    expect(s.pending?.diff).toContain('rm -rf build'); // axis-1 preview
    expect(s.pending?.summary).toContain('requires explicit human confirmation');
    s.broker.resolve('c1', true);
    expect(await decision).toEqual({ action: 'allow' });
    expect(s.approvals).toEqual(['c1']); // snapshot hook fired before the side effect lands
  });

  it('parks an out-of-workspace write and resolves DENY on reject (side effect never lands)', async () => {
    const s = setup();
    const decision = s.gate({ id: 'c2', name: 'write', args: { path: '/etc/cron.d/x', content: 'evil' } });
    await tick();
    expect(s.pending?.callId).toBe('c2');
    expect(s.pending?.diff).toContain('+evil'); // proposed content previewed
    s.broker.resolve('c2', false);
    expect(await decision).toEqual({ action: 'deny', reason: 'rejected by human' });
    expect(s.approvals).toEqual([]); // never approved => never snapshotted
  });

  it('SECURITY: a secret/key-store read is a HARD deny, NEVER parked for confirmation', async () => {
    const s = setup('/home/test');
    const decision = await s.gate({ id: 'k', name: 'read', args: { path: join('/home/test', '.ssh/id_rsa') } });
    expect(decision).toEqual({ action: 'deny', reason: 'read of a secret/key-store path is denied' });
    expect(s.parkedCount).toBe(0); // never surfaced for human approval
    expect(s.broker.hasPending()).toBe(false);
  });

  it('SECURITY: a malformed (schema-reject) call is a hard deny, not confirmable', async () => {
    const s = setup();
    const decision = await s.gate({ id: 'm', name: 'bash', args: {} });
    expect(decision.action).toBe('deny');
    expect(s.parkedCount).toBe(0);
  });

  it('passes a safe in-workspace call straight through to allow (no parking)', async () => {
    const s = setup();
    const decision = await s.gate({ id: 'ok', name: 'read', args: { path: '/ws/src/index.ts' } });
    expect(decision).toEqual({ action: 'allow' });
    expect(s.parkedCount).toBe(0);
  });

  it('rejectAll resolves every outstanding hold as denied (turn cancel never leaks a hung await)', async () => {
    const s = setup();
    const decision = s.gate({ id: 'c3', name: 'bash', args: { command: 'git push --force' } });
    await tick();
    expect(s.broker.hasPending()).toBe(true);
    s.broker.rejectAll();
    expect(await decision).toEqual({ action: 'deny', reason: 'rejected by human' });
    expect(s.broker.hasPending()).toBe(false);
  });

  it('isConfirmable matches only the explicit-confirmation marker', () => {
    expect(isConfirmable('destructive shell command requires explicit human confirmation')).toBe(true);
    expect(isConfirmable('read of a secret/key-store path is denied')).toBe(false);
    expect(isConfirmable('malformed bash call: missing string `command`')).toBe(false);
  });
});
