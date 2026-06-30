import { homedir } from 'node:os';
import { resolve, sep } from 'node:path';

// The centralized secret read-deny list (Phase 108, T2). API keys live ONLY in
// the OS keychain (keyring-rs), never a plaintext file — but the agent's
// file/shell tools must still refuse to read the keychain DBs and the common
// on-disk credential locations, so a prompt-injected read can't exfiltrate
// anything key-shaped. One source of truth; the gate (T3) and the agent file
// tool both consult it.

/** Absolute path prefixes the agent's file/shell tools must never read. */
export function deniedPathPrefixes(home: string = homedir()): string[] {
  return [
    resolve(home, 'Library/Keychains'), // macOS Keychain databases (the key store)
    resolve(home, '.ssh'), // ssh private keys
    resolve(home, '.aws', 'credentials'), // aws static credentials
    resolve(home, '.config', 'nana-harness', 'secrets'), // app secret store (reserved)
  ];
}

/** True if `target` is, or lives under, any denied prefix. */
export function isDeniedPath(target: string, home: string = homedir()): boolean {
  const abs = resolve(target);
  return deniedPathPrefixes(home).some(
    (prefix) => abs === prefix || abs.startsWith(prefix + sep),
  );
}

/**
 * True if a RECURSIVE search/list rooted at `target` could REACH a denied secret
 * path — i.e. `target` is, lives under, OR is an ANCESTOR of any denied prefix.
 *
 * `isDeniedPath` (self-or-descendant) is correct for a single-file `read`. But the
 * recursive tools (grep/find/ls — activated in Phase 114, and NOT seatbelt-confined
 * the way bash is) ALSO reach a secret when rooted ABOVE one: `grep --hidden` at
 * `~`, or `ls ~/.aws`, enumerates `~/.ssh` / `~/.aws/credentials` even though those
 * paths are merely descendants of the search root. So those tools consult this
 * stricter, containment-symmetric check (ancestor included). Found by the Phase-114
 * adversarial pre-commit review.
 */
export function pathReachesDeniedPath(target: string, home: string = homedir()): boolean {
  const abs = resolve(target);
  if (isDeniedPath(abs, home)) return true;
  // `abs` is an ancestor of a denied prefix (a recursive walk from here hits it).
  // Normalize a trailing sep so `/Users/a` does not "contain" `/Users/ab`.
  const base = abs.endsWith(sep) ? abs : abs + sep;
  return deniedPathPrefixes(home).some((prefix) => prefix.startsWith(base));
}
