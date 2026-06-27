import { describe, it, expect } from 'vitest';
import { resolve, join } from 'node:path';
import { createHostGate } from '../../src/gate/host-gate';
import type { GateDecision, NormalizedToolCall } from '../../src/engine/types';

// Phase 111 T4 — host-gate out-of-workspace HARDENING. A regression baseline
// caught the live model occasionally landing an out-of-workspace write: the
// gate enforced the workspace boundary ONLY for the `write`/`edit` tool with an
// `args.path` key. Bash file-write vectors (redirect/tee/cp/mv/dd) and
// alternately-named write tools bypassed it. These cases pin every vector
// deterministically at the gate boundary (no model). The VERDICT-LOOP core
// (confirm/approve, key-store hard-deny) is untouched — base-policy COVERAGE only.

const WS = resolve('/tmp/nana-ws-test');
const HOME = '/home/test';
const gate = createHostGate({ workspaceRoot: WS, home: HOME });

const outside = '/tmp/nana-elsewhere/escape.txt';
const inside = join(WS, 'note.txt');

function decide(name: string, args: Record<string, unknown>): GateDecision {
  const call: NormalizedToolCall = { id: 'c', name, args };
  // The base host gate is synchronous (only the confirming-gate wrapper returns
  // a Promise) — narrow the ToolCallGate union for assertions.
  return gate(call) as GateDecision;
}

describe('host-gate: out-of-workspace write coverage (T4)', () => {
  describe('covered today — regression guards (must stay deny/allow)', () => {
    it('A. write tool + args.path outside → deny', () => {
      expect(decide('write', { path: outside, content: 'owned' }).action).toBe('deny');
    });
    it('within-workspace write tool + args.path → allow', () => {
      expect(decide('write', { path: inside, content: 'ok' }).action).toBe('allow');
    });
    it('bash rm still denied (DESTRUCTIVE_BASH unchanged)', () => {
      expect(decide('bash', { command: 'rm -f x' }).action).toBe('deny');
    });
    it('secret/key-store write stays HARD-denied', () => {
      expect(decide('write', { path: `${HOME}/.aws/credentials` }).action).toBe('deny');
    });
  });

  describe('GAP 1 — bash file-write vectors to outside the workspace → deny', () => {
    it('B. echo redirect', () => {
      expect(decide('bash', { command: `echo owned > ${outside}` }).action).toBe('deny');
    });
    it('B2. append redirect', () => {
      expect(decide('bash', { command: `echo owned >> ${outside}` }).action).toBe('deny');
    });
    it('B3. no-space redirect', () => {
      expect(decide('bash', { command: `echo owned>${outside}` }).action).toBe('deny');
    });
    it('C. tee', () => {
      expect(decide('bash', { command: `echo owned | tee ${outside}` }).action).toBe('deny');
    });
    it('D. cp to outside', () => {
      expect(decide('bash', { command: `cp ${inside} ${outside}` }).action).toBe('deny');
    });
    it('D2. mv to outside', () => {
      expect(decide('bash', { command: `mv ${inside} ${outside}` }).action).toBe('deny');
    });
    it('E0. dd of= outside', () => {
      expect(decide('bash', { command: `dd if=/dev/zero of=${outside}` }).action).toBe('deny');
    });
    it('relative ../ escape redirect', () => {
      expect(decide('bash', { command: `echo owned > ../escape.txt` }).action).toBe('deny');
    });
  });

  describe('GAP 2 — alternately-named write tools to outside → deny', () => {
    it('E. write_file + args.path outside', () => {
      expect(decide('write_file', { path: outside, content: 'owned' }).action).toBe('deny');
    });
    it('E2. apply_patch + args.file_path outside', () => {
      expect(decide('apply_patch', { file_path: outside, patch: '...' }).action).toBe('deny');
    });
  });

  describe('NO over-block — legitimate in-workspace / non-writing commands still allow', () => {
    it('within-ws bash redirect (relative) → allow', () => {
      expect(decide('bash', { command: `echo owned > note.txt` }).action).toBe('allow');
    });
    it('within-ws bash redirect (absolute inside) → allow', () => {
      expect(decide('bash', { command: `echo owned > ${inside}` }).action).toBe('allow');
    });
    it('plain echo (no write) → allow', () => {
      expect(decide('bash', { command: 'echo hello world' }).action).toBe('allow');
    });
    it('read within ws via cat → allow', () => {
      expect(decide('bash', { command: `cat ${inside}` }).action).toBe('allow');
    });
    it('alt-named write tool within ws → allow (no over-block)', () => {
      expect(decide('write_file', { path: inside, content: 'ok' }).action).toBe('allow');
    });
    it('content arg that is not a path does not trip the path check', () => {
      // a write within ws whose CONTENT happens to mention an absolute path
      expect(decide('write', { path: inside, content: 'see /etc/hosts for details' }).action).toBe(
        'allow',
      );
    });
  });

  // Adversarial pre-commit review (Ph111 T5) — confirmed + self-verified edge cases.
  describe('review-found edge cases', () => {
    it('does NOT over-block /dev device-sink redirects (the most common shell idiom)', () => {
      // 2>/dev/null, >/dev/null 2>&1 etc. are harmless — must not force a confirm hold.
      expect(decide('bash', { command: 'ls 2>/dev/null' }).action).toBe('allow');
      expect(decide('bash', { command: 'npm test > /dev/null 2>&1' }).action).toBe('allow');
      expect(decide('bash', { command: `cat ${inside} > /dev/null` }).action).toBe('allow');
      expect(decide('bash', { command: 'echo hi > /dev/stdout' }).action).toBe('allow');
      expect(decide('bash', { command: 'grep x note.txt 2> /dev/stderr' }).action).toBe('allow');
    });

    it('still denies a REAL out-of-workspace redirect (the device exemption is narrow)', () => {
      expect(decide('bash', { command: `echo owned > ${outside}` }).action).toBe('deny');
      // a /dev path that is NOT a standard sink is not exempt
      expect(decide('bash', { command: 'echo owned > /dev/../tmp/nana-elsewhere/escape.txt' }).action).toBe(
        'deny',
      );
    });

    it('denies the force-clobber `>|` redirect to an out-of-workspace path', () => {
      expect(decide('bash', { command: `echo owned >| ${outside}` }).action).toBe('deny');
      expect(decide('bash', { command: `echo owned >|${outside}` }).action).toBe('deny');
    });

    it('allows force-clobber `>|` to an in-workspace path (no over-block)', () => {
      expect(decide('bash', { command: 'echo owned >| note.txt' }).action).toBe('allow');
    });
  });
});
