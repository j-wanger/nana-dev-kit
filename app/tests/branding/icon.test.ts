import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const app = (p: string) => resolve(here, '../../', p);

// Ph110 T7: a real Nana app icon replaces the stock Tauri placeholder. MECHANICS
// only — the visual / felt quality is the maintainer's call (UI carve-out). The
// pinned hash is the ORIGINAL Tauri placeholder icon.png we replaced; the test
// asserts we are no longer shipping it.
const TAURI_PLACEHOLDER_ICON_SHA = '96308f3b33630ea14169292363b3395b0ba21480e2f42837663c89aa8938dff0';

const sha = (p: string) => createHash('sha256').update(readFileSync(p)).digest('hex');

describe('app branding — Nana icon (Ph110 T7)', () => {
  it('the generated icon source is a 1024×1024 PNG', () => {
    const src = app('assets/icon-source.png');
    expect(existsSync(src)).toBe(true);
    const buf = readFileSync(src);
    expect(buf.subarray(0, 8).toString('hex')).toBe('89504e470d0a1a0a'); // PNG signature
    expect(buf.readUInt32BE(16)).toBe(1024); // IHDR width
    expect(buf.readUInt32BE(20)).toBe(1024); // IHDR height
  });

  it('the Tauri icon set is regenerated (every referenced file present)', () => {
    for (const f of [
      '32x32.png',
      '128x128.png',
      '128x128@2x.png',
      'icon.icns',
      'icon.ico',
      'icon.png',
    ]) {
      expect(existsSync(app(`src-tauri/icons/${f}`)), f).toBe(true);
    }
  });

  it('icon.png is NO LONGER the stock Tauri placeholder', () => {
    expect(sha(app('src-tauri/icons/icon.png'))).not.toBe(TAURI_PLACEHOLDER_ICON_SHA);
  });

  it('tauri.conf.json references the bundled icons', () => {
    const conf = JSON.parse(readFileSync(app('src-tauri/tauri.conf.json'), 'utf8'));
    const icons: string[] = conf.bundle?.icon ?? [];
    expect(icons).toContain('icons/32x32.png');
    expect(icons).toContain('icons/icon.icns');
    expect(icons.length).toBeGreaterThanOrEqual(4);
  });
});
