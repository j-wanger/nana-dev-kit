import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { existsSync } from 'node:fs';

// Node-side accessor for OS-keychain secrets (Phase 108). Shells out to the
// keyring-rs `keyhelper` binary — the same crate the Tauri shell uses via its
// store_secret/get_secret commands. Keeping one accessor means the engine layer
// reads provider keys from the keychain (never a plaintext file, never the
// chat). In-app this routes through the Tauri command; in Node/tests it's the
// helper binary.

const here = dirname(fileURLToPath(import.meta.url));
const KEYHELPER = resolve(here, '../../src-tauri/keyhelper/target/debug/keyhelper');

export function keyhelperAvailable(): boolean {
  return existsSync(KEYHELPER);
}

/** Read a secret from the OS keychain. Returns undefined if absent/unavailable. */
export function getSecret(service: string, account: string): string | undefined {
  if (!keyhelperAvailable()) return undefined;
  try {
    const out = execFileSync(KEYHELPER, ['get', service, account], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    const trimmed = out.trim();
    return trimmed.length > 0 ? trimmed : undefined;
  } catch {
    return undefined; // not found / keychain error
  }
}

/** Store a secret in the OS keychain. */
export function storeSecret(service: string, account: string, secret: string): void {
  execFileSync(KEYHELPER, ['store', service, account, secret], {
    stdio: ['ignore', 'ignore', 'pipe'],
  });
}
