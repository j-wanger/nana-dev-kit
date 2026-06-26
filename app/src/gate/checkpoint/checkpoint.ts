import { existsSync, mkdirSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';

// Per-mutation checkpoint layer (Phase 108, T5). Every file mutation the agent
// makes passes through here first: the pre-action bytes are snapshotted, so any
// turn rewinds to the EXACT prior bytes in one action. This is both the
// irreversible-bad-edit rail and the per-turn rewind axis of the north star
// (a confirm dialog is not a substitute). Deletes are soft (trash), never
// unlink — recoverable by design.

interface Snapshot {
  existed: boolean;
  bytes?: Buffer;
}

export class CheckpointStore {
  private readonly snapshots = new Map<string, Snapshot>();

  /** Capture a file's exact pre-mutation state. Records absence too (so revert can delete a created file). */
  snapshot(path: string): void {
    if (existsSync(path)) {
      this.snapshots.set(path, { existed: true, bytes: readFileSync(path) });
    } else {
      this.snapshots.set(path, { existed: false });
    }
  }

  hasCheckpoint(path: string): boolean {
    return this.snapshots.has(path);
  }

  /** One-action revert to the exact pre-action bytes (or back to non-existence). */
  revert(path: string): void {
    const snap = this.snapshots.get(path);
    if (!snap) throw new Error(`no checkpoint for ${path}`);
    if (snap.existed) {
      writeFileSync(path, snap.bytes!);
    } else if (existsSync(path)) {
      rmSync(path);
    }
  }
}

/**
 * Soft-delete: move a file into the trash dir instead of unlinking it. Returns
 * the trash path so the action is reversible. NEVER calls unlink on the target.
 */
export function softDelete(path: string, trashDir: string, stamp = 0): string {
  if (!existsSync(path)) throw new Error(`cannot soft-delete missing path: ${path}`);
  mkdirSync(trashDir, { recursive: true });
  // Caller passes a monotonic stamp to disambiguate repeated deletes of the same name.
  const dest = join(trashDir, `${basename(path)}.${stamp}.trashed`);
  renameSync(path, dest);
  return dest;
}

/** Restore a soft-deleted file from its trash path back to the original location. */
export function restoreFromTrash(trashPath: string, originalPath: string): void {
  if (!existsSync(trashPath)) throw new Error(`trash entry missing: ${trashPath}`);
  renameSync(trashPath, originalPath);
}

export function fileMtimeMs(path: string): number {
  return statSync(path).mtimeMs;
}
