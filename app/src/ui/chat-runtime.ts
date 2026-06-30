import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
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
import { loadConversation, saveConversation, clearConversation } from './conversation-store';
import type { WorkspaceInfo } from './engine-bridge';

/**
 * The workspace source the runtime persists against (Phase 115) — structurally
 * the BridgeClient (its `currentWorkspace` getter + `onWorkspace`). OPTIONAL: when
 * it is absent (bare adapters, the offline path, unit tests) persistence is
 * DISABLED and the runtime behaves exactly as before — conversation stays
 * in-memory only. Importing the bridge's type only (erased) keeps the seam clean.
 */
export interface WorkspaceSource {
  readonly currentWorkspace: WorkspaceInfo | null;
  onWorkspace(listener: (w: WorkspaceInfo) => void): () => void;
}

/**
 * Bind an EngineAdapter to an assistant-ui runtime (Phase 109, T1). The surface
 * is an external store of UiMessages; each prompt pumps the adapter's
 * AsyncIterable<EngineEvent> through commitEvent (clone-correct) so text streams
 * incrementally and tool calls transition called -> done / denied. No engine
 * type is reshaped — the whole binding lives in the UI layer.
 *
 * Phase 115 — conversation memory: when a `workspace` source is supplied, the
 * conversation is persisted to localStorage PER workspace root (redacted at the
 * boundary by conversation-store): restored on the first ready, swapped on a
 * workspace change (no stale cross-workspace leak), cleared on newConversation.
 * Restore/swap is DISPLAY-ONLY — it sets the message store directly and never
 * calls the engine or the gate (the no-bypass invariant).
 */
export function useChatRuntime(
  engine: EngineAdapter,
  workspace?: WorkspaceSource,
): {
  runtime: AssistantRuntime;
  artifacts: Artifact[];
  /** A turn is streaming (a tool/model run is in flight) — drives the `stop` command's enablement. */
  isRunning: boolean;
  /** Hard-interrupt the in-flight turn (axis 3 — same path as the composer Stop). */
  stop: () => void;
  /**
   * Start a fresh conversation: abort any in-flight turn, clear the message store
   * (which the artifact feed derives from), AND drop the persisted thread for the
   * active workspace. Still adds NO new bridge message and needs NO host reset —
   * clearConversation is local storage, not an engine send (the no-bypass
   * invariant, T5). The shell composes any additional surface reset at the call site.
   */
  newConversation: () => void;
} {
  const [messages, setMessages] = useState<UiMessage[]>([]);
  const [running, setRunning] = useState(false);
  const abortRef = useRef<AbortController | null>(null);
  // The active persistence key — the workspace root, or null before the first
  // ready / when no workspace source is supplied (persistence then no-ops).
  const keyRef = useRef<string | null>(null);

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
    const key = keyRef.current;
    if (key) clearConversation(key);
  }, []);

  // Refs so the workspace subscription (bound once) reads LIVE values without
  // re-subscribing: the latest messages (to persist the OUTGOING thread on a
  // swap) and whether a turn is in flight (to DEFER a mid-turn change).
  const messagesRef = useRef(messages);
  const runningRef = useRef(running);
  useEffect(() => {
    messagesRef.current = messages;
    runningRef.current = running;
  }, [messages, running]);

  // A pending workspace change requested mid-turn (applied on settle).
  const pendingWsRef = useRef<string | null>(null);

  // Apply a workspace switch (Ph115, T4): persist the OUTGOING thread, then load
  // the incoming — purely display-side (no engine send). Same-root is a no-op so
  // a re-ready can't clobber the live thread.
  const swapWorkspace = useCallback((incoming: string) => {
    const prev = keyRef.current;
    if (incoming === prev) return;
    if (prev) saveConversation(prev, messagesRef.current);
    keyRef.current = incoming;
    setMessages(loadConversation(incoming));
  }, []);

  // Persist on settle (Ph115): when a turn finishes (running true -> false), save
  // the thread under the active workspace key — keyed off the running transition
  // so the final streamed message is committed before we read it. No-op when the
  // key is null. Then flush any workspace change that was deferred during the turn.
  const wasRunning = useRef(false);
  useEffect(() => {
    if (wasRunning.current && !running) {
      const key = keyRef.current;
      if (key) saveConversation(key, messages);
      const pending = pendingWsRef.current;
      if (pending) {
        pendingWsRef.current = null;
        swapWorkspace(pending);
      }
    }
    wasRunning.current = running;
  }, [running, messages, swapWorkspace]);

  // Restore / swap on workspace (Ph115). onWorkspace fires immediately with the
  // current value if a ready already arrived, then on every subsequent ready
  // (incl. the re-spawn after a workspace change). A change arriving mid-turn is
  // DEFERRED — the in-flight thread must not be clobbered — and applied on settle.
  useEffect(() => {
    if (!workspace) return;
    const apply = (w: WorkspaceInfo) => {
      if (!w.root) return; // ignore a bogus empty root — keep key state consistent
      if (w.root === keyRef.current) return; // same-root re-ready: no-op
      if (runningRef.current) {
        pendingWsRef.current = w.root; // defer until the turn settles
        return;
      }
      swapWorkspace(w.root);
    };
    return workspace.onWorkspace(apply);
  }, [workspace, swapWorkspace]);

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
