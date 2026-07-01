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
import type { EngineEvent, ModelInfo, SkillInfo, TemplateInfo, ThinkingInfo, ToolCallGate } from '../types';
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
 * Per-turn output-token ceiling for the LOCAL model ONLY. Pi's local path defaults
 * to 2048 (LocalProviderConfig), which truncates real responses; raise it (env-
 * overridable). Never 0/negative.
 *
 * Ph119 T9 — HOSTED-PATH maxTokens VERIFICATION (verdict: NOT A BUG, no fix). The
 * research finding flagged "hosted path maxTokens UNSET = truncation bug." Verified
 * by source inspection: nana overrides maxTokens ONLY on the local path (this
 * function feeds buildLocalModelsJson). The HOSTED path uses the model straight
 * from Pi's ModelRegistry, and Pi's generated registry carries each model's REAL
 * max-output (anthropic.models.js: 8192 older Claude, 64000 / 128000 Claude 4.x
 * extended output, 4096 legacy; other providers 131072 / 262144 / …). So "unset by
 * nana" means "uses the model's real limit" — correct, not truncated. Overriding it
 * would be the actual bug: a uniform cap would clamp a 128000-max model down to
 * 8192. Hence NO hosted-path override, and NO regression test (there is no
 * truncation to pin). The local override exists only because nana authors that
 * models.json and its default is low.
 */
export function resolveMaxTokens(opt?: number): number {
  if (opt != null && Number.isFinite(opt) && opt > 0) return Math.floor(opt);
  const env = Number(process.env.NANA_MAX_TOKENS);
  return Number.isFinite(env) && env > 0 ? Math.floor(env) : 8192;
}

/** The launch-time local-endpoint capability check result (Ph119 T4). */
export interface LocalEndpointProbe {
  /** The OpenAI-compatible server answered GET /models. */
  ok: boolean;
  /** The model ids the server reports (for a "weak default?" nudge). */
  models: string[];
  /** A human reason when !ok (unreachable / non-200), for the header warning. */
  detail?: string;
}

/**
 * Ph119 T4 — probe the local OpenAI-compatible endpoint at launch so the surface
 * can warn when the default local model is DOWN (the #1 "why is nothing happening"
 * failure on the local $0 default). "Weak" is a judgment call (the local default is
 * deliberately modest) — we surface the model list so the maintainer can see what
 * is loaded, but only DOWN is a hard warning. Never throws; a fetch failure is a
 * clean `{ ok: false }`. `fetchImpl` is injectable for tests.
 */
export async function probeLocalEndpoint(
  baseUrl: string,
  opts: { timeoutMs?: number; fetchImpl?: typeof fetch } = {},
): Promise<LocalEndpointProbe> {
  const doFetch = opts.fetchImpl ?? fetch;
  try {
    const res = await doFetch(`${baseUrl.replace(/\/$/, '')}/models`, {
      signal: AbortSignal.timeout(opts.timeoutMs ?? 2000),
    });
    if (!res.ok) return { ok: false, models: [], detail: `local model endpoint returned HTTP ${res.status}` };
    const body = (await res.json()) as { data?: Array<{ id?: unknown }> };
    const models = Array.isArray(body?.data)
      ? body.data.map((m) => (typeof m?.id === 'string' ? m.id : '')).filter(Boolean)
      : [];
    return { ok: true, models };
  } catch (err) {
    return {
      ok: false,
      models: [],
      detail: `local model endpoint unreachable (${err instanceof Error ? err.message : String(err)})`,
    };
  }
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
  /**
   * Phase 119 T1 seam: build the ONE persistent session. Default embeds Pi
   * (buildDefaultSession). Tests inject a fake to drive the build-once / reuse /
   * dispose-and-rebuild lifecycle without a live model. Advanced/internal — the
   * real app never sets this.
   */
  sessionBuilder?: PiSessionBuilder;
}

/**
 * The minimal persistent-session surface the adapter drives across turns (Phase
 * 119 T1). Pi's `AgentSession` structurally satisfies it; a fake satisfies it in
 * the lifecycle unit tests. Only the methods the adapter actually calls are
 * declared, so no broad Pi type crosses this seam.
 */
export interface PiSessionHandle {
  /** Run one turn. Resolves when the turn completes, rejects on a session error. */
  prompt(text: string): Promise<void>;
  /** Interrupt the in-flight turn and return to idle; the session stays usable. */
  abort(): Promise<void>;
  /** Tear down the session (Pi clears its extension host + the gate hook here). */
  dispose(): void;
  /** Fold auto-compaction into the persistent session (the correctness dependency). */
  setAutoCompactionEnabled(enabled: boolean): void;
  /** Ph119 T2: the current context%/cost snapshot for the meter, or undefined if
   *  unavailable. Engine-neutral (no Pi type crosses the seam). */
  meterSnapshot(): MeterSnapshot | undefined;
  /** Ph119 T2: manually compact the session context. A session mutation — the gate
   *  survives it (A1 verdict); shipped with a gate-survives-after-compact check. */
  compact(): Promise<void>;
  /** Ph119 T4: the models available to switch to (local + any hosted with auth). */
  listModels(): ModelInfo[];
  /** Ph119 T4: the active model, or undefined before the session is built. */
  currentModel(): ModelInfo | undefined;
  /** Ph119 T4: switch to a specific model (a session mutation — the gate survives).
   *  Returns false if the id is unknown (no change). */
  setModel(providerId: string, modelId: string): Promise<boolean>;
  /** Ph119 T4: cycle to the next available model (a session mutation). Returns the
   *  new model, or undefined when only one model is available (no-op). */
  cycleModel(): Promise<ModelInfo | undefined>;
  /** Ph119 T5: the active thinking level + the ones this model offers. */
  thinkingInfo(): ThinkingInfo;
  /** Ph119 T5: set the thinking level (synchronous in Pi; the gate survives). */
  setThinkingLevel(level: string): void;
  /** Ph119 T5: cycle to the next thinking level (delegates to the setter). Returns
   *  the new level, or undefined when the model does not support thinking. */
  cycleThinkingLevel(): string | undefined;
  /** Ph119 T7: the loaded prompt templates (surfaced as palette commands). */
  listPromptTemplates(): TemplateInfo[];
  /** Ph119 T7: the loaded skills (surfaced as palette commands). */
  listSkills(): SkillInfo[];
}

/** Engine-neutral context/cost snapshot for the meter (Ph119 T2). Mirrors the
 *  `context-usage` event fields minus `type`. `percent`/`tokens` are null in the
 *  post-compaction window; `costUsd` is $0 on the local model. */
export interface MeterSnapshot {
  percent: number | null;
  tokens: number | null;
  contextWindow: number;
  costUsd: number;
}

/**
 * What the adapter hands a session builder (Phase 119 T1). The gate is resolved
 * at CALL time (`getGate`, never captured), and denials + mapped stream events
 * flow through `onDenied`/`onEvent` — which push to whatever the CURRENT turn's
 * sink is. That call-time indirection is the C1 decouple: a denial on turn N
 * reaches turn N's stream even though the gate hook was wired once at build.
 */
export interface PiSessionBuildArgs {
  workspaceRoot: string;
  /** Resolve the live host gate at call time — mirrors Pi's own call-time `_extensionRunner` read. */
  getGate: () => ToolCallGate;
  /** Route a host-gate denial to the current turn's stream. */
  onDenied: (id: string, reason: string) => void;
  /** Route a mapped engine event (from Pi's subscribe) to the current turn's stream. */
  onEvent: (event: EngineEvent) => void;
}

/** Builds ONE persistent Pi session with the host-gate `tool_call` hook wired. */
export type PiSessionBuilder = (args: PiSessionBuildArgs) => Promise<PiSessionHandle>;

/**
 * Ph119 T2: Pi's `session.compact()` THROWS on the two benign "nothing to do"
 * conditions — the session is too small to compact, or it was already compacted
 * (agent-session.js:1291-1293, plain `Error` with a message string; no typed
 * error). A MANUAL /compact on a small session must be a graceful no-op, not a
 * surfaced crash — so we classify those messages and swallow ONLY them. Any other
 * compaction failure (summarizer/network) still propagates. Exported so the
 * classification is unit-tested without a live model (the live C3 test caught the
 * raw throw; this keeps the fix pinned).
 */
export function isBenignCompactError(err: unknown): boolean {
  const msg = err instanceof Error ? err.message : String(err);
  return /nothing to compact|already compacted/i.test(msg);
}

/**
 * Ph119 T6 (A4) — the DefaultResourceLoader options with nana's context policy.
 * `noContextFiles: true` turns OFF Pi's NATIVE context-file load (AGENTS.md etc.),
 * so nana's assembly.ts is the SOLE injector of project context (via the
 * <project-context> preamble). Without this, AGENTS.md reaches the model TWICE
 * (Pi native + nana). Extracted + exported so the policy is host-testable — a
 * regression that re-enables the native load (double injection) trips the test.
 * NOTE: this only disables native CONTEXT FILES; extensions (the gate),
 * skills, and prompt-templates still load.
 */
export function piLoaderOptions(
  cwd: string,
  agentDir: string,
  extensionFactories: Array<(pi: ExtensionAPI) => void>,
): { cwd: string; agentDir: string; extensionFactories: Array<(pi: ExtensionAPI) => void>; noContextFiles: true } {
  return { cwd, agentDir, extensionFactories, noContextFiles: true };
}

/** Project a Pi model (read structurally — no Pi type crosses) to ModelInfo (T4). */
function modelInfoOf(
  m: { id: string; name?: string; provider: string },
  active: { id: string; provider: string } | undefined,
  localProviderId: string | undefined,
): ModelInfo {
  return {
    providerId: m.provider,
    modelId: m.id,
    label: m.name ?? m.id,
    isLocal: localProviderId != null && m.provider === localProviderId,
    active: active != null && active.provider === m.provider && active.id === m.id,
  };
}

/**
 * The Pi EngineAdapter: embeds @earendil-works/pi-coding-agent in-process and
 * routes every tool call through the host gate via Pi's `tool_call` hook —
 * registered by the HOST as an extension factory, with no model-facing removal
 * path. This is the make-or-break gate spike (Phase 108, T3).
 *
 * Phase 119 T1: the session is now PERSISTENT — built once and reused across
 * turns (felt-quality items need a session that lives across turns). The host
 * gate SURVIVES that persistence and every session mutation: Pi installs
 * `beforeToolCall` once in the AgentSession ctor and reads `this._extensionRunner`
 * at call time, and only `_buildRuntime` (ctor + reload()) ever reassigns it —
 * none of setModel/cycleModel/compact/setThinkingLevel/setAutoCompactionEnabled
 * do (A1 verification checkpoint, verdict SURVIVES; see the Phase-119 checkpoint
 * report). new-conversation = dispose + rebuild (the gate re-attaches via a fresh
 * loader factory run); workspace change stays a sidecar respawn that rebinds the
 * gate to the new root.
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

  // Phase 119 T1 — the persistent session + its per-turn sink.
  /** The ONE persistent session; built lazily on the first turn, reused after. */
  private session: PiSessionHandle | null = null;
  /** The CURRENT turn's event sink. Swapped each turn; read at call time by the
   *  gate-denial hook and the subscribe callback (the C1 decouple). null between turns. */
  private currentTurn: EventQueue | null = null;
  /** In-flight build guard so two racing turns share one session, not two. */
  private buildPromise: Promise<PiSessionHandle> | null = null;
  /** Memoized fail-closed gate (only used if the host never wired one). */
  private failClosed: ToolCallGate | null = null;
  private readonly builder: PiSessionBuilder;

  constructor(opts: PiAdapterOptions = {}) {
    this.workspaceRoot = resolve(opts.workspaceRoot ?? process.cwd());
    this.agentDir = opts.agentDir ?? getAgentDir();
    this.provider = opts.provider ?? 'anthropic';
    this.modelId = opts.modelId;
    this.getApiKey = opts.getApiKey;
    this.local = opts.local;
    this.sandboxMode = resolveSandboxMode(opts.sandboxMode);
    this.toolNames = opts.tools ?? PI_TOOL_ALLOWLIST;
    this.builder = opts.sessionBuilder ?? ((args) => this.buildDefaultSession(args));
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

  /** Resolve the live host gate at CALL time (fail-closed if the host never wired
   *  one). Read inside the tool_call hook so a gate set after build still governs. */
  private resolveGate(): ToolCallGate {
    return this.gate ?? (this.failClosed ??= createHostGate({ workspaceRoot: this.workspaceRoot }));
  }

  /** Build (once) or return the persistent session. A concurrent caller shares the
   *  same in-flight build. Auto-compaction is folded in here — a persistent
   *  `inMemory` session would otherwise grow unbounded and exhaust context. */
  private async ensureSession(): Promise<PiSessionHandle> {
    if (this.session) return this.session;
    if (this.buildPromise) return this.buildPromise;
    this.buildPromise = this.builder({
      workspaceRoot: this.workspaceRoot,
      getGate: () => this.resolveGate(),
      // C1: both sinks read `this.currentTurn` at call time, so a denial / event
      // reaches whatever turn is live now — not the turn that was live at build.
      onDenied: (id, reason) => this.currentTurn?.push({ type: 'tool-denied', id, reason }),
      onEvent: (event) => this.currentTurn?.push(event),
    });
    try {
      const session = await this.buildPromise;
      session.setAutoCompactionEnabled(true);
      this.session = session;
      return session;
    } finally {
      this.buildPromise = null;
    }
  }

  /** The default builder: embed Pi and wire the host-gate `tool_call` hook + the
   *  subscribe stream, both routing through the adapter-provided call-time sinks. */
  private async buildDefaultSession(args: PiSessionBuildArgs): Promise<PiSessionHandle> {
    const { workspaceRoot, getGate, onDenied, onEvent } = args;
    mkdirSync(this.agentDir, { recursive: true });
    const authStorage = AuthStorage.create(join(this.agentDir, 'auth.json'));
    let modelRegistry: ModelRegistry;
    if (this.local) {
      // Local OpenAI-compatible backend: describe it in a models.json and point
      // the registry at it. No key, no billing. ModelRegistry.create MERGES the
      // custom local model into the built-in provider list, so hosted models are
      // ALSO present — but only "available" (switchable) when auth is configured.
      const modelsJsonPath = join(this.agentDir, 'models.json');
      writeFileSync(modelsJsonPath, JSON.stringify(this.buildLocalModelsJson(this.local), null, 2));
      modelRegistry = ModelRegistry.create(authStorage, modelsJsonPath);
      // Ph119 T4 — local↔hosted keeping the LOCAL DEFAULT: best-effort, ENV-ONLY
      // hosted auth so hosted models become switchable in the picker when a key is
      // present. Env-only (no keychain prompt) keeps local startup fast + silent;
      // the active model still starts on local below.
      const hostedKey = process.env[`${this.provider.toUpperCase()}_API_KEY`];
      if (hostedKey) authStorage.setRuntimeApiKey(this.provider, hostedKey);
    } else {
      const apiKey = await this.resolveApiKey();
      if (apiKey) authStorage.setRuntimeApiKey(this.provider, apiKey);
      modelRegistry = ModelRegistry.create(authStorage);
    }

    // The host gate, wired as a Pi extension hook. The host registers this; the
    // model has no channel to deregister it, and Pi keeps the hook attached across
    // every session mutation (A1 verdict). On deny we surface a tool-denied event
    // to the CURRENT turn's stream (C1 — the sink is resolved at call time).
    const gateFactory = (pi: ExtensionAPI) => {
      pi.on('tool_call', async (event) => {
        const piEvent = event as unknown as PiToolCallEvent;
        const result = await applyHostGate(piEvent, getGate());
        if (result?.block) {
          onDenied(piEvent.toolCallId, result.reason ?? 'denied by host gate');
        }
        return result;
      });
    };
    // Ph119 T6: noContextFiles:true — nana's assembly.ts is the SOLE context
    // injector (AGENTS.md reaches the model exactly once, not Pi-native + nana).
    const loader = new DefaultResourceLoader(
      piLoaderOptions(workspaceRoot, this.agentDir, [gateFactory]),
    );
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
      cwd: workspaceRoot,
      agentDir: this.agentDir,
      sessionManager: SessionManager.inMemory(workspaceRoot),
      resourceLoader: loader,
      // Phase 114: activate the full builtin tool set (grep/find/ls were dormant)
      // so the model gets paginated read + ripgrep/fd/ls + surgical edit. `bash`
      // here is OS-sandbox-overridden by customTools below (the custom definition
      // wins by name — Ph112), so listing it does NOT re-expose unsandboxed bash.
      tools: [...this.toolNames],
      // Phase 112: OS-sandbox bash by overriding the builtin with a seatbelt-
      // wrapped 'bash' tool (empty off-darwin → builtin bash + string-gate only).
      customTools: piSandboxCustomTools(workspaceRoot, this.sandboxMode),
    });

    const unsubscribe = session.subscribe((raw: unknown) => {
      const mapped = mapPiStreamEvent(raw as PiStreamEvent);
      if (mapped) onEvent(mapped);
    });

    // Return the neutral handle. dispose() releases OUR subscription too (Pi's
    // dispose clears its own extension host + listeners; the unsubscribe handle
    // is ours to release).
    return {
      prompt: (text) => session.prompt(text),
      abort: () => session.abort(),
      setAutoCompactionEnabled: (enabled) => session.setAutoCompactionEnabled(enabled),
      // Ph119 T2: project Pi's ContextUsage + SessionStats.cost to the engine-
      // neutral snapshot. getContextUsage() is undefined before the first response;
      // normalize to a zero-usage reading so the meter still shows the window + cost.
      meterSnapshot: () => {
        const usage = session.getContextUsage();
        const cost = session.getSessionStats().cost;
        return {
          percent: usage?.percent ?? null,
          tokens: usage?.tokens ?? null,
          contextWindow: usage?.contextWindow ?? 0,
          costUsd: typeof cost === 'number' ? cost : 0,
        };
      },
      // Ph119 T2: manual compaction. The gate hook survives it (A1 verdict) — Pi
      // does not rebuild the extension host on compact; only the low-level agent
      // event subscription is bounced, not `beforeToolCall` or our subscribe. A
      // too-small / already-compacted session is a benign no-op (Pi throws for it),
      // not a failure to surface; every other error propagates.
      compact: async () => {
        try {
          await session.compact();
        } catch (err) {
          if (!isBenignCompactError(err)) throw err;
        }
      },
      // Ph119 T4 — model switcher. `active` is recomputed per call from the live
      // session.model (a getter), so a chip stays correct after setModel/cycleModel.
      // The gate hook survives these mutations (A1 verdict); C3 test ships with it.
      listModels: () => {
        const active = session.model;
        return modelRegistry.getAvailable().map((m) => modelInfoOf(m, active, this.local?.providerId));
      },
      currentModel: () =>
        session.model ? modelInfoOf(session.model, session.model, this.local?.providerId) : undefined,
      setModel: async (providerId, modelId) => {
        const m = modelRegistry.find(providerId, modelId);
        if (!m) return false;
        await session.setModel(m);
        return true;
      },
      cycleModel: async () => {
        const result = await session.cycleModel();
        return result ? modelInfoOf(result.model, result.model, this.local?.providerId) : undefined;
      },
      // Ph119 T5 — thinking-level toggle. session.thinkingLevel is a getter; the
      // levels/supported come from the active model. setThinkingLevel is SYNCHRONOUS
      // (a plain field set + event) and cycleThinkingLevel DELEGATES to it, so the
      // gate hook is never touched (self-verified against the SDK; no T1 dependency).
      thinkingInfo: () => ({
        level: session.thinkingLevel,
        levels: session.getAvailableThinkingLevels(),
        supported: session.supportsThinking(),
      }),
      setThinkingLevel: (level) => {
        (session.setThinkingLevel as (l: string) => void)(level);
      },
      cycleThinkingLevel: () => session.cycleThinkingLevel(),
      // Ph119 T7: project Pi's prompt templates + loaded skills to the engine-
      // neutral shapes (no Pi type crosses). A template surfaces as a palette
      // command whose run SUBMITS `content` through the gated prompt path.
      listPromptTemplates: () =>
        session.promptTemplates.map((t) => ({
          name: t.name,
          description: t.description ?? '',
          content: t.content,
          ...(t.argumentHint ? { argumentHint: t.argumentHint } : {}),
        })),
      listSkills: () =>
        session.resourceLoader.getSkills().skills.map((s) => ({
          name: s.name,
          description: s.description ?? '',
        })),
      dispose: () => {
        unsubscribe();
        session.dispose();
      },
    };
  }

  async *sendPrompt(prompt: string, options: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
    const session = await this.ensureSession();
    // Swap in this turn's sink. The persistent gate hook + subscribe callback both
    // read `this.currentTurn`, so from here their output flows to THIS turn (C1).
    const turn = new EventQueue();
    this.currentTurn = turn;

    const signal = options.signal;
    let onAbort: (() => void) | undefined;
    if (signal) {
      onAbort = () => void session.abort();
      if (signal.aborted) onAbort();
      else signal.addEventListener('abort', onAbort, { once: true });
    }

    // Project context (A2): Pi's session.prompt has no separate system-prompt
    // seam here, so prepend the assembled context as a marked preamble. undefined
    // => the prompt is unchanged (existing live tests pass no systemContext).
    const turnPrompt = options.systemContext
      ? `<project-context>\n${options.systemContext}\n</project-context>\n\n${prompt}`
      : prompt;

    void session
      .prompt(turnPrompt)
      .then(() => {
        // Ph119 T2: emit the updated context/cost meter at turn end (Pi's usage is
        // current once the response lands), just before the turn closes.
        const snap = session.meterSnapshot();
        if (snap) {
          turn.push({
            type: 'context-usage',
            percent: snap.percent,
            tokens: snap.tokens,
            contextWindow: snap.contextWindow,
            costUsd: snap.costUsd,
          });
        }
        turn.close();
      })
      .catch((err: unknown) => {
        turn.push({ type: 'error', error: err instanceof Error ? err.message : String(err) });
        turn.close();
      });

    try {
      for await (const ev of turn.stream()) yield ev;
    } finally {
      if (signal && onAbort) signal.removeEventListener('abort', onAbort);
      // The session PERSISTS across turns — only detach this turn's sink so a
      // late/stray event from a settled turn is dropped, never misrouted.
      if (this.currentTurn === turn) this.currentTurn = null;
    }
    yield { type: 'done' };
  }

  /**
   * Crash-isolation recovery + explicit reset. Disposes the persistent session
   * (tearing down Pi's extension host, incl. the gate hook) and rebuilds a fresh
   * one — the rebuild re-runs the loader's extensionFactory, so the host gate is
   * RE-ATTACHED. Engine cross-turn memory is intra-run only; this is the
   * documented recovery from a mid-turn session error. Call it between turns.
   */
  async newConversation(): Promise<void> {
    this.disposeSession();
    await this.ensureSession();
  }

  /**
   * Ph119 T2: manually compact the persistent session's context. A session
   * MUTATION — the gate hook survives it (A1 verdict; Pi installs beforeToolCall
   * once and never rebuilds the extension host on compact). The C3 discipline: a
   * gate-survives-after-compact check ships with this surface (unit + live).
   */
  async compact(): Promise<void> {
    const session = await this.ensureSession();
    await session.compact();
  }

  /** Ph119 T4: the models available to switch to (local + hosted-with-auth). */
  async listModels(): Promise<ModelInfo[]> {
    const session = await this.ensureSession();
    return session.listModels();
  }

  /** Ph119 T4: the active model. */
  async currentModel(): Promise<ModelInfo | undefined> {
    const session = await this.ensureSession();
    return session.currentModel();
  }

  /**
   * Ph119 T4: switch to a specific model (a session MUTATION — the gate survives
   * it, A1 verdict; C3 gate-survives-after-setModel test ships with this surface).
   * Returns false if the id is unknown.
   */
  async setModel(providerId: string, modelId: string): Promise<boolean> {
    const session = await this.ensureSession();
    return session.setModel(providerId, modelId);
  }

  /** Ph119 T4: cycle to the next available model (a session mutation). */
  async cycleModel(): Promise<ModelInfo | undefined> {
    const session = await this.ensureSession();
    return session.cycleModel();
  }

  /** Ph119 T5: the active thinking level + the ones the model offers. */
  async thinkingInfo(): Promise<ThinkingInfo> {
    const session = await this.ensureSession();
    return session.thinkingInfo();
  }

  /** Ph119 T5: set the thinking level (synchronous; the gate survives). */
  async setThinkingLevel(level: string): Promise<void> {
    const session = await this.ensureSession();
    session.setThinkingLevel(level);
  }

  /** Ph119 T5: cycle to the next thinking level (delegates to the setter). */
  async cycleThinkingLevel(): Promise<string | undefined> {
    const session = await this.ensureSession();
    return session.cycleThinkingLevel();
  }

  /** Ph119 T7: the loaded prompt templates (palette slash-commands). */
  async listPromptTemplates(): Promise<TemplateInfo[]> {
    const session = await this.ensureSession();
    return session.listPromptTemplates();
  }

  /** Ph119 T7: the loaded skills (palette slash-commands). */
  async listSkills(): Promise<SkillInfo[]> {
    const session = await this.ensureSession();
    return session.listSkills();
  }

  /** Tear down the persistent session (idempotent). Used by newConversation and
   *  by a clean sidecar shutdown. */
  dispose(): void {
    this.disposeSession();
  }

  private disposeSession(): void {
    const s = this.session;
    this.session = null;
    this.currentTurn = null;
    s?.dispose();
  }
}
