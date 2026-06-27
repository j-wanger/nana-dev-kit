import { describe, it, expect } from 'vitest';
import { reduceEngineEvents } from '../../src/ui/runtime';
import type { EngineEvent } from '../../src/engine/types';

// The engine -> surface reduction is engine-neutral (Phase 108, T6): any
// adapter's event stream folds into one message model the surface renders.

describe('engine -> surface message reduction', () => {
  it('accumulates text deltas and marks done', () => {
    const events: EngineEvent[] = [
      { type: 'text-delta', delta: 'Hello, ' },
      { type: 'text-delta', delta: 'world' },
      { type: 'done' },
    ];
    const msg = reduceEngineEvents(events);
    expect(msg.text).toBe('Hello, world');
    expect(msg.done).toBe(true);
  });

  it('threads real args + output through to the surface, tracks done and denied (Ph110 T2)', () => {
    const events: EngineEvent[] = [
      { type: 'tool-call', call: { id: 'a', name: 'read', args: { path: 'src/app.ts' } } },
      { type: 'tool-result', id: 'a', result: 'export const x = 1;\n', isError: false },
      { type: 'tool-call', call: { id: 'b', name: 'bash', args: { command: 'rm -rf /' } } },
      { type: 'tool-denied', id: 'b', reason: 'destructive' },
      { type: 'done' },
    ];
    const msg = reduceEngineEvents(events);
    expect(msg.toolCalls).toEqual([
      {
        id: 'a',
        name: 'read',
        status: 'done',
        args: { path: 'src/app.ts' },
        output: 'export const x = 1;\n',
        isError: false,
      },
      // a denied call still carries the args it was about to run with
      { id: 'b', name: 'bash', status: 'denied', reason: 'destructive', args: { command: 'rm -rf /' } },
    ]);
  });

  it('the reduced surface message stays JSON-serializable for the host line protocol (Ph110 T2)', () => {
    const msg = reduceEngineEvents([
      { type: 'tool-call', call: { id: 'a', name: 'bash', args: { command: 'ls' } } },
      { type: 'tool-result', id: 'a', result: 'a.txt\nb.txt', isError: false },
      { type: 'done' },
    ]);
    expect(() => JSON.stringify(msg)).not.toThrow();
    expect(JSON.parse(JSON.stringify(msg))).toEqual(msg);
  });

  it('shows the latest partial while a tool is still running — the long-run-looks-frozen fix (Ph110 T4)', () => {
    const msg = reduceEngineEvents([
      { type: 'tool-call', call: { id: 'a', name: 'bash', args: { command: 'serve' } } },
      { type: 'tool-progress', id: 'a', partial: 'compiling… 10%' },
      { type: 'tool-progress', id: 'a', partial: 'listening on :8080' },
    ]);
    const call = msg.toolCalls[0];
    expect(call.status).toBe('called'); // still in-flight
    expect(call.output).toBe('listening on :8080'); // latest partial, not frozen
  });

  it('the final result supersedes streamed partials when the tool finishes (Ph110 T4)', () => {
    const msg = reduceEngineEvents([
      { type: 'tool-call', call: { id: 'a', name: 'bash', args: { command: 'build' } } },
      { type: 'tool-progress', id: 'a', partial: 'compiling…' },
      { type: 'tool-result', id: 'a', result: 'build OK', isError: false },
      { type: 'done' },
    ]);
    const call = msg.toolCalls[0];
    expect(call.status).toBe('done');
    expect(call.output).toBe('build OK');
  });

  it('captures an error', () => {
    const msg = reduceEngineEvents([{ type: 'error', error: 'boom' }]);
    expect(msg.error).toBe('boom');
    expect(msg.done).toBe(false);
  });
});
