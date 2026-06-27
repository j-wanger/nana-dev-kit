import { useCallback, useMemo, useRef, useState } from 'react';
import {
  useExternalStoreRuntime,
  type ExternalStoreAdapter,
  type AppendMessage,
  type AssistantRuntime,
} from '@assistant-ui/react';
import type { EngineAdapter } from '../engine/adapter';
import { emptySurfaceMessage } from './runtime';
import { type UiMessage, surfaceToThreadMessage, commitEvent, appendMessageText } from './chat-binding';
import { toArtifacts, type Artifact } from './artifact-feed';

/**
 * Bind an EngineAdapter to an assistant-ui runtime (Phase 109, T1). The surface
 * is an external store of UiMessages; each prompt pumps the adapter's
 * AsyncIterable<EngineEvent> through commitEvent (clone-correct) so text streams
 * incrementally and tool calls transition called -> done / denied. No engine
 * type is reshaped — the whole binding lives in the UI layer.
 */
export function useChatRuntime(engine: EngineAdapter): {
  runtime: AssistantRuntime;
  artifacts: Artifact[];
} {
  const [messages, setMessages] = useState<UiMessage[]>([]);
  const [running, setRunning] = useState(false);
  const abortRef = useRef<AbortController | null>(null);

  const onNew = useCallback(
    async (message: AppendMessage) => {
      const text = appendMessageText(message);
      if (!text || running) return;
      const ac = new AbortController();
      abortRef.current = ac;
      setMessages((prev) => [...prev, { role: 'user', text }, emptySurfaceMessage()]);
      setRunning(true);
      try {
        for await (const ev of engine.sendPrompt(text, { signal: ac.signal })) {
          setMessages((prev) => commitEvent(prev, ev));
          if (ev.type === 'done' || ev.type === 'error') break;
        }
      } finally {
        setRunning(false);
        abortRef.current = null;
      }
    },
    [engine, running],
  );

  const onCancel = useCallback(async () => {
    abortRef.current?.abort();
  }, []);

  const adapter: ExternalStoreAdapter<UiMessage> = {
    messages,
    isRunning: running,
    isSendDisabled: running,
    convertMessage: surfaceToThreadMessage,
    onNew,
    onCancel,
  };

  const runtime = useExternalStoreRuntime(adapter);

  // The live artifact feed (Ph110 T6): every completed tool call across the
  // conversation, routed to its typed view. Derived from the same message store
  // that drives the chat — one source of truth, no second subscription.
  const artifacts = useMemo(
    () => toArtifacts(messages.flatMap((m) => (m.role === 'assistant' ? m.toolCalls : []))),
    [messages],
  );

  return { runtime, artifacts };
}
