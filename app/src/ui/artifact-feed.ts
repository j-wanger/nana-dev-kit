import type { SurfaceToolCall } from './runtime';
import { redactSecrets } from '../security/redact';

// Ph110 T5: route ONE completed tool call to a typed artifact for the side
// panel, keyed on tool NAME. Routing lives in the UI (ledger A4 — the engine
// layer stays opaque, no view taxonomy leaks across the adapter boundary). A
// real edit/write diff → the typed DiffView; everything else → a terminal view
// (the generic-text fallback, ledger A3). Typed test/diff-from-structured-details
// sharpens when Pi's typed `details` are threaded (deferred from T1; A3
// revisit-status: open). Untrusted output is redacted, mirroring the inline rail.

export type Artifact =
  | { kind: 'diff'; id: string; name: string; diff: string }
  | { kind: 'terminal'; id: string; name: string; text: string };

const ARTIFACT_CAP = 16_384;

function looksLikeDiff(text: string): boolean {
  // Require unified-diff STRUCTURE (a file/hunk header), NOT a bare +/- line —
  // prose bullets like "- added foo" in an edit/write message are not a diff
  // and must not render through DiffView as red/green deletions (review artifacts-2).
  return /^(---|\+\+\+|@@|diff --git)/m.test(text);
}

/** Map one completed tool call to a typed artifact, or null if nothing to show. */
export function toArtifact(tc: SurfaceToolCall): Artifact | null {
  if (tc.status !== 'done' || tc.output == null) return null;
  const raw = typeof tc.output === 'string' ? tc.output : JSON.stringify(tc.output, null, 2);
  let text = redactSecrets(raw);
  // Bound the side-panel render even for a large non-string result that capOutput
  // (string-only) didn't cap upstream (review reduction-3).
  if (text.length > ARTIFACT_CAP) {
    text = `${text.slice(0, ARTIFACT_CAP)}\n…[+${text.length - ARTIFACT_CAP} chars]`;
  }
  if ((tc.name === 'edit' || tc.name === 'write') && looksLikeDiff(text)) {
    return { kind: 'diff', id: tc.id, name: tc.name, diff: text };
  }
  return { kind: 'terminal', id: tc.id, name: tc.name, text };
}

/** The live artifact list derived from a surface message's completed tool calls. */
export function toArtifacts(toolCalls: readonly SurfaceToolCall[]): Artifact[] {
  return toolCalls.map(toArtifact).filter((a): a is Artifact => a !== null);
}
