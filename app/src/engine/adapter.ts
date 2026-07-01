import type { EngineEvent, ModelInfo, SkillInfo, TemplateInfo, ThinkingInfo, ToolCallGate } from './types';

export interface SendPromptOptions {
  /**
   * Cancels an in-flight run (and any hung tool call). The hard-interrupt
   * control (T8, ≤2s) drives this; adapters must observe it promptly.
   */
  signal?: AbortSignal;

  /**
   * Per-turn system context assembled from the active workspace (Phase 109 / A2):
   * the project's AGENTS.md/CLAUDE.md + .claude/rules/*.md. When set, the adapter
   * injects it as the engine's system instructions so the agent is not
   * project-blind. When undefined, behavior is unchanged (no system context).
   */
  systemContext?: string;
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

  /**
   * Optional (Phase 119 T1): reset the engine's cross-turn conversation and
   * rebuild a fresh session with the gate re-attached. Adapters that hold a
   * PERSISTENT session (Pi) expose this as the crash-isolation recovery and the
   * "new conversation" action; stateless/per-turn adapters omit it. The host
   * calls it if present.
   */
  newConversation?(): Promise<void>;

  /**
   * Optional (Phase 119 T2): manually compact the engine's context. A session
   * mutation; the gate survives it. Adapters with a persistent, compactable
   * session (Pi) expose it; others omit it. The host calls it if present.
   */
  compact?(): Promise<void>;

  /** Optional (Phase 119 T4): the models available to switch to (local + hosted). */
  listModels?(): Promise<ModelInfo[]>;
  /** Optional (Phase 119 T4): the active model. */
  currentModel?(): Promise<ModelInfo | undefined>;
  /** Optional (Phase 119 T4): switch to a specific model (a gate-surviving mutation). */
  setModel?(providerId: string, modelId: string): Promise<boolean>;
  /** Optional (Phase 119 T4): cycle to the next available model (a gate-surviving mutation). */
  cycleModel?(): Promise<ModelInfo | undefined>;

  /** Optional (Phase 119 T5): the active thinking level + the ones the model offers. */
  thinkingInfo?(): Promise<ThinkingInfo>;
  /** Optional (Phase 119 T5): set the thinking level (a gate-surviving mutation). */
  setThinkingLevel?(level: string): Promise<void>;
  /** Optional (Phase 119 T5): cycle to the next thinking level (a gate-surviving mutation). */
  cycleThinkingLevel?(): Promise<string | undefined>;

  /** Optional (Phase 119 T7): the loaded prompt templates (palette slash-commands). */
  listPromptTemplates?(): Promise<TemplateInfo[]>;
  /** Optional (Phase 119 T7): the loaded skills (palette slash-commands). */
  listSkills?(): Promise<SkillInfo[]>;
}
