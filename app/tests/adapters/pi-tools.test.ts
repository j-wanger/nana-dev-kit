import { describe, it, expect, afterEach } from 'vitest';
import { PI_TOOL_ALLOWLIST, resolveMaxTokens } from '../../src/engine/pi/pi-adapter';

// Phase 114 (T1): the Pi adapter activates the full builtin tool set (grep/find/ls
// were dormant) and threads maxTokens past Pi's 2048 local default. These pin the
// config wiring deterministically; the live e2e (provider-roundtrip) proves the
// round-trip + the gate still blocks a real bash rm with the new allowlist active.

describe('Pi tool allowlist (Phase 114)', () => {
  it('activates the full set incl. the previously-dormant grep/find/ls', () => {
    for (const t of ['read', 'bash', 'edit', 'write', 'grep', 'find', 'ls']) {
      expect(PI_TOOL_ALLOWLIST).toContain(t);
    }
  });
});

describe('resolveMaxTokens (Phase 114)', () => {
  afterEach(() => {
    delete process.env.NANA_MAX_TOKENS;
  });

  it('defaults to 8192 (not Pi local 2048)', () => {
    delete process.env.NANA_MAX_TOKENS;
    expect(resolveMaxTokens()).toBe(8192);
    expect(resolveMaxTokens()).not.toBe(2048);
  });

  it('honors an explicit option, then the env var', () => {
    expect(resolveMaxTokens(4096)).toBe(4096);
    process.env.NANA_MAX_TOKENS = '16000';
    expect(resolveMaxTokens()).toBe(16000);
  });

  it('falls back to 8192 for invalid / non-positive values', () => {
    process.env.NANA_MAX_TOKENS = 'abc';
    expect(resolveMaxTokens()).toBe(8192);
    process.env.NANA_MAX_TOKENS = '0';
    expect(resolveMaxTokens()).toBe(8192);
    expect(resolveMaxTokens(0)).toBe(8192);
    expect(resolveMaxTokens(-5)).toBe(8192);
  });
});
