import { spawnSync } from 'node:child_process';
import { existsSync, realpathSync, statSync } from 'node:fs';
import { homedir, tmpdir } from 'node:os';
import { basename, dirname, join, resolve } from 'node:path';

// OS-level filesystem sandbox for bash tool execution (Phase 112). The Ph111
// host-gate STRING-gates bash write targets, but string-gating arbitrary shell
// is incomplete BY NATURE — `python -c`, `node -e`, base64-decoded paths and env
// indirection all evade the regex (the documented Ph111 HONEST RESIDUAL). This
// module is the COMPLETE fix for IN-PROCESS write obfuscation: it wraps bash
// execution in a macOS seatbelt (`sandbox-exec`) profile that confines file
// WRITES to the workspace at the KERNEL/syscall layer. Confinement is INHERITED
// by every child process, so an in-process evasion (python -c / node -e / base64
// / env indirection) dies regardless of how it obfuscates the write target.
// (Daemon/XPC-mediated writes are NOT in-process — see the residual below.)
//
// It sits BELOW the host-gate verdict loop, not inside it: the gate still runs
// first (string policy + the confirmable-write prompt + key-store hard-deny),
// and this layer is the deterministic backstop for what string-gating cannot
// see. macOS-only; on other platforms callers fall back to the string-gate alone.
//
// Empirically validated (Ph112 T1 spike, 18 committed evasion vectors): seatbelt enforces
// at the syscall layer and inherits to python/node/sub-shell children; the
// confused-deputy symlink escape is blocked (seatbelt resolves the canonical
// target). KNOWN RESIDUALS (do not over-claim): daemon/XPC-mediated writes
// (`defaults write` via cfprefsd, `launchctl`, cron) are performed by an
// unconfined daemon and bypass file-write* rules; full filesystem READ stays
// open (this is a write-INTEGRITY boundary, not confidentiality); the per-user
// $TMPDIR is write-allowed for tool compatibility; `sandbox-exec` is
// Apple-deprecated-but-functional (durability caveat; Chromium-seatbelt precedent).

export type SandboxMode = 'strict' | 'integrity';

// Absolute path (NOT the bare name) so a model-planted `sandbox-exec` earlier on
// PATH cannot shadow the real binary and run the command un-sandboxed (Ph112
// review). This is the exact path isSandboxAvailable() checks for.
const SANDBOX_EXEC = '/usr/bin/sandbox-exec';

/** Resolve the sandbox mode: explicit option, else NANA_SANDBOX_MODE env, else
 *  'strict' (the maintainer's Ph112 choice). 'integrity' keeps write-confinement
 *  but drops the network/mach denials — the A2/A5 tension knob, flippable without
 *  a code change (strict denies external network, breaking npm/pip by design). */
export function resolveSandboxMode(opt?: SandboxMode): SandboxMode {
  if (opt) return opt;
  return process.env.NANA_SANDBOX_MODE === 'integrity' ? 'integrity' : 'strict';
}

// SBPL string literals are INJECTABLE: a path containing a double quote or a
// newline can CLOSE the `(subpath "...")` literal and append a second rule — the
// T1 spike proved a crafted path `/x")) (allow file-write* (subpath "/` produced
// a valid profile granting write to `/` and a file landed outside the workspace.
// Fail CLOSED: reject any path carrying an SBPL-breakout character before it
// reaches the profile. `(`, `)` and spaces are INERT inside a quoted literal and
// are legitimate in real macOS paths, so they are deliberately NOT rejected
// (rejecting them would break real workspaces).
const SBPL_UNSAFE = /["\\\n\r\0]/;

/** Throw (fail-closed) if a path is not a profile-safe absolute path. */
export function assertSafeProfilePath(path: string): void {
  if (!path.startsWith('/')) {
    throw new Error(`sandbox: refusing non-absolute path in profile: ${JSON.stringify(path)}`);
  }
  // The filesystem root is never a legitimate workspace root OR approved target:
  // `(subpath "/")` would re-allow writes everywhere and silently DISABLE the
  // sandbox (Ph112 adversarial review). Reject it fail-closed — a `/` extraWrites
  // (e.g. an approved `echo x > /`) fails the command rather than opening the FS.
  if (path === '/') {
    throw new Error('sandbox: refusing filesystem-root path in profile (would grant whole-FS write)');
  }
  if (SBPL_UNSAFE.test(path)) {
    throw new Error(`sandbox: refusing SBPL-unsafe path in profile: ${JSON.stringify(path)}`);
  }
}

// seatbelt evaluates file operations on the RESOLVED canonical path. On macOS the
// workspace commonly lives under a symlinked prefix (/var -> /private/var, /tmp ->
// /private/tmp), so an un-canonicalized `(subpath ...)` rule matches NOTHING and
// silently denies every intended in-workspace write — the most dangerous failure
// mode (looks like it works, confines nothing the way you think). Canonicalize
// before emitting the rule. The leaf may not exist yet (a write about to create
// it), so resolve the nearest existing ancestor and re-append the remainder.
export function canonicalizePath(p: string): string {
  const abs = resolve(p);
  if (existsSync(abs)) return realpathSync.native(abs);
  const parent = dirname(abs);
  if (parent === abs) return abs; // reached the filesystem root
  // Re-append the leaf via basename, NOT a slice: when parent is the filesystem
  // root, `abs.slice(parent.length + 1)` over-slices (the root '/' IS the
  // separator) and drops a leaf char — '/w' → '/', i.e. (subpath "/") = whole-FS
  // (Ph112 review). basename is correct for every depth.
  return resolve(canonicalizePath(parent), basename(abs));
}

let _available: boolean | undefined;

/** True iff we are on darwin AND `sandbox-exec` is present (cached). */
export function isSandboxAvailable(): boolean {
  if (_available !== undefined) return _available;
  let present = false;
  if (process.platform === 'darwin') {
    try {
      present = statSync('/usr/bin/sandbox-exec').isFile();
    } catch {
      present = false;
    }
  }
  _available = present;
  return _available;
}

/** Test seam: clear the isSandboxAvailable() cache. */
export function __resetSandboxAvailableCache(): void {
  _available = undefined;
}

export interface ProfileOptions {
  /** The workspace root — the only directory tree writable by default. */
  workspaceRoot: string;
  /** The per-user temp dir (defaults to os.tmpdir()); write-allowed for tool compat. */
  tmpDir?: string;
  /** Approved out-of-workspace write targets (Phase 112 T4 C1-preserve channel). */
  extraWrites?: string[];
  /** 'strict' (default) also denies external network + mach-lookup; 'integrity' is write-only. */
  mode?: SandboxMode;
}

// Standard device sinks tools expect to be writable even under a deny-write
// profile. /dev/null is NOT auto-exempt under seatbelt (Ph111 DEV_SINK lesson,
// re-confirmed at the SBPL layer in the T1 spike — omitting it silently breaks
// `>/dev/null` redirects across nearly every tool).
const DEV_SINK_LITERALS = ['/dev/null', '/dev/zero', '/dev/stdout', '/dev/stderr', '/dev/tty', '/dev/dtracehelper'];

const sbplString = (s: string): string => `"${s}"`;

// The default deny-file-write* profile confines ALL writes to the workspace — so
// HOME-based tool caches (~/.npm, ~/.cache, ~/.cargo) are denied too, breaking
// npm/pip/cargo. INTEGRITY mode re-allows this MINIMAL common set (A2 "minimal
// caches") so everyday dev works. STRICT mode OMITS them: it already denies
// external network so npm/pip can't fetch anyway, and keeping caches un-writable
// avoids a cache-poisoning write surface. Not exhaustive by design — a tool with
// a different cache dir fails closed (tune per real dogfood breakage, never a
// silent pre-baked guess-list for everything).
const INTEGRITY_CACHE_DIRS = ['.npm', '.cache', '.cargo'];

/**
 * Build a macOS seatbelt (SBPL) profile that confines file writes to the
 * workspace (+ temp, dev sinks, and any approved targets). In 'strict' mode it
 * also denies external network and mach-lookup, re-allowing only the minimum a
 * functional dev shell needs (empirically determined in the T1 spike).
 */
export function buildProfile(opts: ProfileOptions): string {
  const mode = opts.mode ?? 'strict';
  const tmp = opts.tmpDir ?? tmpdir();

  // Canonicalize FIRST, then fail-closed reject-gate the canonical result.
  const caches = mode === 'integrity' ? INTEGRITY_CACHE_DIRS.map((c) => join(homedir(), c)) : [];
  const writeRoots = [opts.workspaceRoot, tmp, ...caches, ...(opts.extraWrites ?? [])].map((p) => {
    const canon = canonicalizePath(p);
    assertSafeProfilePath(canon);
    return canon;
  });

  const writeAllows = [
    ...writeRoots.map((p) => `(subpath ${sbplString(p)})`),
    ...DEV_SINK_LITERALS.map((d) => `(literal ${sbplString(d)})`),
    '(subpath "/dev/fd")',
  ];

  const lines: string[] = [
    '(version 1)',
    '(allow default)',
    '(deny file-write*)',
    `(allow file-write* ${writeAllows.join(' ')})`,
  ];

  if (mode === 'strict') {
    // Deny all network; re-allow ONLY loopback IP (local dev servers). We do NOT
    // allow (remote unix-socket): it would reach arbitrary LOCAL DAEMON sockets
    // (e.g. the Docker socket → an unconfined host write that bypasses file-write*)
    // AND the DNS resolver (hostname leak) — both undercut strict's exfil/
    // persistence intent (Ph112 review closed this rather than documenting it).
    // Cost: no DNS resolution + no local unix-socket IPC under strict; strict
    // already denies external network (npm/pip fetches fail by design — the A2/A5
    // tension the maintainer accepted), so this is consistent. Use integrity mode
    // (NANA_SANDBOX_MODE=integrity) when full network is needed. RESIDUAL: the
    // mach/XPC daemon path (defaults write/launchctl) remains — denying it breaks
    // the shell — so strict reduces, not eliminates, daemon-mediated side effects.
    lines.push('(deny network*)');
    lines.push('(allow network* (remote ip "localhost:*"))');
    // mach-lookup denied, re-allowing only the two services a functional dev
    // shell needs (T1 spike): the username/group DB and the per-user temp dir.
    // Denied lookups degrade gracefully (logd/configd/notifications are no-ops).
    lines.push('(deny mach-lookup)');
    lines.push(
      '(allow mach-lookup (global-name "com.apple.system.opendirectoryd.libinfo") (global-name "com.apple.bsd.dirhelper"))',
    );
  }

  return lines.join('\n') + '\n';
}

/**
 * The argv to run `command` under `profile`. argv form (no shell) means the
 * profile and command are separate elements — no re-quoting of the command.
 * Used by the synchronous chokepoint (runSandboxedBash) and the Vercel adapter.
 */
export function wrapBashArgv(command: string, profile: string): string[] {
  return [SANDBOX_EXEC, '-p', profile, '/bin/bash', '-c', command];
}

/**
 * POSIX single-quote shell-quoting: wraps `s` so a `shell -c` re-parse yields
 * `s` EXACTLY, for ANY content (correctly handles embedded single quotes). The
 * canonical, injection-proof quote.
 */
export function shellQuote(s: string): string {
  return `'${s.replace(/'/g, `'\\''`)}'`;
}

/**
 * The command STRING for Pi's bash `spawnHook` (Phase 112 T2): Pi's local
 * executor re-parses the returned command via `shell -c <string>`, so the inline
 * `-p` profile AND the original command are both shell-quoted — no re-quoting
 * hole even with arbitrary quotes/newlines in either. Inline `-p` (not a temp
 * file) keeps the profile per-command, which the T4 approved-targets channel
 * needs. `command` and `profile` survive exactly one shell re-parse intact.
 */
export function wrapBashCommandString(command: string, profile: string): string {
  return `${SANDBOX_EXEC} -p ${shellQuote(profile)} /bin/bash -c ${shellQuote(command)}`;
}

export interface RunResult {
  stdout: string;
  stderr: string;
  status: number | null;
  /** false iff executed unwrapped (non-darwin / no sandbox-exec). */
  sandboxed: boolean;
}

export interface RunOptions {
  cwd: string;
  workspaceRoot: string;
  mode?: SandboxMode;
  extraWrites?: string[];
  tmpDir?: string;
  env?: NodeJS.ProcessEnv;
  /** Max bytes/ms (passed through to spawnSync). */
  maxBuffer?: number;
  timeout?: number;
}

/**
 * THE single guarded chokepoint every adapter funnels bash execution through.
 * On darwin-with-sandbox it wraps the command in a workspace-confined seatbelt
 * profile; otherwise it executes unwrapped (the host-gate string layer is the
 * only boundary off-darwin — documented residual). No bash spawn site in the
 * app should call child_process directly; routing through here is the no-bypass
 * invariant that also covers a future Claude-SDK adapter.
 */
export function runSandboxedBash(command: string, opts: RunOptions): RunResult {
  const common = {
    cwd: opts.cwd,
    env: opts.env,
    encoding: 'utf8' as const,
    maxBuffer: opts.maxBuffer,
    timeout: opts.timeout,
  };

  if (!isSandboxAvailable()) {
    const r = spawnSync('/bin/bash', ['-c', command], common);
    return { stdout: r.stdout ?? '', stderr: r.stderr ?? '', status: r.status, sandboxed: false };
  }

  const profile = buildProfile({
    workspaceRoot: opts.workspaceRoot,
    tmpDir: opts.tmpDir,
    extraWrites: opts.extraWrites,
    mode: opts.mode,
  });
  const argv = wrapBashArgv(command, profile);
  const r = spawnSync(argv[0], argv.slice(1), common);
  return { stdout: r.stdout ?? '', stderr: r.stderr ?? '', status: r.status, sandboxed: true };
}
