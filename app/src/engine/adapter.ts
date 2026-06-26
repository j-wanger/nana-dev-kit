import type { EngineEvent, ToolCallGate } from './types';

export interface SendPromptOptions {
  /**
   * Cancels an in-flight run (and any hung tool call). The hard-interrupt
   * control (T8, ≤2s) drives this; adapters must observe it promptly.
   */
  signal?: AbortSignal;
}

/**
 * The swappable boundary the app OWNS (decision [[engine-adapter-in-process-gate]]).
 *
 * Each concrete adapter embeds one agent engine in-process (Pi SDK primary,
 * Claude Agent SDK second, Vercel AI SDK fallback) and exposes it through this
 * single interface. Two responsibilities are fixed here so they are written
 * ONCE and reused across every engine:
 *
 *   1. `setToolCallGate` — the pre-tool-execution interception point. The host
 *      registers its gate here; the adapter is contractually required to run
 *      every tool call through it before side effects.
 *   2. `sendPrompt` — drive a turn and stream engine-neutral events.
 *
 * No engine SDK type may appear in this interface.
 */
export interface EngineAdapter {
  /** Stable identifier for the engine behind this adapter (e.g. 'noop', 'pi', 'claude'). */
  readonly id: string;

  /**
   * Register the host-owned, in-process pre-execution gate. Called once by the
   * host at wiring time. After this, every tool call the engine attempts must
   * pass through `gate` and honor its {@link GateDecision} before executing.
   */
  setToolCallGate(gate: ToolCallGate): void;

  /**
   * Send a user prompt and stream engine-neutral events as the turn runs.
   * The returned async iterable completes with a terminal `done` (or `error`).
   */
  sendPrompt(prompt: string, options?: SendPromptOptions): AsyncIterable<EngineEvent>;
}
