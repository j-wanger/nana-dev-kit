import { describe, it, expect, afterEach } from 'vitest';
import { resolveMaxSteps } from '../../src/engine/vercel/vercel-adapter';

// Dogfound fix #1: the Vercel agent loop was hard-capped at 4 steps (it halted
// mid-task after ~3 tool rounds). The cap is now a sane default (64), overridable
// by option or NANA_MAX_STEPS, and never 0/negative (stepCountIs(0) would halt
// immediately — worse than the bug).

const ENV = 'NANA_MAX_STEPS';

describe('resolveMaxSteps (#1 step cap)', () => {
  afterEach(() => {
    delete process.env[ENV];
  });

  it('defaults to 64 (not the old hard-coded 4)', () => {
    delete process.env[ENV];
    expect(resolveMaxSteps()).toBe(64);
    expect(resolveMaxSteps()).not.toBe(4);
  });

  it('honors an explicit option over the env/default', () => {
    process.env[ENV] = '30';
    expect(resolveMaxSteps(12)).toBe(12);
  });

  it('honors NANA_MAX_STEPS when no option is given', () => {
    process.env[ENV] = '128';
    expect(resolveMaxSteps()).toBe(128);
  });

  it('falls back to 64 for invalid / non-positive values', () => {
    process.env[ENV] = 'abc';
    expect(resolveMaxSteps()).toBe(64);
    process.env[ENV] = '0';
    expect(resolveMaxSteps()).toBe(64);
    expect(resolveMaxSteps(0)).toBe(64);
    expect(resolveMaxSteps(-5)).toBe(64);
  });
});
