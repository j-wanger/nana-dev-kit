import { resolve, join } from 'node:path';
import { mkdirSync, writeFileSync } from 'node:fs';
import {
  AuthStorage,
  createAgentSession,
  createBashToolDefinition,
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
import {
  buildProfile,
  isSandboxAvailable,
  resolveSandboxMode,
  wrapBashCommandString,
  type SandboxMode,
} from '../../gate/sandbox/seatbelt';
import { consumeApprovedWrites } from '../../gate/sandbox/approved-writes';
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
 * Ph111: NORMALIZE Pi's typed `AgentToolResult.details` to a whitelisted,
 * engine-neutral `{ diff }` (A3) — for the edit tool that is `EditToolDetails`
 * ({ diff, patch, firstChangedLine }; pi edit.d.ts). We lift ONLY the
 * display-oriented `diff` string (what DiffView consumes), so no Pi type crosses
 * the boundary. The diff is untrusted model-adjacent content (it embeds file
 * bytes) → redact BEFORE cap, the same rail as the text result. Returns
 * undefined when there is no usable diff so the surface falls back cleanly.
 */
function extractToolDetails(result: unknown): { diff?: string } | undefined {
  if (result == null || typeof result !== 'object') return undefined;
  const details = (result as { details?: unknown }).details;
  if (details == null || typeof details !== 'object') return undefined;
  const diff = (details as { diff?: unknown }).diff;
  if (typeof diff !== 'string' || diff.length === 0) return undefined;
  return { diff: capOutput(redactSecrets(diff)) as string };
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
      const details = extractToolDetails(e.result);
      return {
        type: 'tool-result',
        id: e.toolCallId ?? '',
        result: extractToolText(e.result),
        isError: Boolean(e.isError),
        ...(details ? { details } : {}),
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

// Phase 112 T2 — OS-sandbox the Pi bash tool. Pi runs bash inside the SDK, but
// it lets us SUBSTITUTE a custom tool named 'bash' via createAgentSession's
// `customTools` (a custom 'bash' deterministically overrides the builtin —
// verified by probe). The wrap lives in the bash tool's `spawnHook`, which fires
// INSIDE the tool's execute() — strictly DOWNSTREAM of `pi.on('tool_call')` (the
// host gate) and `tool_execution_start` (the Ph110/111 visibility surface). So
// the gate + the UI feed see the ORIGINAL command; only the actual spawn is
// sandbox-wrapped. NOTE: `baseToolsOverride` is NOT the seam — it is on the
// low-level AgentSession ctor (not createAgentSession) and replaces the WHOLE
// base tool set.

// Structural shape of Pi's BashSpawnContext (bash.d.ts) — kept local so no Pi
// type is required at this seam. The hook is SYNCHRONOUS (a pure transform).
export type SandboxSpawnContext = { command: string; cwd: string; env: NodeJS.ProcessEnv };

/** The synchronous spawnHook: rewrite the command to run under a workspace-
 *  confined seatbelt profile. Returns a NEW context (never mutates the input), so
 *  it cannot retroactively change what the gate/visibility already observed. */
export function makeSandboxSpawnHook(
  workspaceRoot: string,
  mode: SandboxMode,
): (ctx: SandboxSpawnContext) => SandboxSpawnContext {
  return (ctx) => ({
    ...ctx,
    command: wrapBashCommandString(
      ctx.command,
      // Phase 112 T4: fold any human-APPROVED out-of-workspace target for THIS
      // command into the per-command profile (consume-once) — approve-then-succeed.
      buildProfile({ workspaceRoot, mode, extraWrites: consumeApprovedWrites(ctx.command) }),
    ),
  });
}

// The element type createAgentSession's `customTools` accepts (Pi erases the
// per-tool schema to TSchema/unknown/any). createBashToolDefinition returns a
// CONCRETELY-typed bash ToolDefinition; handing it back to Pi is sound at runtime
// (probe-verified) but TS rejects the assignment on renderCall's contravariant
// arg type — bridge with a single typed cast, no `any` leak past this seam.
type PiCustomTool = NonNullable<NonNullable<Parameters<typeof createAgentSession>[0]>['customTools']>[number];

/** The customTools entry that OS-sandboxes bash — empty off-darwin / when
 *  sandbox-exec is absent (the host-gate string layer remains the only boundary
 *  there; documented residual). */
export function piSandboxCustomTools(workspaceRoot: string, mode: SandboxMode): PiCustomTool[] {
  if (!isSandboxAvailable()) return [];
  const bash = createBashToolDefinition(workspaceRoot, {
    spawnHook: makeSandboxSpawnHook(workspaceRoot, mode),
  });
  return [bash as unknown as PiCustomTool];
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

// Phase 114: the active builtin tool set for the Pi session. The SDK registers all
// 7 but defaults to activating only read/bash/edit/write — leaving grep/find/ls
// DORMANT, so the model had to shell out to bash for search. Activating the full
// set gives it ripgrep/fd/ls with paginated, capped output. `bash` stays in the
// list but is OS-sandbox-overridden by piSandboxCustomTools (Ph112) — the custom
// definition wins by name, so this does NOT re-expose an unsandboxed bash.
export const PI_TOOL_ALLOWLIST = ['read', 'bash', 'edit', 'write', 'grep', 'find', 'ls'] as const;

/**
 * Per-turn output-token ceiling for the local model. Pi's local path defaults to
 * 2048 (LocalProviderConfig), which truncates real responses; raise it (env-
 * overridable). Never 0/negative.
 */
export function resolveMaxTokens(opt?: number): number {
  if (opt != null && Number.isFinite(opt) && opt > 0) return Math.floor(opt);
  const env = Number(process.env.NANA_MAX_TOKENS);
  return Number.isFinite(env) && env > 0 ? Math.floor(env) : 8192;
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
  /** Sandbox profile for bash (Phase 112). Default: NANA_SANDBOX_MODE or 'strict'. */
  sandboxMode?: SandboxMode;
  /** Active builtin tool allowlist. Default: PI_TOOL_ALLOWLIST (Phase 114). */
  tools?: readonly string[];
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
  private readonly sandboxMode: SandboxMode;
  private readonly toolNames: readonly string[];

  constructor(opts: PiAdapterOptions = {}) {
    this.workspaceRoot = resolve(opts.workspaceRoot ?? process.cwd());
    this.agentDir = opts.agentDir ?? getAgentDir();
    this.provider = opts.provider ?? 'anthropic';
    this.modelId = opts.modelId;
    this.getApiKey = opts.getApiKey;
    this.local = opts.local;
    this.sandboxMode = resolveSandboxMode(opts.sandboxMode);
    this.toolNames = opts.tools ?? PI_TOOL_ALLOWLIST;
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
      // Phase 114: activate the full builtin tool set (grep/find/ls were dormant)
      // so the model gets paginated read + ripgrep/fd/ls + surgical edit. `bash`
      // here is OS-sandbox-overridden by customTools below (the custom definition
      // wins by name — Ph112), so listing it does NOT re-expose unsandboxed bash.
      tools: [...this.toolNames],
      // Phase 112: OS-sandbox bash by overriding the builtin with a seatbelt-
      // wrapped 'bash' tool (empty off-darwin → builtin bash + string-gate only).
      customTools: piSandboxCustomTools(this.workspaceRoot, this.sandboxMode),
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
