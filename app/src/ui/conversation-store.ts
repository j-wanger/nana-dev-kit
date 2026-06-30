import { redactSecrets } from '../security/redact';
import type { UiMessage } from './chat-binding';
import type { SurfaceMessage, SurfaceToolCall } from './runtime';

// Phase 115 — conversation memory. Persist + restore the chat thread per
// workspace so an app restart no longer loses it, and a workspace change swaps
// (rather than leaks) the thread.
//
// T1 — redaction at the PERSISTENCE boundary. The in-memory store holds RAW tool
// args: the Pi adapter redacts tool OUTPUT and the typed `details.diff`
// (pi-adapter.ts extractToolText/extractToolDetails), but tool ARGS are forwarded
// verbatim (runtime.ts applyEngineEvent 'tool-call'; gate-bridge passes the live
// input). The render layer redacts args only at projection time (chat-binding
// toolArgsText). So serializing the store as-is would write secrets to disk — the
// at-rest class the redact rail closes for the DOM. redactForPersist is the
// structured walker applied before ANYTHING is written to localStorage.
//
// RESIDUAL (Ph115 A1, accepted): redactSecrets is pattern-based. The `write`
// tool's `content` body — the highest at-rest risk field (an agent-written .env)
// — is STRIPPED to a size marker, but a short / non-prefixed token, or a
// plaintext secret in a NON-write body (e.g. an `edit` new_string), is
// redacted-not-stripped and may persist. Same content the live DOM already
// showed; the delta is durability (memory -> disk).

/** Deep-redact every string leaf of an arbitrary JSON-ish value. */
function redactDeep(v: unknown): unknown {
  if (typeof v === 'string') return redactSecrets(v);
  if (Array.isArray(v)) return v.map(redactDeep);
  if (v && typeof v === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, val] of Object.entries(v as Record<string, unknown>)) out[k] = redactDeep(val);
    return out;
  }
  return v; // number | boolean | null | undefined
}

function byteLen(s: string): number {
  return new TextEncoder().encode(s).length;
}

/**
 * Redact (and, for the write tool, STRIP) a tool call's args for at-rest
 * persistence. The write `content` body is replaced by a size marker — the path
 * is kept so the restored thread still shows WHAT file was written.
 */
function redactArgs(name: string, args: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(args)) {
    if (name === 'write' && k === 'content') {
      const raw = typeof v === 'string' ? v : JSON.stringify(v ?? '');
      out[k] = `«write content omitted: ${byteLen(raw)} bytes»`;
    } else {
      out[k] = redactDeep(v);
    }
  }
  return out;
}

function redactToolCall(tc: SurfaceToolCall): SurfaceToolCall {
  return {
    id: tc.id,
    name: tc.name,
    // Finalize a non-terminal status: a turn interrupted after `tool-call` but
    // before `tool-result` would otherwise restore as a perpetual tool spinner
    // (the per-tool analogue of the message `done` finalize below).
    status: tc.status === 'called' ? 'done' : tc.status,
    ...(tc.reason !== undefined ? { reason: redactSecrets(tc.reason) } : {}),
    ...(tc.args !== undefined ? { args: redactArgs(tc.name, tc.args) } : {}),
    ...(tc.output !== undefined ? { output: redactDeep(tc.output) } : {}),
    ...(tc.isError !== undefined ? { isError: tc.isError } : {}),
    // redactDeep (not a verbatim forward) so any present/future `details` field
    // is redacted symmetrically with every other persisted leaf.
    ...(tc.details !== undefined ? { details: redactDeep(tc.details) as { diff?: string } } : {}),
  };
}

/**
 * Redact ONE UiMessage for at-rest persistence. Pure — returns a new message,
 * never mutates the live store. Finalizes a mid-stream (done:false) turn to
 * done:true: a restored turn has no engine behind it, and chat-binding renders
 * done:false as status:'running' — a perpetual spinner. The turn `error`, if
 * present, is preserved (and redacted), so a failed turn still reads as failed.
 */
export function redactForPersist(m: UiMessage): UiMessage {
  if (m.role === 'user') return { role: 'user', text: redactSecrets(m.text) };
  const msg: SurfaceMessage = {
    role: 'assistant',
    text: redactSecrets(m.text),
    toolCalls: m.toolCalls.map(redactToolCall),
    done: true,
    ...(m.error !== undefined ? { error: redactSecrets(m.error) } : {}),
  };
  return msg;
}

// T2 — persistence. One conversation per workspace, keyed by the workspace root.
// Bounded primarily by message count (turn-ish), with a byte ceiling backstop so
// a few huge tool outputs can't blow the shared localStorage origin quota. Every
// path is fail-soft: a read/parse/quota failure degrades to an empty thread or a
// skipped write — it NEVER throws into a React effect/render.

const KEY_PREFIX = 'nana.conv.v1:';
export const MAX_MESSAGES = 400; // ~200 turns — the primary bound
// Per-workspace byte backstop. Kept well under the ~5MB localStorage origin quota
// (shared across every workspace's key) so a handful of active workspaces coexist.
// RESIDUAL: there is no cross-workspace LRU eviction — past ~15-20 large active
// workspaces, new saves fail-soft (skip, prior thread preserved), never corrupt.
const MAX_BYTES = 256_000;

function ls(): Storage | null {
  try {
    return typeof localStorage !== 'undefined' ? localStorage : null;
  } catch {
    return null; // some webviews throw on access when storage is disabled
  }
}

function storageKey(key: string): string {
  return KEY_PREFIX + key;
}

/** A persisted element is only restorable if it is shape-valid for chat-binding. */
function isValidMessage(m: unknown): m is UiMessage {
  if (!m || typeof m !== 'object') return false;
  const role = (m as { role?: unknown }).role;
  const text = (m as { text?: unknown }).text;
  if (role === 'user') return typeof text === 'string';
  if (role === 'assistant') {
    const toolCalls = (m as { toolCalls?: unknown }).toolCalls;
    if (typeof text !== 'string' || !Array.isArray(toolCalls)) return false;
    // Validate each element too — a tampered `toolCalls:[null]` passes Array.isArray
    // but crashes chat-binding's surfaceToThreadMessage (reads tc.id/tc.args) on render.
    return toolCalls.every(
      (t) =>
        t != null &&
        typeof t === 'object' &&
        typeof (t as { id?: unknown }).id === 'string' &&
        typeof (t as { name?: unknown }).name === 'string' &&
        typeof (t as { status?: unknown }).status === 'string',
    );
  }
  return false;
}

/**
 * Persist a conversation for a workspace. Redacts at the boundary (redactForPersist),
 * bounds by count then bytes, and prunes-oldest-and-retries on a QuotaExceededError.
 * NEVER throws into a React effect/render, and NEVER overwrites a good thread with an
 * empty array: a non-empty conversation is pruned no further than its newest message,
 * and a write that still fails is skipped (the prior persisted thread is preserved).
 */
export function saveConversation(key: string, messages: UiMessage[]): void {
  try {
    const store = ls();
    if (!store) return;
    let kept = messages.map(redactForPersist).slice(-MAX_MESSAGES);
    // byte backstop — keep at least the newest message (length > 1, not > 0): never
    // prune a non-empty thread to [] and overwrite good history with "[]".
    while (kept.length > 1 && byteLen(JSON.stringify(kept)) > MAX_BYTES) kept = kept.slice(1);
    for (;;) {
      try {
        store.setItem(storageKey(key), JSON.stringify(kept));
        return;
      } catch {
        // QuotaExceeded (or any storage error): drop the oldest and retry, but at
        // the last message stop — skip the write rather than clobber the prior value.
        if (kept.length <= 1) return;
        kept = kept.slice(1);
      }
    }
  } catch {
    /* fail-soft: redact/serialize/encode failures never reach a React effect/render */
  }
}

/** Load a workspace's persisted conversation. Fail-soft: corrupt / wrong-shape -> []. */
export function loadConversation(key: string): UiMessage[] {
  const store = ls();
  if (!store) return [];
  let raw: string | null;
  try {
    raw = store.getItem(storageKey(key));
  } catch {
    return [];
  }
  if (!raw) return [];
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return [];
  }
  if (!Array.isArray(parsed) || !parsed.every(isValidMessage)) return [];
  return parsed as UiMessage[];
}

/** Drop a workspace's persisted conversation (newConversation, or an explicit clear). */
export function clearConversation(key: string): void {
  const store = ls();
  if (!store) return;
  try {
    store.removeItem(storageKey(key));
  } catch {
    /* fail-soft */
  }
}
