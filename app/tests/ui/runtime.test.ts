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

  it('tracks tool calls through to done and denied', () => {
    const events: EngineEvent[] = [
      { type: 'tool-call', call: { id: 'a', name: 'read', args: {} } },
      { type: 'tool-result', id: 'a', result: {} },
      { type: 'tool-call', call: { id: 'b', name: 'bash', args: { command: 'rm -rf /' } } },
      { type: 'tool-denied', id: 'b', reason: 'destructive' },
      { type: 'done' },
    ];
    const msg = reduceEngineEvents(events);
    expect(msg.toolCalls).toEqual([
      { id: 'a', name: 'read', status: 'done' },
      { id: 'b', name: 'bash', status: 'denied', reason: 'destructive' },
    ]);
  });

  it('captures an error', () => {
    const msg = reduceEngineEvents([{ type: 'error', error: 'boom' }]);
    expect(msg.error).toBe('boom');
    expect(msg.done).toBe(false);
  });
});
