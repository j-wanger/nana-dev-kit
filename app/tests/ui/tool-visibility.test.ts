import { describe, it, expect } from 'vitest';
import { surfaceToThreadMessage } from '../../src/ui/chat-binding';
import type { SurfaceToolCall } from '../../src/ui/runtime';

// Ph110 T3 (security-bearing). The binding projects the REAL args + output that
// T1/T2 thread onto the assistant-ui tool part — argsText shows WHAT ran, result
// shows the output — and routes BOTH through redactSecrets() so a key-shaped
// string in untrusted tool output never reaches the renderer (the GUI exfil
// surface the terminal never had). Gate-denials keep their distinct
// "blocked by gate" affordance (isError + reason).

type Part = { type: string; toolName?: string; argsText?: string; result?: unknown; isError?: boolean };

function tools(toolCalls: SurfaceToolCall[]): Part[] {
  const tm = surfaceToThreadMessage({ role: 'assistant', text: '', toolCalls, done: true });
  return (tm.content as unknown as Part[]).filter((p) => p.type === 'tool-call');
}

describe('tool-call visibility binding (Ph110 T3)', () => {
  it('shows the real bash command as argsText (not the empty stub)', () => {
    const [p] = tools([
      { id: 'a', name: 'bash', status: 'done', args: { command: 'ls -la /tmp' }, output: 'a.txt' },
    ]);
    expect(p.argsText).toBe('ls -la /tmp');
  });

  it('shows non-bash args as compact JSON', () => {
    const [p] = tools([
      { id: 'a', name: 'read', status: 'done', args: { path: 'src/app.ts' }, output: 'x' },
    ]);
    expect(p.argsText).toContain('src/app.ts');
  });

  it('shows the real tool output as the result (not the literal "done")', () => {
    const [p] = tools([
      { id: 'a', name: 'bash', status: 'done', args: { command: 'echo hi' }, output: 'hi\n' },
    ]);
    expect(p.result).toBe('hi\n');
  });

  it('redacts a key-shaped string in BOTH args and output before it reaches the renderer', () => {
    const key = `sk-ant-${'A'.repeat(40)}`;
    const [p] = tools([
      {
        id: 'a',
        name: 'bash',
        status: 'done',
        args: { command: `export TOKEN=${key}` },
        output: `using ${key} now`,
      },
    ]);
    expect(p.argsText).not.toContain(key);
    expect(String(p.result)).not.toContain(key);
    expect(p.argsText).toContain('«redacted»');
    expect(String(p.result)).toContain('«redacted»');
  });

  it('a gate-denied call keeps the distinct blocked-by-gate affordance (isError + reason), still showing WHAT was blocked', () => {
    const [p] = tools([
      { id: 'b', name: 'bash', status: 'denied', reason: 'destructive', args: { command: 'rm -rf /' } },
    ]);
    expect(p.isError).toBe(true);
    expect(p.result).toBe('destructive');
    expect(p.argsText).toBe('rm -rf /');
  });

  it('an in-flight (called) tool shows args but no result yet', () => {
    const [p] = tools([{ id: 'a', name: 'bash', status: 'called', args: { command: 'sleep 5' } }]);
    expect(p.argsText).toBe('sleep 5');
    expect(p.result).toBeUndefined();
  });

  it('truncates very long argsText/result to keep the inline view compact', () => {
    const huge = 'lorem ipsum dolor sit amet '.repeat(1000); // ~27k chars, no 40-char token run
    const [p] = tools([
      { id: 'a', name: 'bash', status: 'done', args: { command: huge }, output: huge },
    ]);
    expect((p.argsText as string).length).toBeLessThan(huge.length);
    expect(String(p.result).length).toBeLessThan(huge.length);
  });
});
