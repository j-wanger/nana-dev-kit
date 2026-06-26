import type { ToolCallGate } from '../types';

// The ONLY Pi-specific glue for the gate (Phase 108, T3). It translates between
// Pi's `tool_call` extension event and the engine-neutral host gate, per Pi's
// documented contract (verified against the package docs):
//   - deny   -> return { block: true, reason }
//   - modify -> mutate event.input IN PLACE (no return); Pi runs no re-validation
//   - allow  -> return undefined
// Kept deliberately small and Pi-typed only at this seam so the host gate stays
// engine-neutral and the translation is unit-testable with a synthetic event.

/** The subset of Pi's ToolCallEvent the bridge needs (structurally compatible). */
export interface PiToolCallEvent {
  toolName: string;
  toolCallId: string;
  input: Record<string, unknown>;
}

/** What a Pi `tool_call` handler may return: block, or nothing. */
export type PiToolCallResult = { block: true; reason?: string } | undefined;

export async function applyHostGate(
  event: PiToolCallEvent,
  gate: ToolCallGate,
): Promise<PiToolCallResult> {
  const decision = await gate({
    id: event.toolCallId,
    name: event.toolName,
    // Pass the live args; the gate reads them and never mutates the call object.
    args: event.input,
  });

  switch (decision.action) {
    case 'deny':
      return { block: true, reason: decision.reason };
    case 'modify': {
      // Replace the tool args in place: clear existing keys, then assign the
      // gate's replacement. Mutation is how Pi accepts argument patches.
      for (const key of Object.keys(event.input)) delete event.input[key];
      Object.assign(event.input, decision.args);
      return undefined;
    }
    case 'allow':
      return undefined;
  }
}
