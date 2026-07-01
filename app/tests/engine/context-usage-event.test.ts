import { describe, it, expect } from 'vitest';
import type { EngineEvent } from '../../src/engine/types';
import { reduceEngineEvents, emptySurfaceMessage, applyEngineEvent } from '../../src/ui/runtime';

// Phase 119 T2 — the `context-usage` meter event is ADDITIVE + OPTIONAL: adding it
// to the EngineEvent union must NOT break any existing consumer. Two guards:
//  (1) it is a well-formed EngineEvent (incl. the percent:null post-compaction case);
//  (2) the surface reducer treats it as a benign no-op (the message is unchanged) —
//      so an adapter that starts emitting it never corrupts an existing chat.

describe('context-usage event — additive, no breaking change to the engine event union', () => {
  it('is a well-formed EngineEvent with numeric + null variants', () => {
    const withValue: EngineEvent = {
      type: 'context-usage',
      percent: 42,
      tokens: 12_345,
      contextWindow: 262_144,
      costUsd: 0,
    };
    expect(withValue.type).toBe('context-usage');

    // The post-compaction window: percent/tokens null. Still a valid event.
    const postCompaction: EngineEvent = {
      type: 'context-usage',
      percent: null,
      tokens: null,
      contextWindow: 262_144,
      costUsd: 1.23,
    };
    expect(postCompaction.percent).toBeNull();
  });

  it('the surface reducer treats a context-usage event as a no-op (message unchanged)', () => {
    const before = emptySurfaceMessage();
    before.text = 'hello';
    const after = applyEngineEvent({ ...before, toolCalls: [...before.toolCalls] }, {
      type: 'context-usage',
      percent: 50,
      tokens: 1000,
      contextWindow: 2000,
      costUsd: 0,
    });
    // No new tool call, no text change, not marked done/error — the meter feed does
    // not participate in the message store.
    expect(after.text).toBe('hello');
    expect(after.toolCalls).toEqual([]);
    expect(after.done).toBeFalsy();
    expect(after.error).toBeUndefined();
  });

  it('a stream carrying context-usage still reduces its real messages intact', () => {
    const events: EngineEvent[] = [
      { type: 'text-delta', delta: 'Hi' },
      { type: 'context-usage', percent: 10, tokens: 100, contextWindow: 1000, costUsd: 0 },
      { type: 'done' },
    ];
    const msg = reduceEngineEvents(events);
    expect(msg.text).toBe('Hi'); // context-usage did not disturb the text stream
    expect(msg.done).toBe(true);
  });
});
