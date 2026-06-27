// Canonical, engine-neutral types shared by every EngineAdapter.
//
// The whole point of the adapter boundary (Phase 108 / decision
// [[engine-adapter-in-process-gate]]): NO engine-specific types (Pi, Claude
// Agent SDK, Vercel AI SDK) may leak across it. Each adapter normalizes its
// engine's tool calls and events INTO these types, so the host gate and the
// surface speak one vocabulary regardless of which engine is behind the wheel.

/**
 * One tool call, normalized to a plain JSON shape, as it is about to be
 * dispatched. This is the unit the in-process pre-execution gate inspects.
 * `id` correlates a call with its later result/denial.
 */
export interface NormalizedToolCall {
  id: string;
  name: string;
  args: Record<string, unknown>;
}

/**
 * The host gate's verdict on a tool call, decided BEFORE any side effect runs:
 *   - allow:  dispatch the call as-is.
 *   - deny:   block the call entirely; the side effect never runs.
 *   - modify: dispatch the call with replacement args (e.g. redirect a write
 *             into a sandboxed path). The original args are discarded.
 */
export type GateDecision =
  | { action: 'allow' }
  | { action: 'deny'; reason: string }
  | { action: 'modify'; args: Record<string, unknown> };

/**
 * The host-owned, in-process pre-execution gate. Every adapter MUST route every
 * tool call through this function and honor its decision before the tool's side
 * effects run. The model has no channel to deregister it — that un-bypassability
 * is the load-bearing invariant of the harness, and is verified empirically
 * (not assumed) by the T3 security tests.
 */
export type ToolCallGate = (
  call: NormalizedToolCall,
) => GateDecision | Promise<GateDecision>;

/**
 * Engine-neutral event emitted while a prompt runs. Shaped to map cleanly onto
 * an AI-SDK-style data stream so the surface (assistant-ui custom runtime, T6)
 * can render any engine identically.
 */
export type EngineEvent =
  | { type: 'text-delta'; delta: string }
  | { type: 'tool-call'; call: NormalizedToolCall }
  // `result` is the raw tool output (consistent across adapters: Pi forwards
  // ToolExecutionEndEvent.result, Vercel forwards the AI-SDK part.output). A
  // tool EXECUTION error (distinct from a host-gate `tool-denied`) rides the
  // additive optional `isError` — adapters that don't distinguish it omit it.
  // Ph111: `details` carries a NORMALIZED, engine-neutral view of a tool's typed
  // result (Pi's AgentToolResult.details → e.g. EditToolDetails.diff). Kept to a
  // whitelisted JSON shape so NO engine type crosses the boundary
  // ([[engine-adapter-in-process-gate]]); the UI's mapToArtifact still owns the
  // VIEW-kind decision. Additive: adapters with no typed details omit it.
  | {
      type: 'tool-result';
      id: string;
      result: unknown;
      isError?: boolean;
      details?: { diff?: string };
    }
  // Ph110: partial/streaming output while a tool is still executing (Pi's
  // tool_execution_update.partialResult), folded into the in-flight call so a
  // long local-model tool run streams per-step instead of looking frozen.
  // Additive: adapters that don't stream simply never emit it.
  | { type: 'tool-progress'; id: string; partial: unknown }
  | { type: 'tool-denied'; id: string; reason: string }
  | { type: 'error'; error: string }
  | { type: 'done' };
