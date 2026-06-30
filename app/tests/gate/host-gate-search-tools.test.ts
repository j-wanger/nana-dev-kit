import { describe, it, expect } from 'vitest';
import { createHostGate } from '../../src/gate/host-gate';
import type { GateDecision, NormalizedToolCall } from '../../src/engine/types';

// Phase 114 (T1): Pi's read-only search/list tools (grep/find/ls) are activated
// alongside the Pi-default switch. The gate must handle them like `read` — deny
// secret paths, allow otherwise — and crucially NOT fall through to the `default`
// branch, which runs every string arg through the destructive-bash check (that
// would falsely deny a grep PATTERN of "rm"/"git push"/"--force"). These are the
// deterministic proofs (no live model) that the gate covers the now-active tools.

const WS = '/ws';
const HOME = '/Users/test';
const rawGate = createHostGate({ workspaceRoot: WS, home: HOME });
// createHostGate is synchronous; narrow the ToolCallGate's GateDecision|Promise type.
const gate = (call: NormalizedToolCall): GateDecision => rawGate(call) as GateDecision;

describe('host gate — search/list tools (Phase 114)', () => {
  it('allows an in-workspace grep whose PATTERN contains a destructive word (a search is not destructive)', () => {
    expect(gate({ id: '1', name: 'grep', args: { pattern: 'rm -rf', path: WS } })).toEqual({ action: 'allow' });
    expect(gate({ id: '2', name: 'grep', args: { pattern: 'git push --force', path: WS } })).toEqual({
      action: 'allow',
    });
    expect(gate({ id: '3', name: 'grep', args: { pattern: 'dd if=/dev/zero', path: WS } })).toEqual({
      action: 'allow',
    });
  });

  it('denies grep/find/ls of a secret / key-store path', () => {
    expect(gate({ id: '4', name: 'grep', args: { pattern: 'x', path: `${HOME}/.ssh/id_rsa` } }).action).toBe('deny');
    expect(gate({ id: '5', name: 'find', args: { path: `${HOME}/.ssh` } }).action).toBe('deny');
    expect(gate({ id: '6', name: 'ls', args: { path: `${HOME}/Library/Keychains` } }).action).toBe('deny');
  });

  it('denies a recursive search/list rooted AT or ABOVE a secret dir (ancestor-aware — Ph114 review)', () => {
    // grep --hidden at HOME descends into ~/.ssh; the search ROOT (HOME) is merely
    // an ancestor of the secret, which the old self-or-descendant check missed.
    expect(gate({ id: 'a1', name: 'grep', args: { pattern: 'PRIVATE KEY', path: HOME } }).action).toBe('deny');
    // the sharpest case: the deny prefix is the FILE ~/.aws/credentials, so the
    // ~/.aws DIRECTORY must still be denied as a search/list root.
    expect(gate({ id: 'a2', name: 'ls', args: { path: `${HOME}/.aws` } }).action).toBe('deny');
    expect(gate({ id: 'a3', name: 'find', args: { pattern: 'id_rsa', path: HOME } }).action).toBe('deny');
    // filesystem root reaches every secret.
    expect(gate({ id: 'a4', name: 'grep', args: { pattern: '.', path: '/' } }).action).toBe('deny');
    // a sibling of the secret dir (not an ancestor) stays allowed — no over-block.
    expect(gate({ id: 'a5', name: 'ls', args: { path: `${HOME}/Documents` } })).toEqual({ action: 'allow' });
  });

  it('allows a normal in-workspace find/ls/glob', () => {
    expect(gate({ id: '7', name: 'find', args: { pattern: '*.ts', path: WS } })).toEqual({ action: 'allow' });
    expect(gate({ id: '8', name: 'ls', args: { path: WS } })).toEqual({ action: 'allow' });
    expect(gate({ id: '9', name: 'glob', args: { pattern: '**/*.rs', path: WS } })).toEqual({ action: 'allow' });
  });

  it('REGRESSION: write/edit secret + out-of-workspace and destructive bash still denied', () => {
    expect(gate({ id: '10', name: 'write', args: { path: `${HOME}/.ssh/authorized_keys`, content: 'x' } }).action).toBe('deny');
    expect(gate({ id: '11', name: 'edit', args: { path: '/etc/hosts' } }).action).toBe('deny'); // out-of-ws
    expect(gate({ id: '12', name: 'bash', args: { command: 'rm -rf /' } }).action).toBe('deny');
    // and the still-cased read tool keeps its secret-deny
    expect(gate({ id: '13', name: 'read', args: { path: `${HOME}/.aws/credentials` } }).action).toBe('deny');
  });
});
