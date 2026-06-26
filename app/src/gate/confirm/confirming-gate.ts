import type { GateDecision, NormalizedToolCall, ToolCallGate } from '../../engine/types';
import type { ConfirmationBroker } from './broker';
import { computeDiff } from './diff';

// The EXACT marker the base host-gate uses for denials that a human MAY approve
// (Ph108 host-gate.ts: "... requires explicit human confirmation"). Matching the
// literal phrase is the security boundary: hard denials (secret/key-store reads
// and writes say "is denied" / "path denied"; malformed calls say "malformed
// ...") do NOT contain it and therefore can NEVER be turned into a confirmation.
// Tested against the REAL gate so wording drift is caught.
export const CONFIRMATION_MARKER = 'requires explicit human confirmation';

export function isConfirmable(reason: string): boolean {
  return reason.includes(CONFIRMATION_MARKER);
}

export interface ConfirmingGateOptions {
  /** Called when a held call is APPROVED, before it lands — e.g. snapshot for one-action revert (T4). */
  onApprove?: (call: NormalizedToolCall) => void;
}

/**
 * Wrap a base gate so a CONFIRMABLE denial becomes a human-confirm HOLD (axis 1
 * — preview & approve BEFORE it lands). The hold is an unresolved
 * Promise<GateDecision> — already legal (ToolCallGate may be async) and already
 * awaited by every adapter; the model's tool call blocks in-process until the
 * human answers. The base gate's CORE is unchanged; this is a host wrapper
 * injected via setToolCallGate.
 *
 * A non-confirmable denial (secret/key-store read or write, malformed call) is
 * passed through UNCHANGED — it stays a hard deny and is never surfaced for
 * approval. allow/modify pass through unchanged.
 */
export function createConfirmingGate(
  base: ToolCallGate,
  broker: ConfirmationBroker,
  opts: ConfirmingGateOptions = {},
): ToolCallGate {
  return async (call: NormalizedToolCall): Promise<GateDecision> => {
    const decision = await base(call);
    if (decision.action !== 'deny' || !isConfirmable(decision.reason)) {
      return decision; // allow / modify / hard-deny pass through unchanged
    }
    const approved = await broker.request({
      callId: call.id,
      toolName: call.name,
      args: call.args,
      diff: computeDiff(call),
      summary: decision.reason,
      path: typeof call.args.path === 'string' ? call.args.path : undefined,
    });
    if (approved) {
      opts.onApprove?.(call);
      return { action: 'allow' };
    }
    return { action: 'deny', reason: 'rejected by human' };
  };
}
