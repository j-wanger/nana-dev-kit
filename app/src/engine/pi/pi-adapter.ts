import { resolve, join } from 'node:path';
import { mkdirSync, writeFileSync } from 'node:fs';
import {
  AuthStorage,
  createAgentSession,
  DefaultResourceLoader,
  getAgentDir,
  ModelRegistry,
  SessionManager,
} from '@earendil-works/pi-coding-agent';
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';
import type { EngineAdapter, SendPromptOptions } from '../adapter';
import type { EngineEvent, ToolCallGate } from '../types';
import { createHostGate } from '../../gate/host-gate';
import { applyHostGate, type PiToolCallEvent } from './gate-bridge';
import { getSecret } from '../../security/keystore';
import { redactSecrets } from '../../security/redact';
import { EventQueue } from '../event-queue';

// Minimal view of the Pi subscribe events the adapter consumes. The full
// AgentSessionEvent union is large; we narrow on `type` and read only the fields
// we map, casting at the subscribe seam so the rest of the engine stays
// Pi-type-free.
type PiStreamEvent =
  | { type: 'message_update'; assistantMessageEvent: { type: string; delta?: string } }
  | { type: 'tool_execution_start'; toolName: string; toolCallId?: string; args?: unknown }
  | {
      type: 'tool_execution_end';
      toolName?: string;
      toolCallId?: string;
      result?: unknown;
      isError?: boolean;
    }
  | {
      type: 'tool_execution_update';
      toolName?: string;
      toolCallId?: string;
      args?: unknown;
      partialResult?: unknown;
    }
  | { type: string };

/**
 * Max chars of a single tool output forwarded to the surface. Keeps the
 * stdin/stdout line protocol bounded and the React state from ballooning on a
 * multi-megabyte read/bash result; the full output is the engine's to keep.
 */
const OUTPUT_CAP = 16_384;

/**
 * Coerce Pi's `args: any` to the engine-neutral Record. Pi's built-in tool
 * inputs are always objects (BashToolInput, EditToolInput, …); a non-object is
 * an unexpected shape we surface as empty rather than crash the reduction.
 */
function asArgsRecord(args: unknown): Record<string, unknown> {
  return args && typeof args === 'object' && !Array.isArray(args)
    ? (args as Record<string, unknown>)
    : {};
}

/**
 * Cap an oversized string output; non-string results pass through untouched
 * (typed structures the artifact router reads downstream, T5).
 */
function capOutput(result: unknown): unknown {
  if (typeof result === 'string' && result.length > OUTPUT_CAP) {
    return `${result.slice(0, OUTPUT_CAP)}\n…[truncated ${result.length - OUTPUT_CAP} chars]`;
  }
  return result;
}

/**
 * Pi forwards tool results as AgentToolResult WRAPPER objects
 * ({content:[{type:'text',text}], details}), NOT strings (Ph110 review
 * boundary-1) — extract the text content before it crosses the adapter boundary,
 * else the surface renders `{"content":[…]}` JSON noise and the OUTPUT_CAP never
 * fires. Redact BEFORE capping so a secret can't be split across the cap boundary
 * (review security-2) and never crosses the stdin/stdout line protocol
 * un-redacted (defense-in-depth ahead of the UI-side redaction).
 */
function extractToolText(result: unknown): unknown {
  if (result == null) return result;
  let text: string;
  if (typeof result === 'string') {
    text = result;
  } else if (typeof result === 'object' && Array.isArray((result as { content?: unknown }).content)) {
    text = (result as { content: Array<{ type?: string; text?: string }> }).content
      .filter((c) => c && c.type === 'text' && typeof c.text === 'string')
      .map((c) => c.text as string)
      .join('\n');
  } else {
    text = JSON.stringify(result);
  }
  return capOutput(redactSecrets(text));
}

/**
 * Pure mapping from one Pi subscribe event to one engine-neutral EngineEvent
 * (or null to skip). Extracted as a seam so it is unit-testable without a live
 * Pi session (Ph110 T1). It forwards the REAL args (tool_execution_start.args)
 * and REAL output (tool_execution_end.result) Pi already carries — Ph108 stubbed
 * args:{} / result:{isError}, which is why allowed tool calls rendered name-only.
 */
export function mapPiStreamEvent(event: PiStreamEvent): EngineEvent | null {
  switch (event.type) {
    case 'message_update': {
      const ame = (event as Extract<PiStreamEvent, { type: 'message_update' }>)
        .assistantMessageEvent;
      if (ame?.type === 'text_delta' && typeof ame.delta === 'string') {
        return { type: 'text-delta', delta: ame.delta };
      }
      return null;
    }
    case 'tool_execution_start': {
      const e = event as Extract<PiStreamEvent, { type: 'tool_execution_start' }>;
      return {
        type: 'tool-call',
        call: { id: e.toolCallId ?? '', name: e.toolName, args: asArgsRecord(e.args) },
      };
    }
    case 'tool_execution_end': {
      const e = event as Extract<PiStreamEvent, { type: 'tool_execution_end' }>;
      return {
        type: 'tool-result',
        id: e.toolCallId ?? '',
        result: extractToolText(e.result),
        isError: Boolean(e.isError),
      };
    }
    case 'tool_execution_update': {
      const e = event as Extract<PiStreamEvent, { type: 'tool_execution_update' }>;
      return { type: 'tool-progress', id: e.toolCallId ?? '', partial: extractToolText(e.partialResult) };
    }
    default:
      return null;
  }
}

/**
 * A local / self-hosted OpenAI-compatible provider (llama.cpp, vLLM, Ollama,
 * LM Studio, ...). When set, the adapter registers it via a models.json and
 * talks to it directly — no API key, no billing, no provider account. This is
 * the model-agnostic thesis in practice: the gate + adapter are identical; only
 * the backing model changes.
 */
export interface LocalProviderConfig {
  /** Provider id, e.g. 'local'. */
  providerId: string;
  /** OpenAI-compatible base URL, e.g. 'http://localhost:8080/v1'. */
  baseUrl: string;
  /** Model id as the server reports it (from GET /v1/models). */
  modelId: string;
  /** Dummy key for keyless local servers (ignored by the server). Default 'local'. */
  apiKey?: string;
  contextWindow?: number;
  maxTokens?: number;
}

export interface PiAdapterOptions {
  /** Working tree the agent operates on (gate's workspace root). Default: process.cwd(). */
  workspaceRoot?: string;
  /** Pi agent config dir. Default: getAgentDir() (~/.pi/agent). Pass a temp dir to isolate. */
  agentDir?: string;
  /** Provider id for key lookup + model selection (hosted path). Default: 'anthropic'. */
  provider?: string;
  /** Optional model id override (else first available model for the provider). */
  modelId?: string;
  /** Key resolver (hosted path). Default: env <PROVIDER>_API_KEY, then the OS keychain. */
  getApiKey?: () => string | undefined | Promise<string | undefined>;
  /** When set, use a local OpenAI-compatible backend instead of a hosted provider. */
  local?: LocalProviderConfig;
}

/**
 * The Pi EngineAdapter: embeds @earendil-works/pi-coding-agent in-process and
 * routes every tool call through the host gate via Pi's `tool_call` hook —
 * registered by the HOST as an extension factory, with no model-facing removal
 * path. This is the make-or-break gate spike (Phase 108, T3).
 */
export class PiAdapter implements EngineAdapter {
  readonly id = 'pi';
  private gate: ToolCallGate | null = null;
  private readonly workspaceRoot: string;
  private readonly agentDir: string;
  private readonly provider: string;
  private readonly modelId?: string;
  private readonly getApiKey?: PiAdapterOptions['getApiKey'];
  private readonly local?: LocalProviderConfig;

  constructor(opts: PiAdapterOptions = {}) {
    this.workspaceRoot = resolve(opts.workspaceRoot ?? process.cwd());
    this.agentDir = opts.agentDir ?? getAgentDir();
    this.provider = opts.provider ?? 'anthropic';
    this.modelId = opts.modelId;
    this.getApiKey = opts.getApiKey;
    this.local = opts.local;
  }

  setToolCallGate(gate: ToolCallGate): void {
    this.gate = gate;
  }

  private async resolveApiKey(): Promise<string | undefined> {
    if (this.getApiKey) return this.getApiKey();
    const envKey = process.env[`${this.provider.toUpperCase()}_API_KEY`];
    return envKey ?? getSecret('nana-harness', this.provider);
  }

  /** models.json describing the local OpenAI-compatible provider (Pi's documented local-model path). */
  private buildLocalModelsJson(local: LocalProviderConfig): unknown {
    return {
      providers: {
        [local.providerId]: {
          baseUrl: local.baseUrl,
          api: 'openai-completions',
          apiKey: local.apiKey ?? 'local',
          compat: { supportsDeveloperRole: false, supportsReasoningEffort: false },
          models: [
            {
              id: local.modelId,
              name: local.modelId,
              reasoning: false,
              input: ['text'],
              contextWindow: local.contextWindow ?? 131072,
              maxTokens: local.maxTokens ?? 2048,
              cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            },
          ],
        },
      },
    };
  }

  async *sendPrompt(prompt: string, options: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
    // Fail-closed: if the host never registered a gate, build the default
    // deny-destructive gate rather than run ungated.
    const gate = this.gate ?? createHostGate({ workspaceRoot: this.workspaceRoot });
    const queue = new EventQueue();

    mkdirSync(this.agentDir, { recursive: true });
    const authStorage = AuthStorage.create(join(this.agentDir, 'auth.json'));
    let modelRegistry: ModelRegistry;
    if (this.local) {
      // Local OpenAI-compatible backend: describe it in a models.json and point
      // the registry at it. No key, no billing.
      const modelsJsonPath = join(this.agentDir, 'models.json');
      writeFileSync(modelsJsonPath, JSON.stringify(this.buildLocalModelsJson(this.local), null, 2));
      modelRegistry = ModelRegistry.create(authStorage, modelsJsonPath);
    } else {
      const apiKey = await this.resolveApiKey();
      if (apiKey) authStorage.setRuntimeApiKey(this.provider, apiKey);
      modelRegistry = ModelRegistry.create(authStorage);
    }

    // The host gate, wired as a Pi extension hook. The host registers this; the
    // model has no channel to deregister it. On deny we also surface a
    // tool-denied event to the UI stream.
    const loader = new DefaultResourceLoader({
      cwd: this.workspaceRoot,
      agentDir: this.agentDir,
      extensionFactories: [
        (pi: ExtensionAPI) => {
          pi.on('tool_call', async (event) => {
            const piEvent = event as unknown as PiToolCallEvent;
            const result = await applyHostGate(piEvent, gate);
            if (result?.block) {
              queue.push({
                type: 'tool-denied',
                id: piEvent.toolCallId,
                reason: result.reason ?? 'denied by host gate',
              });
            }
            return result;
          });
        },
      ],
    });
    await loader.reload();

    let model: ReturnType<ModelRegistry['find']>;
    if (this.local) {
      model = modelRegistry.find(this.local.providerId, this.local.modelId);
    } else {
      const available = await modelRegistry.getAvailable();
      model = this.modelId
        ? modelRegistry.find(this.provider, this.modelId)
        : (available.find((m) => m.provider === this.provider) ?? available[0]);
    }

    const { session } = await createAgentSession({
      model,
      authStorage,
      modelRegistry,
      cwd: this.workspaceRoot,
      agentDir: this.agentDir,
      sessionManager: SessionManager.inMemory(this.workspaceRoot),
      resourceLoader: loader,
    });

    const unsubscribe = session.subscribe((raw: unknown) => {
      const mapped = mapPiStreamEvent(raw as PiStreamEvent);
      if (mapped) queue.push(mapped);
    });

    if (options.signal) {
      const onAbort = () => void session.abort();
      if (options.signal.aborted) onAbort();
      else options.signal.addEventListener('abort', onAbort, { once: true });
    }

    // Project context (A2): Pi's session.prompt has no separate system-prompt
    // seam here, so prepend the assembled context as a marked preamble. undefined
    // => the prompt is unchanged (existing live tests pass no systemContext).
    const turnPrompt = options.systemContext
      ? `<project-context>\n${options.systemContext}\n</project-context>\n\n${prompt}`
      : prompt;

    void session
      .prompt(turnPrompt)
      .then(() => queue.close())
      .catch((err: unknown) => {
        queue.push({ type: 'error', error: err instanceof Error ? err.message : String(err) });
        queue.close();
      });

    try {
      for await (const ev of queue.stream()) yield ev;
    } finally {
      unsubscribe();
      session.dispose();
    }
    yield { type: 'done' };
  }
}
