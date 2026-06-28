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
  /** A turn is streaming (a tool/model run is in flight) — drives the `stop` command's enablement. */
  isRunning: boolean;
  /** Hard-interrupt the in-flight turn (axis 3 — same path as the composer Stop). */
  stop: () => void;
  /**
   * Start a fresh conversation: abort any in-flight turn and clear the message
   * store (which the artifact feed derives from). Conversation state is UI-side
   * only — both adapters are stateless across sendPrompt — so this needs NO host
   * reset and adds NO new bridge message (the no-bypass invariant, T5). The shell
   * composes any additional surface reset (e.g. the revert list) at the call site.
   */
  newConversation: () => void;
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

  const newConversation = useCallback(() => {
    abortRef.current?.abort();
    setMessages([]);
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

  return { runtime, artifacts, isRunning: running, stop: onCancel, newConversation };
}
