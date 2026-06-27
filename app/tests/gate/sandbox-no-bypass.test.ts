import { describe, it, expect, afterEach } from 'vitest';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import {
  buildProfile,
  isSandboxAvailable,
  runSandboxedBash,
  __resetSandboxAvailableCache,
} from '../../src/gate/sandbox/seatbelt';
import { piSandboxCustomTools } from '../../src/engine/pi/pi-adapter';

// Phase 112 T5 — no-bypass invariant, non-darwin fallback, and the
// model-controlled approved-target injection guard.

function walk(dir: string): string[] {
  const out: string[] = [];
  for (const e of readdirSync(dir)) {
    const p = join(dir, e);
    if (statSync(p).isDirectory()) out.push(...walk(p));
    else if (p.endsWith('.ts') || p.endsWith('.tsx')) out.push(p);
  }
  return out;
}

describe('sandbox no-bypass invariant (T5)', () => {
  // Matches any child_process form: `node:child_process`, `'child_process'`, and
  // dynamic import('child_process') — they all contain the substring.
  const importsChildProcess = (f: string) => /child_process/.test(readFileSync(f, 'utf8'));
  // Any direct shell spawn by path (covers /bin/bash AND /bin/sh).
  const spawnsAShell = (f: string) => /\/bin\/(ba)?sh/.test(readFileSync(f, 'utf8'));

  // Guards a future 3rd adapter (Claude Agent SDK): if it execs bash directly it
  // would import child_process under src/engine/ and trip this — forcing it
  // through the seatbelt chokepoint instead.
  it('no engine adapter imports child_process in ANY form (bash routes through the chokepoint)', () => {
    const offenders = walk(join(process.cwd(), 'src/engine')).filter(importsChildProcess);
    expect(offenders).toEqual([]);
  });

  it('child_process importers in src are EXACTLY the chokepoint + the keychain helper (allowlist)', () => {
    const importers = walk(join(process.cwd(), 'src'))
      .filter(importsChildProcess)
      .map((f) => f.slice(f.indexOf(`${join('src')}/`)))
      .sort();
    // seatbelt.ts = the bash chokepoint; keystore.ts spawns the macOS `security`
    // keychain CLI (NOT a shell). A new importer anywhere trips this → review it.
    expect(importers).toEqual([join('src', 'gate', 'sandbox', 'seatbelt.ts'), join('src', 'security', 'keystore.ts')].sort());
  });

  it('the seatbelt module is the ONLY src file that spawns a shell by path (/bin/bash|/bin/sh)', () => {
    const spawners = walk(join(process.cwd(), 'src')).filter(spawnsAShell);
    expect(spawners).toHaveLength(1);
    expect(spawners[0]).toContain(join('gate', 'sandbox', 'seatbelt.ts'));
  });
});

describe('non-darwin fallback (T5) — forced off-darwin on a darwin box', () => {
  const realPlatform = process.platform;
  afterEach(() => {
    // restore the REAL platform (captured before any forcing) + clear the cache
    Object.defineProperty(process, 'platform', { value: realPlatform, configurable: true });
    __resetSandboxAvailableCache();
  });

  const forcePlatform = (p: string) => {
    Object.defineProperty(process, 'platform', { value: p, configurable: true });
    __resetSandboxAvailableCache();
  };

  it('isSandboxAvailable() is false off-darwin', () => {
    forcePlatform('linux');
    expect(isSandboxAvailable()).toBe(false);
  });

  it('runSandboxedBash executes UNWRAPPED off-darwin (string-gate is the only boundary)', () => {
    forcePlatform('linux');
    const r = runSandboxedBash('echo hi', { cwd: process.cwd(), workspaceRoot: process.cwd() });
    expect(r.sandboxed).toBe(false);
    expect(r.stdout.trim()).toBe('hi');
  });

  it('piSandboxCustomTools returns [] off-darwin (builtin bash + string-gate)', () => {
    forcePlatform('win32');
    expect(piSandboxCustomTools('/ws', 'strict')).toEqual([]);
  });
});

describe('SBPL injection hardening — model-controlled approved-target (T5)', () => {
  it('buildProfile rejects an approved-target (extraWrites) with an SBPL-breakout char', () => {
    // The approved-target is the attacker-influenceable surface (P5) — it must
    // pass the same fail-closed reject-gate as the workspace path.
    expect(() =>
      buildProfile({ workspaceRoot: '/tmp', extraWrites: ['/tmp/x")) (allow file-write* (subpath "/'] }),
    ).toThrow();
  });
  it('buildProfile accepts a legit approved-target with spaces/parens (inert in SBPL)', () => {
    expect(() => buildProfile({ workspaceRoot: '/tmp', extraWrites: ['/tmp/My Out (1)'] })).not.toThrow();
  });
});
