import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync } from 'node:fs';

// Shared-tree safety (Phase 108, T5). The working tree is shared, not owned:
// the maintainer's other editor may change a file between the agent's read and
// its write. Before any write, we detect that drift (content hash, with mtime as
// a cheap pre-check) and HOLD the write rather than clobber concurrent edits.

function sha256(buf: Buffer): string {
  return createHash('sha256').update(buf).digest('hex');
}

interface ReadRecord {
  mtimeMs: number;
  hash: string;
}

export type GuardedWrite = { written: true } | { written: false; held: string };

export class ExternalModGuard {
  private readonly reads = new Map<string, ReadRecord>();

  /** Record a file's state at the moment the agent reads it. */
  recordRead(path: string): void {
    const bytes = readFileSync(path);
    this.reads.set(path, { mtimeMs: statSync(path).mtimeMs, hash: sha256(bytes) });
  }

  /**
   * True if the file changed since the agent read it. A file deleted externally,
   * or whose content hash differs, counts as modified. If we never recorded a
   * read, we cannot claim drift (caller decides policy).
   */
  isExternallyModified(path: string): boolean {
    const rec = this.reads.get(path);
    if (!rec) return false;
    if (!existsSync(path)) return true; // deleted out from under us
    if (statSync(path).mtimeMs === rec.mtimeMs) return false; // cheap path: untouched
    return sha256(readFileSync(path)) !== rec.hash; // mtime moved — confirm by content
  }

  /**
   * Gate a write: refuse (hold) if the file was modified externally since the
   * read. The caller performs the actual write only on `{ written: true }`.
   */
  guard(path: string): GuardedWrite {
    if (this.isExternallyModified(path)) {
      return { written: false, held: 'file modified externally since the agent read it' };
    }
    return { written: true };
  }
}
