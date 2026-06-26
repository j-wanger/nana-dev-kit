import { describe, it, expect } from 'vitest';
import { SpendCeiling, SpendCeilingExceededError } from '../../src/control/spend';

// Driving session cost past the configured ceiling triggers a hard
// pause-for-confirmation, not merely a displayed number (Phase 108, T8).

describe('spend ceiling: enforced hard pause', () => {
  it('hard-pauses (throws) when cost exceeds the ceiling', () => {
    const ceiling = new SpendCeiling(0.1, { 'anthropic/claude': { input: 3, output: 15 } });
    ceiling.record('anthropic/claude', 100_000, 100_000); // 0.1*3 + 0.1*15 = $1.80
    expect(ceiling.spentUsd).toBeCloseTo(1.8, 5);
    expect(ceiling.exceeded()).toBe(true);
    expect(ceiling.status().paused).toBe(true);
    expect(() => ceiling.guardSpend()).toThrow(SpendCeilingExceededError);
  });

  it('allows spend below the ceiling (no pause)', () => {
    const ceiling = new SpendCeiling(10, { m: { input: 3, output: 15 } });
    ceiling.record('m', 1_000, 1_000); // ~$0.018
    expect(ceiling.exceeded()).toBe(false);
    expect(ceiling.status().paused).toBe(false);
    expect(() => ceiling.guardSpend()).not.toThrow();
  });

  it('local/free models never trip the ceiling', () => {
    const ceiling = new SpendCeiling(0.01, { 'local/qwen': { input: 0, output: 0 } });
    ceiling.record('local/qwen', 1e9, 1e9); // a billion tokens, $0
    expect(ceiling.spentUsd).toBe(0);
    expect(ceiling.exceeded()).toBe(false);
    expect(() => ceiling.guardSpend()).not.toThrow();
  });

  it('accumulates across calls and pauses once the running total crosses the line', () => {
    const ceiling = new SpendCeiling(0.05, { m: { input: 10, output: 10 } });
    ceiling.record('m', 1_000, 1_000); // $0.02
    expect(ceiling.exceeded()).toBe(false);
    ceiling.record('m', 2_000, 1_000); // +$0.03 -> $0.05 total
    expect(ceiling.exceeded()).toBe(true);
    expect(() => ceiling.guardSpend()).toThrow();
  });
});
