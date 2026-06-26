import type { EngineAdapter, SendPromptOptions } from './adapter';
import type { EngineEvent, NormalizedToolCall, ToolCallGate } from './types';

/**
 * A scripted tool the {@link NoopAdapter} will attempt during a turn. `run` is
 * the observable side effect — it MUST NOT execute when the gate denies the
 * call, which is exactly what the contract test asserts.
 */
export interface ScriptedTool {
  call: NormalizedToolCall;
  /** The side effect. Receives the (possibly gate-modified) args; returns the tool result. */
  run: (args: Record<string, unknown>) => unknown;
}

export interface NoopAdapterOptions {
  scriptedTools?: ScriptedTool[];
}

/**
 * Reference EngineAdapter with no real engine behind it. It exists to pin the
 * adapter contract: it echoes the prompt and, for each scripted tool, routes
 * the call through the host gate BEFORE running the tool's side effect. Every
 * real adapter (Pi, Claude) must reproduce this same gate-then-dispatch
 * discipline at its engine's tool-dispatch site.
 *
 * Fail-safe note: with no gate registered the adapter defaults to allow, which
 * is fine for this engine-less reference. The production safety property comes
 * from the host ALWAYS registering a deny-by-default gate at wiring time (T3) —
 * the adapter cannot manufacture that guarantee on its own.
 */
export class NoopAdapter implements EngineAdapter {
  readonly id = 'noop';
  private gate: ToolCallGate | null = null;
  private readonly scriptedTools: ScriptedTool[];

  constructor(options: NoopAdapterOptions = {}) {
    this.scriptedTools = options.scriptedTools ?? [];
  }

  setToolCallGate(gate: ToolCallGate): void {
    this.gate = gate;
  }

  async *sendPrompt(
    prompt: string,
    options: SendPromptOptions = {},
  ): AsyncIterable<EngineEvent> {
    const { signal } = options;
    if (signal?.aborted) {
      yield { type: 'error', error: 'aborted' };
      return;
    }

    yield { type: 'text-delta', delta: `echo: ${prompt}` };

    for (const tool of this.scriptedTools) {
      if (signal?.aborted) {
        yield { type: 'error', error: 'aborted' };
        return;
      }

      yield { type: 'tool-call', call: tool.call };

      const decision = this.gate
        ? await this.gate(tool.call)
        : ({ action: 'allow' } as const);

      if (decision.action === 'deny') {
        // The load-bearing invariant: a denied call's side effect never runs.
        yield { type: 'tool-denied', id: tool.call.id, reason: decision.reason };
        continue;
      }

      const args = decision.action === 'modify' ? decision.args : tool.call.args;
      const result = tool.run(args);
      yield { type: 'tool-result', id: tool.call.id, result };
    }

    yield { type: 'done' };
  }
}
