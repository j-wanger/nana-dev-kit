import { describe, it, expect } from 'vitest';
import { mkdtempSync, writeFileSync, utimesSync, statSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { ExternalModGuard } from '../../src/gate/checkpoint';

// A file modified externally between the agent's read and its write is detected
// and the write is held (Phase 108, T5) — never clobber the maintainer's
// concurrent edits from another editor.

function tmp(): string {
  return mkdtempSync(join(tmpdir(), 'nana-extmod-'));
}

// Force a file's mtime forward so the cheap mtime pre-check fires deterministically.
function bumpMtime(file: string): void {
  const now = statSync(file).mtimeMs / 1000;
  utimesSync(file, now + 5, now + 5);
}

describe('external-modification: hold the write when the tree changed underneath', () => {
  it('detects an external content change and holds the write', () => {
    const dir = tmp();
    const file = join(dir, 'shared.ts');
    writeFileSync(file, 'export const x = 1;\n');

    const guard = new ExternalModGuard();
    guard.recordRead(file); // agent reads it

    // Another editor changes it before the agent writes.
    writeFileSync(file, 'export const x = 999; // edited elsewhere\n');
    bumpMtime(file);

    expect(guard.isExternallyModified(file)).toBe(true);
    expect(guard.guard(file)).toEqual({ written: false, held: expect.any(String) });
  });

  it('detects external deletion as a modification', () => {
    const dir = tmp();
    const file = join(dir, 'gone.ts');
    writeFileSync(file, 'data');
    const guard = new ExternalModGuard();
    guard.recordRead(file);
    rmSync(file); // delete it externally

    expect(guard.isExternallyModified(file)).toBe(true);
  });

  it('allows the write when the file is untouched since the read', () => {
    const dir = tmp();
    const file = join(dir, 'stable.ts');
    writeFileSync(file, 'export const y = 2;\n');
    const guard = new ExternalModGuard();
    guard.recordRead(file);
    expect(guard.isExternallyModified(file)).toBe(false);
    expect(guard.guard(file)).toEqual({ written: true });
  });

  it('treats a touched-but-identical file as unmodified (content hash, not just mtime)', () => {
    const dir = tmp();
    const file = join(dir, 'touched.ts');
    writeFileSync(file, 'same bytes');
    const guard = new ExternalModGuard();
    guard.recordRead(file);
    bumpMtime(file); // mtime moves, content identical
    expect(guard.isExternallyModified(file)).toBe(false);
  });
});
