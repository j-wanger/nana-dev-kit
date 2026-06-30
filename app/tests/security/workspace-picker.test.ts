import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// Phase 114, T3 (A4) — the workspace picker is Rust-ATOMIC: the native folder
// dialog is opened from Rust (`pick_workspace` command), never from the webview,
// and the chosen path is the new gate root (the gate auto-allows in-workspace
// writes, so the workspace root IS the free-write zone). The renderer must NOT be
// able to relocate that root, so `pick_workspace` takes NO webview-supplied path
// argument and the capability manifest grants the renderer no broad fs/shell/http
// scope. The dialog runs Rust-side (which bypasses the webview ACL entirely), so
// the design grants the renderer no dialog permission at all — `dialog:allow-open`
// is the defense-in-depth ceiling this audit enforces, nothing broader.

const here = dirname(fileURLToPath(import.meta.url));
const tauriDir = resolve(here, '../../src-tauri');
const lib = readFileSync(resolve(tauriDir, 'src/lib.rs'), 'utf8');

describe('workspace picker — Rust-atomic, dialog-only capability (Phase 114 T3, A4)', () => {
  it('registers the native dialog plugin (Rust-side picker, not a webview dialog call)', () => {
    expect(lib).toMatch(/\.plugin\(\s*tauri_plugin_dialog::init\(\)\s*\)/);
  });

  it('exposes a `pick_workspace` command wired into the invoke handler', () => {
    expect(lib).toMatch(/fn\s+pick_workspace\s*\(/);
    const handler = lib.match(/generate_handler!\[([^\]]*)\]/s);
    expect(handler).not.toBeNull();
    expect(handler![1]).toMatch(/\bpick_workspace\b/);
  });

  it('pick_workspace takes NO webview-supplied path argument (the renderer cannot relocate the gate root)', () => {
    const sig = lib.match(/fn\s+pick_workspace\s*\(([^)]*)\)/s);
    expect(sig).not.toBeNull();
    const params = sig![1];
    // Only Tauri-injected params (AppHandle/State/Window) are allowed — never a
    // raw String/&str/PathBuf the renderer could fill with an arbitrary root.
    expect(params).not.toMatch(/:\s*(?:&\s*)?(?:String|str|PathBuf|Path)\b/);
  });

  it('the capability manifest grants no broad fs/shell/http/process/os scope, and at most dialog:allow-open', () => {
    const capDir = resolve(tauriDir, 'capabilities');
    const perms = readdirSync(capDir)
      .filter((f) => f.endsWith('.json'))
      .flatMap((f) => {
        const cap = JSON.parse(readFileSync(resolve(capDir, f), 'utf8'));
        return (cap.permissions ?? []) as string[];
      });
    const broad = /^(fs|shell|http|process|os):/;
    expect(perms.filter((p) => broad.test(p))).toEqual([]);
    // The folder-open dialog is the only dialog-family permission ever permitted;
    // save/message/ask/confirm and the broad default set stay out.
    const offendingDialog = perms.filter((p) => p.startsWith('dialog:') && p !== 'dialog:allow-open');
    expect(offendingDialog).toEqual([]);
  });
});
