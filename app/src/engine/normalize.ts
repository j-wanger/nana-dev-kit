import type { NormalizedToolCall } from './types';

// The single tool-call normalization chokepoint (Phase 108, T8). Per-engine
// adapters parse their own tool-call wire formats, then funnel through THIS
// function into one canonical representation feeding the gate. It REJECTS
// (never coerces) a call whose shape is invalid, and canonicalizes arg key
// order so the same logical call from any adapter is byte-identical — which
// prevents a model-agnostic parser from silently editing the wrong thing.

export class ToolCallSchemaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ToolCallSchemaError';
  }
}

/** Deep-sort object keys so JSON serialization is deterministic across adapters. */
function canonicalize(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonicalize);
  if (value && typeof value === 'object') {
    const out: Record<string, unknown> = {};
    for (const key of Object.keys(value as Record<string, unknown>).sort()) {
      out[key] = canonicalize((value as Record<string, unknown>)[key]);
    }
    return out;
  }
  return value;
}

export function normalizeToolCall(raw: { id?: unknown; name?: unknown; args?: unknown }): NormalizedToolCall {
  if (typeof raw.id !== 'string' || raw.id.length === 0) {
    throw new ToolCallSchemaError('tool call `id` must be a non-empty string');
  }
  if (typeof raw.name !== 'string' || raw.name.length === 0) {
    throw new ToolCallSchemaError('tool call `name` must be a non-empty string');
  }
  if (typeof raw.args !== 'object' || raw.args === null || Array.isArray(raw.args)) {
    throw new ToolCallSchemaError('tool call `args` must be a plain object');
  }
  return { id: raw.id, name: raw.name, args: canonicalize(raw.args) as Record<string, unknown> };
}

/** Deterministic byte representation of a normalized tool call (key order fixed). */
export function toolCallBytes(call: NormalizedToolCall): string {
  return JSON.stringify({ id: call.id, name: call.name, args: call.args });
}
