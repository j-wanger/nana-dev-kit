import type { ToolCallGate } from '../types';

// The Vercel-AI-SDK gate integration (Phase 108, T7). The Vercel AI SDK has no
// pre-execution hook like Pi's tool_call, but the host OWNS the tool
// definitions — so we wrap each tool's `execute` to consult the SAME host gate
// before the real side effect. The gate logic is NOT duplicated: it lives in
// createHostGate and is reused verbatim, which is exactly what proves the gate
// is engine-neutral (one gate, two engines).

export interface GatedToolResult {
  denied?: boolean;
  reason?: string;
  output?: unknown;
}

/**
 * Wrap a real tool implementation so every call passes through the host gate
 * first. Deny -> the real impl never runs (no side effect) and a reason is
 * returned (+ onDenied fires). Modify -> the real impl runs with replaced args.
 */
export function createGatedToolExecute(
  name: string,
  getGate: () => ToolCallGate,
  realImpl: (args: Record<string, unknown>) => unknown | Promise<unknown>,
  onDenied?: (id: string, reason: string) => void,
): (args: Record<string, unknown>, options?: { toolCallId?: string }) => Promise<GatedToolResult> {
  return async (args, options) => {
    const id = options?.toolCallId ?? `${name}-call`;
    const decision = await getGate()({ id, name, args });
    if (decision.action === 'deny') {
      onDenied?.(id, decision.reason);
      return { denied: true, reason: decision.reason };
    }
    const finalArgs = decision.action === 'modify' ? decision.args : args;
    return { output: await realImpl(finalArgs) };
  };
}
