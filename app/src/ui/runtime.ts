import type { EngineEvent } from '../engine/types';

// The adapter -> surface binding (Phase 108, T6). The assistant-ui custom
// runtime renders ONE engine-neutral message model, fed by any EngineAdapter's
// event stream. Keeping this reduction engine-neutral is what lets the surface
// render Pi, Vercel-AI-SDK, or Claude identically (the felt quality of the
// surface itself is the maintainer's call — UI carve-out — but the mechanics
// are pinned here).

export interface SurfaceToolCall {
  id: string;
  name: string;
  status: 'called' | 'done' | 'denied';
  reason?: string;
}

export interface SurfaceMessage {
  role: 'assistant';
  text: string;
  toolCalls: SurfaceToolCall[];
  done: boolean;
  error?: string;
}

export function emptySurfaceMessage(): SurfaceMessage {
  return { role: 'assistant', text: '', toolCalls: [], done: false };
}

/** Fold one engine event into the running surface message (mutates + returns it). */
export function applyEngineEvent(msg: SurfaceMessage, ev: EngineEvent): SurfaceMessage {
  switch (ev.type) {
    case 'text-delta':
      msg.text += ev.delta;
      break;
    case 'tool-call':
      msg.toolCalls.push({ id: ev.call.id, name: ev.call.name, status: 'called' });
      break;
    case 'tool-result': {
      const t = msg.toolCalls.find((c) => c.id === ev.id);
      if (t) t.status = 'done';
      break;
    }
    case 'tool-denied': {
      const t = msg.toolCalls.find((c) => c.id === ev.id);
      if (t) {
        t.status = 'denied';
        t.reason = ev.reason;
      } else {
        msg.toolCalls.push({ id: ev.id, name: '(denied)', status: 'denied', reason: ev.reason });
      }
      break;
    }
    case 'error':
      msg.error = ev.error;
      break;
    case 'done':
      msg.done = true;
      break;
  }
  return msg;
}

/** Reduce a whole event stream to a final surface message (for tests / replay). */
export function reduceEngineEvents(events: Iterable<EngineEvent>): SurfaceMessage {
  const msg = emptySurfaceMessage();
  for (const ev of events) applyEngineEvent(msg, ev);
  return msg;
}
