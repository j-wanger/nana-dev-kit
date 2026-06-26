import { describe, it, expect } from 'vitest';
import { runInterruptible } from '../../src/control/interrupt';

// A hard interrupt from the GUI cancels an in-flight/hung tool call within ≤2s
// of the user action (Phase 108, T8).

describe('hard interrupt: cancel a hung tool call within 2s', () => {
  it('cancels a never-resolving tool call promptly after interrupt', async () => {
    const controller = new AbortController();
    // A hung tool: it never resolves on its own.
    const hung = () => new Promise<string>(() => {});

    const start = Date.now();
    setTimeout(() => controller.abort(), 100); // "user hits stop" 100ms in
    const result = await runInterruptible(hung, controller.signal);
    const elapsed = Date.now() - start;

    expect(result).toEqual({ completed: false, interrupted: true });
    expect(elapsed).toBeLessThan(2000);
  });

  it('already-aborted signal cancels immediately', async () => {
    const controller = new AbortController();
    controller.abort();
    const result = await runInterruptible(() => new Promise<string>(() => {}), controller.signal);
    expect(result).toEqual({ completed: false, interrupted: true });
  });

  it('returns the value when the tool finishes before any interrupt', async () => {
    const controller = new AbortController();
    const result = await runInterruptible(async () => 'done', controller.signal);
    expect(result).toEqual({ completed: true, value: 'done' });
  });
});
