import { describe, it, expect, beforeAll } from 'vitest';
import { execFileSync, execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { homedir } from 'node:os';
import { isDeniedPath } from '../../src/security/secret-deny';
import { agentReadFile } from '../../src/fs/agent-file-tool';
import { redactSecrets } from '../../src/security/redact';

const here = dirname(fileURLToPath(import.meta.url));
const keyhelperDir = resolve(here, '../../src-tauri/keyhelper');
const keyhelperBin = resolve(keyhelperDir, 'target/debug/keyhelper');
const isMac = process.platform === 'darwin';

describe('key custody: keyring-rs round-trip + agent read-deny + redaction (T2 / A3)', () => {
  beforeAll(() => {
    if (isMac && !existsSync(keyhelperBin)) {
      execSync('cargo build', { cwd: keyhelperDir, stdio: 'inherit' });
    }
  });

  // The A3 empirical check: keys actually round-trip through the macOS Keychain.
  // darwin-only — the apple-native backend is macOS-first per the spec.
  it.runIf(isMac)('keyring-rs round-trips a secret through the macOS Keychain', () => {
    const secret = `sk-test-${Date.now()}-abcdef0123456789`;
    const got = execFileSync(
      keyhelperBin,
      ['roundtrip', 'nana-harness-test', 'provider-x', secret],
      { encoding: 'utf8' },
    ).trim();
    expect(got).toBe(secret);
  });

  it('the agent file-read tool returns access-denied for the key-store path', async () => {
    const keyStorePath = resolve(homedir(), 'Library/Keychains');
    expect(isDeniedPath(keyStorePath)).toBe(true);
    const result = await agentReadFile(keyStorePath);
    expect(result).toEqual({
      ok: false,
      error: 'access-denied',
      reason: expect.any(String),
    });
  });

  it('the agent file-read tool allows a normal (non-denied) path', async () => {
    const result = await agentReadFile(fileURLToPath(import.meta.url));
    expect(result.ok).toBe(true);
  });

  it('also denies ssh and aws credential paths', () => {
    expect(isDeniedPath(resolve(homedir(), '.ssh/id_rsa'))).toBe(true);
    expect(isDeniedPath(resolve(homedir(), '.aws/credentials'))).toBe(true);
  });

  it('does not deny an unrelated path', () => {
    expect(isDeniedPath(resolve(homedir(), 'projects/app/src/main.tsx'))).toBe(false);
  });

  it('redacts key-shaped strings from log text', () => {
    const line =
      'calling provider with key sk-ant-abcdEFGH1234567890XYZ and AKIA1234567890ABCDEF done';
    const red = redactSecrets(line);
    expect(red).not.toContain('sk-ant-abcdEFGH1234567890XYZ');
    expect(red).not.toContain('AKIA1234567890ABCDEF');
    expect(red).toContain('«redacted»');
  });
});
