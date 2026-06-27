import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, existsSync, symlinkSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir, userInfo } from 'node:os';
import { join } from 'node:path';
import {
  assertSafeProfilePath,
  buildProfile,
  canonicalizePath,
  isSandboxAvailable,
  runSandboxedBash,
  shellQuote,
  wrapBashArgv,
  wrapBashCommandString,
} from '../../src/gate/sandbox/seatbelt';

// Phase 112 T1 — the FRONT-LOADED de-risking spike. This EXECUTES real commands
// under seatbelt and asserts on FILESYSTEM SIDE EFFECTS (a denied write may still
// exit 0 — the T1 probe saw perl/os.system do exactly that — so existence, not
// exit code, is the verdict). Every confinement assertion is paired with a
// positive control (an in-WS write that MUST land) so a mis-built deny-everything
// profile cannot masquerade as "all blocked = secure" (controls-first; the kit's
// instrument-dead guard). Darwin-only (seatbelt is macOS); skips loudly elsewhere.

const onDarwin = process.platform === 'darwin';
if (!onDarwin) {
  // eslint-disable-next-line no-console
  console.warn('[seatbelt-spike] SKIPPED: not darwin — the OS sandbox layer is macOS-only (string-gate is the off-darwin boundary).');
}
const d = describe.runIf(onDarwin);

// WS and OUT both live under /tmp (=/private/tmp), NOT under $TMPDIR
// (/private/var/folders). So a WS write is reachable ONLY via the canonicalized
// workspaceRoot rule (this isolates the canonicalization fix), and an OUT write
// is outside every allowlisted root (workspace, $TMPDIR, dev sinks).
let WS = '';
let OUT = '';

beforeAll(() => {
  if (!onDarwin) return;
  WS = mkdtempSync('/tmp/sb-ws-');
  OUT = mkdtempSync('/tmp/sb-out-');
});
afterAll(() => {
  if (WS) rmSync(WS, { recursive: true, force: true });
  if (OUT) rmSync(OUT, { recursive: true, force: true });
});

/** Run integrity-mode under the WS profile. */
const runIntegrity = (command: string) =>
  runSandboxedBash(command, { cwd: WS, workspaceRoot: WS, mode: 'integrity' });
const runStrict = (command: string) =>
  runSandboxedBash(command, { cwd: WS, workspaceRoot: WS, mode: 'strict' });

d('seatbelt spike — environment', () => {
  it('isSandboxAvailable() is true on darwin (sandbox-exec present)', () => {
    expect(isSandboxAvailable()).toBe(true);
  });
  it('wrapBashArgv puts profile + command in separate argv elements (no re-quoting)', () => {
    const argv = wrapBashArgv('echo "a)b" > x', '(version 1)(allow default)');
    expect(argv).toEqual(['/usr/bin/sandbox-exec', '-p', '(version 1)(allow default)', '/bin/bash', '-c', 'echo "a)b" > x']);
  });
  it('shellQuote round-trips arbitrary content through a shell -c re-parse', () => {
    expect(shellQuote("a'b")).toBe("'a'\\''b'");
    for (const s of ["plain", "a'b", 'has "dq"', 'sp ace', 'a)(b', 'multi\nline', '$VAR `cmd`']) {
      const r = spawnSync('/bin/bash', ['-c', `printf %s ${shellQuote(s)}`], { encoding: 'utf8' });
      expect(r.stdout).toBe(s);
    }
  });
});

d('seatbelt spike — positive controls (instrument-dead guard)', () => {
  it('in-WS write LANDS (proves canonicalization: WS is a /tmp path reachable only via the canonical subpath rule)', () => {
    const r = runIntegrity(`echo hi > '${WS}/ctl_ok'`);
    expect(existsSync(join(WS, 'ctl_ok'))).toBe(true);
    expect(r.sandboxed).toBe(true);
  });
  it('outside READ succeeds (integrity is a write boundary, not confidentiality)', () => {
    const r = runIntegrity('head -1 /etc/hosts');
    expect(r.status).toBe(0);
  });
  it('/dev/null write succeeds (DEV_SINK explicitly allowed — it is NOT auto-exempt)', () => {
    const r = runIntegrity('echo x > /dev/null');
    expect(r.status).toBe(0);
  });
  it('a write to the per-user $TMPDIR succeeds (tool-compat allowance)', () => {
    const target = join(tmpdir(), `sb_tmp_ok_${process.pid}`);
    const r = runSandboxedBash(`echo hi > '${target}'`, { cwd: WS, workspaceRoot: WS, mode: 'integrity' });
    expect(r.status).toBe(0);
    expect(existsSync(target)).toBe(true);
    rmSync(target, { force: true });
  });
});

// The evasion matrix — every vector must FAIL to create its OUT file. Includes
// the four Ph111 string-gating residual evasions (python -c / node -e / base64 /
// env indirection) plus the shell vectors, nested shells, and the two exit-0-but-
// blocked cases (perl, python os.system) that prove file-existence is the verdict.
type Vector = { name: string; rel: string; make: (t: string) => string };
const VECTORS: Vector[] = [
  { name: 'shell redirect', rel: 'v_echo', make: (t) => `echo x > '${t}'` },
  { name: 'printf redirect', rel: 'v_printf', make: (t) => `printf x > '${t}'` },
  { name: 'append >>', rel: 'v_append', make: (t) => `echo x >> '${t}'` },
  { name: 'force-clobber >|', rel: 'v_clobber', make: (t) => `echo x >| '${t}'` },
  { name: 'python3 -c open (RESIDUAL)', rel: 'v_py', make: (t) => `python3 -c 'open("${t}","w").write("x")'` },
  { name: 'node -e writeFileSync (RESIDUAL)', rel: 'v_node', make: (t) => `node -e 'require("fs").writeFileSync("${t}","x")'` },
  { name: 'base64-decoded path (RESIDUAL)', rel: 'v_b64', make: (t) => `P=$(printf %s '${t}' | base64 | base64 -d); echo x > "$P"` },
  { name: 'env indirection (RESIDUAL)', rel: 'v_env', make: (t) => `env T='${t}' sh -c 'echo x > "$T"'` },
  { name: 'nested sh -c', rel: 'v_sh', make: (t) => `sh -c "echo x > '${t}'"` },
  { name: 'nested bash -c', rel: 'v_bash', make: (t) => `bash -c "echo x > '${t}'"` },
  { name: 'dd of=', rel: 'v_dd', make: (t) => `echo x | dd of='${t}' 2>/dev/null` },
  { name: 'tee', rel: 'v_tee', make: (t) => `echo x | tee '${t}' > /dev/null` },
  { name: 'cp', rel: 'v_cp', make: (t) => `cp /etc/hosts '${t}'` },
  { name: 'python low-level os.open', rel: 'v_open', make: (t) => `python3 -c 'import os; fd=os.open("${t}", os.O_CREAT|os.O_WRONLY); os.write(fd, b"x")'` },
  { name: 'mkdir', rel: 'v_mkdir', make: (t) => `mkdir '${t}'` },
  { name: 'touch', rel: 'v_touch', make: (t) => `touch '${t}'` },
  // exit-0-but-blocked: assert on file existence, not status.
  { name: 'perl (exits 0, write denied)', rel: 'v_perl', make: (t) => `perl -e 'open(F,">","${t}") or 1; print F "x";' || true` },
  { name: 'python os.system (exits 0, write denied)', rel: 'v_ossys', make: (t) => `python3 -c 'import os; os.system("echo x > ${t}")'` },
];

d('seatbelt spike — out-of-workspace write evasion matrix (file MUST NOT be created)', () => {
  it.each(VECTORS)('blocks: $name', ({ rel, make }) => {
    const target = join(OUT, rel);
    runIntegrity(make(target));
    expect(existsSync(target), `${target} should NOT exist (write must be denied)`).toBe(false);
  });
});

d('seatbelt spike — symlink + hardlink confused-deputy (resolved-target confinement)', () => {
  it('a symlink inside WS pointing to OUT does NOT let a write escape', () => {
    const link = join(WS, 'esc_link');
    symlinkSync(OUT, link);
    runIntegrity(`echo x > '${link}/owned_via_symlink'`);
    expect(existsSync(join(OUT, 'owned_via_symlink'))).toBe(false);
  });
  it('a HARDLINK from inside WS to an existing OUT file cannot be created (write-class op denied)', () => {
    // Hardlinks share an inode, so a write through an in-WS hardlink would modify
    // the OUT file's bytes. seatbelt denies the link CREATION itself (a write-class
    // op on the outside target), closing the inode-sharing escape (Ph112 review).
    const outFile = join(OUT, 'hardlink_target');
    writeFileSync(outFile, 'ORIGINAL');
    runIntegrity(`ln '${outFile}' '${join(WS, 'hl')}' && echo PWNED > '${join(WS, 'hl')}'`);
    expect(readFileSync(outFile, 'utf8')).toBe('ORIGINAL'); // outside bytes unchanged
  });
});

d('seatbelt spike — strict mode (network + mach), the maintainer-chosen profile', () => {
  it('in-WS write still LANDS under strict (control)', () => {
    runStrict(`echo hi > '${WS}/strict_ok'`);
    expect(existsSync(join(WS, 'strict_ok'))).toBe(true);
  });
  it('out-of-WS write still BLOCKED under strict (incl. python child inheritance)', () => {
    const target = join(OUT, 'strict_py');
    runStrict(`python3 -c 'open("${target}","w").write("x")'`);
    expect(existsSync(target)).toBe(false);
  });
  it('external network is DENIED (curl to an external host fails)', () => {
    const r = runStrict('curl -sS --max-time 5 https://example.com -o /dev/null');
    // Non-zero is the invariant: strict denies the outbound connection. (An
    // offline box also satisfies this — the assertion is "no external reach".)
    expect(r.status === null || r.status !== 0).toBe(true);
  });
  it('username still resolves (opendirectoryd.libinfo allow-listed) — degrades to a bare UID without it', () => {
    const r = runStrict('whoami');
    expect(r.stdout.trim()).toBe(userInfo().username);
  });
  it('per-user temp dir still resolves (bsd.dirhelper allow-listed)', () => {
    const r = runStrict('getconf DARWIN_USER_TEMP_DIR');
    expect(r.status).toBe(0);
    expect(r.stdout.trim().startsWith('/')).toBe(true);
  });
});

d('seatbelt spike — Pi spawnHook command-string path (wrapBashCommandString)', () => {
  // Pi's local executor re-parses the spawnHook command via `shell -c`, so the
  // command-string form survives one extra shell level. Prove it CONFINES and is
  // quoting-safe even when the inner command mixes single + double quotes.
  it('confines an out-of-WS write through the double-shell, quoting-safe', () => {
    const profile = buildProfile({ workspaceRoot: WS, mode: 'integrity' });
    const target = join(OUT, 'pi_path_blocked');
    const inner = `python3 -c "open('${target}','w').write('x')"`; // mixed quotes
    spawnSync('/bin/bash', ['-c', wrapBashCommandString(inner, profile)], { encoding: 'utf8' });
    expect(existsSync(target)).toBe(false);
  });
  it('in-WS write still LANDS through the same path (control)', () => {
    const profile = buildProfile({ workspaceRoot: WS, mode: 'integrity' });
    const target = join(WS, 'pi_path_ok');
    spawnSync('/bin/bash', ['-c', wrapBashCommandString(`echo x > '${target}'`, profile)], { encoding: 'utf8' });
    expect(existsSync(target)).toBe(true);
  });
});

d('seatbelt spike — SBPL injection hardening (fail-closed, pure)', () => {
  it('rejects a path with a double-quote', () => {
    expect(() => assertSafeProfilePath('/tmp/a"b')).toThrow();
  });
  it('rejects a well-formed quote-breakout injection', () => {
    expect(() => assertSafeProfilePath('/tmp/x")) (allow file-write* (subpath "/')).toThrow();
  });
  it('rejects a newline-injection', () => {
    expect(() => assertSafeProfilePath('/tmp/a\n(allow file-write* (subpath "/")')).toThrow();
  });
  it('rejects a backslash and a non-absolute path', () => {
    expect(() => assertSafeProfilePath('/tmp/a\\b')).toThrow();
    expect(() => assertSafeProfilePath('relative/path')).toThrow();
  });
  it('does NOT reject a legit absolute path with spaces and parens (inert in SBPL)', () => {
    expect(() => assertSafeProfilePath('/Users/me/My Project (1)/ws')).not.toThrow();
  });
  it('buildProfile throws on a malicious workspaceRoot (gate runs on the canonical result)', () => {
    expect(() => buildProfile({ workspaceRoot: '/tmp/x")) (allow file-write* (subpath "/' })).toThrow();
  });
  it('buildProfile emits a canonical subpath rule for a normal workspace', () => {
    const profile = buildProfile({ workspaceRoot: WS, mode: 'integrity' });
    expect(profile).toContain('(deny file-write*)');
    expect(profile).toContain(`(subpath "${canonicalizePath(WS)}")`);
    expect(profile).not.toContain('(deny network*)'); // integrity leaves network/mach open
  });
  it('strict profile adds the network + mach denials and the minimal allowlist', () => {
    const profile = buildProfile({ workspaceRoot: WS, mode: 'strict' });
    expect(profile).toContain('(deny network*)');
    expect(profile).toContain('(deny mach-lookup)');
    expect(profile).toContain('com.apple.system.opendirectoryd.libinfo');
    expect(profile).toContain('com.apple.bsd.dirhelper');
  });
});

// Ph112 adversarial-review fixes (pure, run on every platform): the canonicalize
// off-by-one (a non-existent root-child mangled to "/" or a wrong dir) and the
// "(subpath \"/\")" whole-FS over-grant must both be impossible.
describe('seatbelt — review-fix: canonicalize + root-reject (pure)', () => {
  it('canonicalizePath re-appends the leaf via basename — a non-existent root-child is NOT mangled', () => {
    expect(canonicalizePath('/nonexist-rootchild-xyz')).toBe('/nonexist-rootchild-xyz');
    expect(canonicalizePath('/d-nope-xyz')).toBe('/d-nope-xyz');
  });
  it('canonicalizePath NEVER collapses a non-existent root-child to "/"', () => {
    expect(canonicalizePath('/q')).not.toBe('/');
    expect(canonicalizePath('/q')).toBe('/q');
  });
  it('canonicalizePath resolves a non-existent leaf under an existing parent', () => {
    expect(canonicalizePath('/tmp/nonexist-leaf-abc')).toBe(join(canonicalizePath('/tmp'), 'nonexist-leaf-abc'));
  });
  it('buildProfile rejects workspaceRoot "/" (would grant whole-FS)', () => {
    expect(() => buildProfile({ workspaceRoot: '/' })).toThrow();
  });
  it('buildProfile rejects an extraWrites of "/" (the C1 root over-grant)', () => {
    expect(() => buildProfile({ workspaceRoot: '/tmp', extraWrites: ['/'] })).toThrow();
  });
  it('a non-existent root-child extraWrites grants ONLY that path, never "(subpath \\"/\\")"', () => {
    const profile = buildProfile({ workspaceRoot: '/tmp', extraWrites: ['/d'] });
    expect(profile).toContain('(subpath "/d")');
    expect(profile).not.toContain('(subpath "/")');
  });
});

d('seatbelt — review-fix functional regression (darwin): the /d→whole-FS PoC is closed', () => {
  it('a single-char root-child extraWrites no longer opens the whole filesystem', () => {
    const target = join(OUT, 'fs_should_block');
    // Pre-fix: extraWrites=['/d'] canonicalized to '/' → (subpath "/") → this write LANDED.
    runSandboxedBash(`echo x > '${target}'`, { cwd: WS, workspaceRoot: WS, mode: 'integrity', extraWrites: ['/d'] });
    expect(existsSync(target)).toBe(false);
  });
});
