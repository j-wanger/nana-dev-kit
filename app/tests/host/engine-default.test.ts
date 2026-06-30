import { describe, it, expect, afterEach } from 'vitest';
import { buildAdapter } from '../../src/host/build-adapter';

// Phase 114 (T2): the default engine is Pi — the spec's PRIMARY engine with the
// rich tool suite — not Vercel (which was the default only by a Ph109 bring-up
// accident, undefended by any test). Vercel stays the NANA_ENGINE=vercel fallback.
// buildAdapter is extracted from main.ts so importing it does NOT run the sidecar
// (no stdin/ready side effects). `delete` first so an inherited env can't pass it.

describe('default engine selection (Phase 114)', () => {
  afterEach(() => {
    delete process.env.NANA_ENGINE;
  });

  it('defaults to Pi when NANA_ENGINE is unset', () => {
    delete process.env.NANA_ENGINE;
    expect(buildAdapter('/ws').id).toBe('pi');
  });

  it('honors NANA_ENGINE=vercel (the fallback is intact)', () => {
    process.env.NANA_ENGINE = 'vercel';
    expect(buildAdapter('/ws').id).toBe('vercel');
  });

  it('treats any non-pi/non-vercel value as the Vercel fallback', () => {
    process.env.NANA_ENGINE = 'something-else';
    expect(buildAdapter('/ws').id).toBe('vercel');
  });
});
