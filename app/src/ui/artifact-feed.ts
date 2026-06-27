import type { SurfaceToolCall } from './runtime';
import { redactSecrets } from '../security/redact';

// Ph110 T5 / Ph111 T3: route ONE completed tool call to a typed artifact for the
// side panel, keyed on tool NAME + its typed details. Routing lives in the UI
// (ledger A4 — the engine layer stays opaque, no view taxonomy leaks across the
// adapter boundary). Ph111: when a call carries normalized typed `details.diff`
// (an edit), that STRUCTURED diff wins → DiffView, regardless of the output
// text's shape (Pi's edit diff has no ---/+++/@@ header, so the looksLikeDiff
// heuristic alone would miss it). Detail-absent / Vercel tools fall back to the
// Ph110 heuristic, else a terminal view (the generic-text fallback, ledger A3).
// Untrusted output + diff is redacted + capped, mirroring the inline rail.

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

/** Redact (untrusted) + bound the side-panel render. */
function capArtifact(raw: string): string {
  const text = redactSecrets(raw);
  return text.length > ARTIFACT_CAP
    ? `${text.slice(0, ARTIFACT_CAP)}\n…[+${text.length - ARTIFACT_CAP} chars]`
    : text;
}

/** Map one completed tool call to a typed artifact, or null if nothing to show. */
export function toArtifact(tc: SurfaceToolCall): Artifact | null {
  // Ph111 — the TYPED path WINS: a structured diff from the tool's typed details
  // renders a real DiffView regardless of the output text's shape. Pi's edit diff
  // is a +/-/space line format with NO ---/+++/@@ header (T1 spike), so the
  // looksLikeDiff heuristic below would MISS it; the typed channel is strictly
  // better. Redact + cap defensively (the router cannot assume an adapter did).
  if (typeof tc.details?.diff === 'string' && tc.details.diff.length > 0) {
    return { kind: 'diff', id: tc.id, name: tc.name, diff: capArtifact(tc.details.diff) };
  }
  if (tc.status !== 'done' || tc.output == null) return null;
  const raw = typeof tc.output === 'string' ? tc.output : JSON.stringify(tc.output, null, 2);
  const text = capArtifact(raw);
  // Heuristic fallback (Ph110): an edit/write whose OUTPUT looks like a unified
  // diff. Covers Vercel + detail-absent tools.
  if ((tc.name === 'edit' || tc.name === 'write') && looksLikeDiff(text)) {
    return { kind: 'diff', id: tc.id, name: tc.name, diff: text };
  }
  return { kind: 'terminal', id: tc.id, name: tc.name, text };
}

/** The live artifact list derived from a surface message's completed tool calls. */
export function toArtifacts(toolCalls: readonly SurfaceToolCall[]): Artifact[] {
  return toolCalls.map(toArtifact).filter((a): a is Artifact => a !== null);
}
