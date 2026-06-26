import { describe, it, expect } from 'vitest';
import { mkdtempSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { CheckpointStore, softDelete, restoreFromTrash } from '../../src/gate/checkpoint';

// A file edit routed through the checkpoint layer reverts to the EXACT pre-edit
// bytes in one action (Phase 108, T5).

function tmp(): string {
  return mkdtempSync(join(tmpdir(), 'nana-ckpt-'));
}

describe('checkpoint: one-action revert to exact pre-edit bytes', () => {
  it('reverts an edited file to byte-identical original content (binary-safe)', () => {
    const dir = tmp();
    const file = join(dir, 'data.bin');
    // Original includes non-UTF8 bytes + unicode to prove EXACT byte fidelity.
    const original = Buffer.from([0x00, 0x01, 0xff, 0xfe, 0x41, 0x42, 0xc3, 0xa9, 0x0a]);
    writeFileSync(file, original);

    const ckpt = new CheckpointStore();
    ckpt.snapshot(file); // pre-mutation

    writeFileSync(file, Buffer.from('totally different contents'));
    expect(readFileSync(file).equals(original)).toBe(false);

    ckpt.revert(file); // one action
    expect(readFileSync(file).equals(original)).toBe(true);
  });

  it('reverts a newly-created file back to non-existence', () => {
    const dir = tmp();
    const file = join(dir, 'created.txt');
    const ckpt = new CheckpointStore();
    ckpt.snapshot(file); // did not exist
    writeFileSync(file, 'the agent created this');
    expect(existsSync(file)).toBe(true);
    ckpt.revert(file);
    expect(existsSync(file)).toBe(false);
  });

  it('throws if asked to revert a path it never checkpointed', () => {
    const ckpt = new CheckpointStore();
    expect(() => ckpt.revert('/no/checkpoint/here')).toThrow();
  });

  it('soft-deletes to trash (recoverable), never unlink', () => {
    const dir = tmp();
    const file = join(dir, 'doomed.txt');
    const trash = join(dir, '.trash');
    const body = 'precious bytes';
    writeFileSync(file, body);

    const trashPath = softDelete(file, trash, 1);
    expect(existsSync(file)).toBe(false); // gone from working tree
    expect(existsSync(trashPath)).toBe(true); // but recoverable in trash
    expect(readFileSync(trashPath, 'utf8')).toBe(body);

    restoreFromTrash(trashPath, file);
    expect(readFileSync(file, 'utf8')).toBe(body);
  });
});
