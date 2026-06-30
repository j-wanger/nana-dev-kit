import { resolve } from 'node:path';
import { writeFileSync } from 'node:fs';
import { streamText, tool, stepCountIs, jsonSchema } from 'ai';
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';
import type { EngineAdapter, SendPromptOptions } from '../adapter';
import type { EngineEvent, ToolCallGate } from '../types';
import { createHostGate } from '../../gate/host-gate';
import { resolveSandboxMode, runSandboxedBash, type SandboxMode } from '../../gate/sandbox/seatbelt';
import { consumeApprovedWrites } from '../../gate/sandbox/approved-writes';
import { EventQueue } from '../event-queue';
import { createGatedToolExecute } from './gated-tools';

// The SECOND engine adapter (Phase 108, T7) — the Vercel AI SDK over an
// OpenAI-compatible backend. It exists to prove the host gate is engine-neutral:
// the SAME createHostGate ToolCallGate that Pi routes through its tool_call hook
// is reused here, wrapped around each tool's execute. One gate, two engines.

export interface VercelAdapterOptions {
  workspaceRoot?: string;
  /** OpenAI-compatible base URL, e.g. http://localhost:8080/v1 */
  baseUrl: string;
  modelId: string;
  /** Dummy key for keyless local servers. Default 'local'. */
  apiKey?: string;
  providerName?: string;
  /** Sandbox profile for bash (Phase 112). Default: NANA_SANDBOX_MODE or 'strict'. */
  sandboxMode?: SandboxMode;
  /** Max agent-loop steps per turn. Default: NANA_MAX_STEPS or 64. */
  maxSteps?: number;
}

/**
 * The per-turn agent-loop ceiling. Was a hard-coded 4 (Ph108) — far too low: a
 * real task halts mid-work after ~3 tool rounds. Default 64, env-overridable.
 * Never 0/negative (stepCountIs(0) would halt immediately).
 */
export function resolveMaxSteps(opt?: number): number {
  if (opt != null && Number.isFinite(opt) && opt > 0) return Math.floor(opt);
  const env = Number(process.env.NANA_MAX_STEPS);
  return Number.isFinite(env) && env > 0 ? Math.floor(env) : 64;
}

export class VercelAdapter implements EngineAdapter {
  readonly id = 'vercel';
  private gate: ToolCallGate | null = null;
  private readonly workspaceRoot: string;
  private readonly baseUrl: string;
  private readonly modelId: string;
  private readonly apiKey: string;
  private readonly providerName: string;
  private readonly sandboxMode: SandboxMode;
  private readonly maxSteps: number;

  constructor(opts: VercelAdapterOptions) {
    this.workspaceRoot = resolve(opts.workspaceRoot ?? process.cwd());
    this.baseUrl = opts.baseUrl;
    this.modelId = opts.modelId;
    this.apiKey = opts.apiKey ?? 'local';
    this.providerName = opts.providerName ?? 'local';
    this.sandboxMode = resolveSandboxMode(opts.sandboxMode);
    this.maxSteps = resolveMaxSteps(opts.maxSteps);
  }

  setToolCallGate(gate: ToolCallGate): void {
    this.gate = gate;
  }

  private currentGate(): ToolCallGate {
    return this.gate ?? createHostGate({ workspaceRoot: this.workspaceRoot });
  }

  // Real tool side effects — reached ONLY when the gate allows. Phase 112: bash
  // runs through the seatbelt chokepoint (argv form, no quoting hole) so a
  // gate-allowed command is STILL OS-confined to the workspace on darwin (the
  // string-gate's evasion residual closed); off-darwin it executes unwrapped
  // (string-gate is the only boundary — documented residual). Non-zero exit
  // surfaces as a thrown tool error (the model sees stderr), as execSync did.
  private runBash(args: Record<string, unknown>): string {
    const command = String(args.command ?? '');
    const r = runSandboxedBash(command, {
      cwd: this.workspaceRoot,
      workspaceRoot: this.workspaceRoot,
      mode: this.sandboxMode,
      // Phase 112 T4: fold any human-approved out-of-workspace target for this
      // command into the per-command profile (consume-once).
      extraWrites: consumeApprovedWrites(command),
      timeout: 10_000,
    });
    if (r.status !== 0) throw new Error(r.stderr || r.stdout || `command exited with status ${r.status}`);
    return r.stdout;
  }

  private runWrite(args: Record<string, unknown>): string {
    const path = String(args.path ?? '');
    writeFileSync(resolve(this.workspaceRoot, path), String(args.content ?? ''));
    return `wrote ${path}`;
  }

  /** The gate-wrapped AI SDK tool set. Exposed so the gate integration is unit-testable. */
  buildGatedTools(queue?: EventQueue) {
    const getGate = () => this.currentGate();
    const onDenied = (id: string, reason: string) => queue?.push({ type: 'tool-denied', id, reason });
    return {
      bash: tool({
        description: 'Run a shell command in the workspace.',
        inputSchema: jsonSchema<{ command: string }>({
          type: 'object',
          properties: { command: { type: 'string' } },
          required: ['command'],
        }),
        execute: createGatedToolExecute('bash', getGate, (a) => this.runBash(a), onDenied),
      }),
      write: tool({
        description: 'Write text to a file path in the workspace.',
        inputSchema: jsonSchema<{ path: string; content: string }>({
          type: 'object',
          properties: { path: { type: 'string' }, content: { type: 'string' } },
          required: ['path', 'content'],
        }),
        execute: createGatedToolExecute('write', getGate, (a) => this.runWrite(a), onDenied),
      }),
    };
  }

  async *sendPrompt(prompt: string, options: SendPromptOptions = {}): AsyncIterable<EngineEvent> {
    const queue = new EventQueue();
    const provider = createOpenAICompatible({
      name: this.providerName,
      baseURL: this.baseUrl,
      apiKey: this.apiKey,
    });
    const model = provider.chatModel(this.modelId);
    const tools = this.buildGatedTools(queue);

    const result = streamText({
      model,
      prompt,
      // Project context (A2) as the native system prompt; undefined => omitted.
      system: options.systemContext,
      tools,
      stopWhen: stepCountIs(this.maxSteps),
      abortSignal: options.signal,
    });

    void (async () => {
      try {
        for await (const part of result.fullStream as AsyncIterable<Record<string, unknown>>) {
          switch (part.type) {
            case 'text-delta':
              queue.push({ type: 'text-delta', delta: String(part.text ?? part.delta ?? '') });
              break;
            case 'tool-call':
              queue.push({
                type: 'tool-call',
                call: {
                  id: String(part.toolCallId ?? ''),
                  name: String(part.toolName ?? ''),
                  args: (part.input ?? {}) as Record<string, unknown>,
                },
              });
              break;
            case 'tool-result':
              queue.push({ type: 'tool-result', id: String(part.toolCallId ?? ''), result: part.output });
              break;
            case 'finish':
              // Make a cut-off VISIBLE — a silent "done" mid-task is exactly the
              // dogfood bug this raise is fixing. Distinguish the two causes:
              // 'tool-calls' = hit the agent-loop step ceiling; 'length' = hit the
              // model's output-token limit (a different fix knob).
              if (part.finishReason === 'tool-calls') {
                queue.push({
                  type: 'text-delta',
                  delta: `\n\n⚠ Stopped at the ${this.maxSteps}-step limit — the task may be unfinished.`,
                });
              } else if (part.finishReason === 'length') {
                queue.push({
                  type: 'text-delta',
                  delta: `\n\n⚠ Output hit the model's token limit — the response may be unfinished.`,
                });
              }
              break;
            case 'abort':
              // User-initiated stop: a clean end, NOT an error (so the new
              // error-surfacing never renders a deliberate Stop as a failure).
              queue.close();
              return;
            case 'error':
              queue.push({ type: 'error', error: String(part.error) });
              break;
            default:
              break;
          }
        }
        queue.close();
      } catch (e) {
        // An aborted turn throws here — that's a user Stop, not a failure.
        if (options.signal?.aborted) {
          queue.close();
          return;
        }
        queue.push({ type: 'error', error: e instanceof Error ? e.message : String(e) });
        queue.close();
      }
    })();

    for await (const ev of queue.stream()) yield ev;
    yield { type: 'done' };
  }
}
