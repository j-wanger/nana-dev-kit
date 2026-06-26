import { describe, it, expect } from 'vitest';
import { normalizeToolCall, toolCallBytes, ToolCallSchemaError } from '../../src/engine/normalize';

// The same tool call serialized through ≥2 provider adapters normalizes to a
// byte-identical internal representation (Phase 108, T8). Prevents a
// model-agnostic parser from silently editing the wrong file.

describe('tool-call normalization: byte-identical across adapters', () => {
  it('the same logical call from two adapters normalizes byte-identically (arg order independent)', () => {
    // Pi reports args one way; the Vercel/OpenAI path may order keys differently.
    const piShaped = { id: 'call_1', name: 'write', args: { path: 'a.txt', content: 'hi' } };
    const vercelShaped = { id: 'call_1', name: 'write', args: { content: 'hi', path: 'a.txt' } };

    const a = normalizeToolCall(piShaped);
    const b = normalizeToolCall(vercelShaped);

    expect(toolCallBytes(a)).toBe(toolCallBytes(b)); // byte-identical
  });

  it('canonicalizes nested object keys deterministically', () => {
    const x = normalizeToolCall({ id: '1', name: 't', args: { a: { y: 1, x: 2 }, b: 3 } });
    const y = normalizeToolCall({ id: '1', name: 't', args: { b: 3, a: { x: 2, y: 1 } } });
    expect(toolCallBytes(x)).toBe(toolCallBytes(y));
  });

  it('REJECTS (never coerces) a malformed tool call', () => {
    expect(() => normalizeToolCall({ id: '', name: 'x', args: {} })).toThrow(ToolCallSchemaError);
    expect(() => normalizeToolCall({ id: 'x', name: '', args: {} })).toThrow(ToolCallSchemaError);
    expect(() => normalizeToolCall({ id: 'x', name: 'bash', args: 'not-an-object' })).toThrow(ToolCallSchemaError);
    expect(() => normalizeToolCall({ id: 'x', name: 'bash', args: ['a', 'b'] })).toThrow(ToolCallSchemaError);
  });

  it('preserves arg values exactly (no lossy coercion)', () => {
    const call = normalizeToolCall({ id: 'c', name: 'bash', args: { command: 'rm -rf /', n: 42, ok: false } });
    expect(call.args).toEqual({ command: 'rm -rf /', n: 42, ok: false });
  });
});
