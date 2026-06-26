import { readFile } from 'node:fs/promises';
import { isDeniedPath } from '../security/secret-deny';

// The agent's built-in file-read tool boundary (Phase 108, T2). It consults the
// centralized secret deny-list BEFORE touching the filesystem and returns a
// structured access-denied for any denied path. The in-process gate (T3) routes
// the engine's read tool through this same check, so denial is enforced at the
// dispatch site, not left to the model's discretion.

export type FileReadResult =
  | { ok: true; content: string }
  | { ok: false; error: 'access-denied'; reason: string };

export async function agentReadFile(path: string): Promise<FileReadResult> {
  if (isDeniedPath(path)) {
    return {
      ok: false,
      error: 'access-denied',
      reason: 'path is on the secret read-deny list',
    };
  }
  const content = await readFile(path, 'utf8');
  return { ok: true, content };
}
