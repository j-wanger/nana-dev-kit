import { describe, it, expect, beforeEach, beforeAll, afterAll } from 'vitest';
import { mkdtempSync, rmSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import {
  recordApprovedWrites,
  consumeApprovedWrites,
  __clearApprovedWrites,
} from '../../src/gate/sandbox/approved-writes';
import { bashOutOfWorkspaceWriteTargets, createHostGate } from '../../src/gate/host-gate';
import { runSandboxedBash } from '../../src/gate/sandbox/seatbelt';
import { EngineHost, type HostOutbound } from '../../src/host/engine-host';
import type { EngineAdapter, SendPromptOptions } from '../../src/engine/adapter';
import type { EngineEvent, ToolCallGate } from '../../src/engine/types';

// Phase 112 T4 — C1-preserve. An APPROVED out-of-workspace bash write threads its
// target into the per-command sandbox profile so the OS allows that one write
// (approve-then-succeed), preserving the Ph111 capability the hard sandbox would
// otherwise drop. The verdict-loop CORE is untouched.

describe('approved-writes registry (T4)', () => {
  beforeEach(__clearApprovedWrites);

  it('consume-once: read returns the targets, second read is empty', () => {
    recordApprovedWrites('cmd', ['/out/f']);
    expect(consumeApprovedWrites('cmd')).toEqual(['/out/f']);
    expect(consumeApprovedWrites('cmd')).toEqual([]);
  });
  it('records nothing for an empty target list', () => {
    recordApprovedWrites('cmd', []);
    expect(consumeApprovedWrites('cmd')).toEqual([]);
  });
});

describe('bashOutOfWorkspaceWriteTargets (T4 detection, reused from the gate)', () => {
  it('returns the resolved absolute out-of-workspace target', () => {
    expect(bashOutOfWorkspaceWriteTargets("echo x > /tmp/elsewhere/f", '/ws')).toEqual([resolve('/tmp/elsewhere/f')]);
  });
  it('returns [] for an in-workspace target', () => {
    expect(bashOutOfWorkspaceWriteTargets('echo x > /ws/note.txt', '/ws')).toEqual([]);
  });
  it('returns [] for a /dev sink', () => {
    expect(bashOutOfWorkspaceWriteTargets('echo x > /dev/null', '/ws')).toEqual([]);
  });
});

// ── the real host wiring: approval records, rejection records nothing ──
const tick = () => new Promise((r) => setTimeout(r, 0));
class FakeAdapter implements EngineAdapter {
  readonly id = 'fake';
  gate?: ToolCallGate;
  constructor(private readonly script: (ctx: { gate: ToolCallGate }) => AsyncGenerator<EngineEvent>) {}
  setToolCallGate(g: ToolCallGate): void {
    this.gate = g;
  }
  async *sendPrompt(_p: string, _o: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
    if (!this.gate) throw new Error('gate not set');
    yield* this.script({ gate: this.gate });
  }
}

function makeHost(cmd: string, sent: HostOutbound[]) {
  const adapter = new FakeAdapter(async function* ({ gate }) {
    const d = await gate({ id: 'b1', name: 'bash', args: { command: cmd } });
    yield d.action === 'allow'
      ? { type: 'tool-call', call: { id: 'b1', name: 'bash', args: {} } }
      : { type: 'tool-denied', id: 'b1', reason: d.action === 'deny' ? d.reason : 'denied' };
    yield { type: 'done' };
  });
  return new EngineHost({
    adapter,
    workspaceRoot: '/ws',
    baseGate: createHostGate({ workspaceRoot: '/ws' }),
    send: (m) => sent.push(m),
  });
}

describe('engine-host C1-preserve wiring (T4)', () => {
  beforeEach(__clearApprovedWrites);

  it('APPROVING an out-of-workspace bash write records its target for the executor', async () => {
    const cmd = 'echo owned > /tmp/ews-out/f';
    const sent: HostOutbound[] = [];
    const host = makeHost(cmd, sent);
    const turn = host.handle({ type: 'prompt', turnId: 't', text: 'x' });
    await tick();
    expect(sent.some((m) => m.type === 'gate-pending')).toBe(true);
    await host.handle({ type: 'gate-verdict', callId: 'b1', approved: true });
    await turn;
    expect(consumeApprovedWrites(cmd)).toEqual([resolve('/tmp/ews-out/f')]);
  });

  it('REJECTING records nothing (verdict-loop core unchanged)', async () => {
    const cmd = 'echo owned > /tmp/ews-out/g';
    const sent: HostOutbound[] = [];
    const host = makeHost(cmd, sent);
    const turn = host.handle({ type: 'prompt', turnId: 't', text: 'x' });
    await tick();
    await host.handle({ type: 'gate-verdict', callId: 'b1', approved: false });
    await turn;
    expect(consumeApprovedWrites(cmd)).toEqual([]);
  });
});

const onDarwin = describe.runIf(process.platform === 'darwin');
onDarwin('approve-then-succeed (functional, darwin)', () => {
  let WS = '';
  let OUT = '';
  beforeAll(() => {
    WS = mkdtempSync('/tmp/sb-t4-ws-');
    OUT = mkdtempSync('/tmp/sb-t4-out-');
  });
  afterAll(() => {
    if (WS) rmSync(WS, { recursive: true, force: true });
    if (OUT) rmSync(OUT, { recursive: true, force: true });
  });

  it('without the approved target → OS-denied; with it threaded into extraWrites → write succeeds', () => {
    const target = join(OUT, 'approved_f');
    const cmd = `echo x > '${target}'`;
    runSandboxedBash(cmd, { cwd: WS, workspaceRoot: WS, mode: 'integrity' });
    expect(existsSync(target)).toBe(false); // not approved → blocked
    runSandboxedBash(cmd, { cwd: WS, workspaceRoot: WS, mode: 'integrity', extraWrites: [target] });
    expect(existsSync(target)).toBe(true); // approved target threaded → allowed
  });
});
