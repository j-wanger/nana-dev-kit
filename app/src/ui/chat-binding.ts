import type { ThreadMessageLike, AppendMessage } from '@assistant-ui/react';
import type { EngineEvent } from '../engine/types';
import { type SurfaceMessage, type SurfaceToolCall, applyEngineEvent } from './runtime';
import { redactSecrets } from '../security/redact';

// Ph110 T3 (security-bearing): the real args + output threaded by T1/T2 now
// render inline, but they are UNTRUSTED tool content — so every field shown is
// routed through redactSecrets() (a pasted/echoed key never reaches the
// renderer) and truncated to keep the inline view compact. The values stay
// plain strings → assistant-ui renders them as escaped text (inert), the XSS
// rail the chat-stream + inert-render tests assert.

const INLINE_CAP = 2000;

function truncateInline(s: string): string {
  return s.length > INLINE_CAP ? `${s.slice(0, INLINE_CAP)}…[+${s.length - INLINE_CAP} chars]` : s;
}

/** Args shown inline: the bash command verbatim, else compact JSON; redacted. */
function toolArgsText(tc: SurfaceToolCall): string {
  const args = tc.args;
  if (!args || Object.keys(args).length === 0) return '';
  const command = (args as { command?: unknown }).command;
  const raw = typeof command === 'string' ? command : JSON.stringify(args);
  return truncateInline(redactSecrets(raw));
}

/**
 * Result shown inline: a gate-denial's reason (host-generated → no redaction;
 * rendered as the distinct "blocked by gate" affordance), else the real tool
 * output (untrusted → redacted + truncated), else undefined while still running.
 */
function toolResultText(tc: SurfaceToolCall): string | undefined {
  if (tc.status === 'denied') return tc.reason;
  // show output whenever present — including a streamed partial mid-run (T4),
  // not only on 'done' — so a long tool call is legible while it executes.
  if (tc.output == null) return undefined;
  const raw = typeof tc.output === 'string' ? tc.output : JSON.stringify(tc.output);
  return truncateInline(redactSecrets(raw));
}

// The assistant-ui custom-runtime binding (Phase 109, T1). This module is PURE
// (no assistant-ui *value* import — only erased type imports) so it loads in the
// node test env without dragging in browser-coupled code. It binds the existing
// engine-neutral reduction (runtime.ts) to assistant-ui via useExternalStoreRuntime
// WITHOUT reshaping any engine type (EngineEvent / NormalizedToolCall stay as-is).

/**
 * One message in the surface store. SurfaceMessage (role 'assistant') is the
 * model side, reused verbatim from runtime.ts; the user side is added HERE so
 * the engine-neutral reduction never has to know about user turns.
 */
export type UiMessage = { role: 'user'; text: string } | SurfaceMessage;

/**
 * `convertMessage` for useExternalStoreRuntime: project ONE UiMessage onto
 * assistant-ui's ThreadMessageLike. A pure projection — nothing engine-specific
 * leaks, and assistant-ui renders the parts (text escaped = inert by default).
 */
export function surfaceToThreadMessage(m: UiMessage): ThreadMessageLike {
  if (m.role === 'user') {
    return { role: 'user', content: [{ type: 'text', text: m.text }] };
  }
  const content: ThreadMessageLike['content'] = [
    { type: 'text', text: m.text },
    // assistant-ui has no native "denied" part; a host-gate denial maps to an
    // errored tool part carrying the reason. The ToolCallView special-cases
    // isError to render a "blocked by gate" affordance (the security UX).
    ...m.toolCalls.map((tc) => ({
      type: 'tool-call' as const,
      toolCallId: tc.id,
      toolName: tc.name || '(tool)',
      // the structured `args` part field is unread (our MessageView Override
      // renders argsText, not args) — keep it empty; the real command/JSON is in
      // argsText (redacted). Avoids coercing Record<unknown> → ReadonlyJSONObject.
      args: {},
      argsText: toolArgsText(tc),
      // isError flags the gate-denial affordance ONLY; an execution error shows
      // its output normally (the output text carries the error message).
      isError: tc.status === 'denied',
      result: toolResultText(tc),
    })),
  ];
  const status: ThreadMessageLike['status'] = m.error
    ? { type: 'incomplete', reason: 'error', error: m.error }
    : m.done
      ? { type: 'complete', reason: 'stop' }
      : { type: 'running' };
  return { role: 'assistant', content, status };
}

/**
 * Fold ONE engine event into the message list, returning a NEW array with a
 * CLONED streaming message. applyEngineEvent MUTATES in place, so handing it the
 * live React-state object would not change identity and the surface would not
 * re-render / stream. Cloning (new array + new message + new toolCalls array) is
 * the load-bearing detail that makes incremental streaming actually render.
 */
export function commitEvent(messages: UiMessage[], ev: EngineEvent): UiMessage[] {
  const last = messages[messages.length - 1];
  if (!last || last.role !== 'assistant') return messages;
  const clone: SurfaceMessage = { ...last, toolCalls: last.toolCalls.map((t) => ({ ...t })) };
  applyEngineEvent(clone, ev);
  return [...messages.slice(0, -1), clone];
}

/** Pull the user's text out of an assistant-ui AppendMessage (content is parts). */
export function appendMessageText(message: AppendMessage): string {
  const content = message.content as unknown;
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .filter((p): p is { type: 'text'; text: string } => !!p && p.type === 'text')
      .map((p) => p.text)
      .join('');
  }
  return '';
}
