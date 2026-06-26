import { useCallback, useEffect, useState, type ReactElement } from 'react';
import type { GatePending } from './engine-bridge';
import { DiffView } from './diff-view';

// Gate-hold confirm UI (Phase 109, T3 / axis 1 — preview & approve BEFORE it
// lands). The host's confirming-gate holds a destructive call and the bridge
// surfaces it here; the human approves/denies and the verdict travels back over
// the bridge. All content (tool name, reason, diff) renders inert.

/** The bridge surface this UI needs (a subset of BridgeClient), injected for tests. */
export interface GatePendingSource {
  onGatePending(listener: (p: GatePending) => void): () => void;
  respondGate(callId: string, approved: boolean): Promise<void> | void;
}

/** Subscribe to held calls and expose the current one + the verdict actions. */
export function useGatePending(bridge: GatePendingSource): {
  current: GatePending | null;
  pendingCount: number;
  approve: () => void;
  deny: () => void;
} {
  const [queue, setQueue] = useState<GatePending[]>([]);

  useEffect(() => bridge.onGatePending((p) => setQueue((q) => [...q, p])), [bridge]);

  const current = queue[0] ?? null;
  const respond = useCallback(
    (approved: boolean) => {
      if (!current) return;
      void bridge.respondGate(current.callId, approved);
      setQueue((q) => q.slice(1));
    },
    [bridge, current],
  );

  return {
    current,
    pendingCount: queue.length,
    approve: () => respond(true),
    deny: () => respond(false),
  };
}

export interface GateConfirmViewProps {
  pending: GatePending;
  onApprove: () => void;
  onDeny: () => void;
}

/** The blocking confirm card for one held call. Presentational + inert. */
export function GateConfirmView({ pending, onApprove, onDeny }: GateConfirmViewProps): ReactElement {
  return (
    <div className="gate-confirm" role="alertdialog" aria-label="Confirm a guarded action">
      <header className="gate-confirm__header">
        <span className="gate-confirm__badge">gate hold</span>
        <span className="gate-confirm__tool">{pending.toolName}</span>
      </header>
      <p className="gate-confirm__summary">{pending.summary}</p>
      <DiffView diff={pending.diff} />
      <div className="gate-confirm__actions">
        <button type="button" className="gate-confirm__deny" onClick={onDeny}>
          Deny
        </button>
        <button type="button" className="gate-confirm__approve" onClick={onApprove}>
          Approve &amp; run
        </button>
      </div>
    </div>
  );
}

/** Renders the current held call (or nothing) wired to the bridge. */
export function GateConfirm({ bridge }: { bridge: GatePendingSource }): ReactElement | null {
  const { current, approve, deny } = useGatePending(bridge);
  if (!current) return null;
  return <GateConfirmView pending={current} onApprove={approve} onDeny={deny} />;
}
