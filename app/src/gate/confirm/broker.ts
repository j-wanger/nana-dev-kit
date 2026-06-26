import type { NormalizedToolCall } from '../../engine/types';

// Host-owned confirmation broker (Phase 109, T6/T3). The base host-gate
// auto-DENIES confirmable destructive actions (Ph108); the confirmingGate turns
// such a denial into a HOLD — an unresolved Promise<GateDecision> the adapters
// already await — by parking the call here. The transport (engine-host) surfaces
// the pending call to the UI and posts the human's verdict, which resolves the
// promise. host-gate / checkpoint / engine CORE stay unchanged; this is additive
// host wiring injected via the existing setToolCallGate seam.

export interface PendingConfirmation {
  callId: string;
  toolName: string;
  args: Record<string, unknown>;
  /** A computed preview (file diff or the command) for axis-1 "preview before it lands". */
  diff: string;
  /** The base gate's reason (human summary of why confirmation is required). */
  summary: string;
  /** The target file path for a write/edit hold (so an approved edit is revertible — axis 2). */
  path?: string;
}

export type ConfirmationListener = (pending: PendingConfirmation) => void;

export class ConfirmationBroker {
  private readonly pending = new Map<
    string,
    { resolve: (approved: boolean) => void; info: PendingConfirmation }
  >();
  private listener?: ConfirmationListener;

  /** The transport subscribes here; fired when a new confirmation is requested. */
  onPending(listener: ConfirmationListener): void {
    this.listener = listener;
  }

  /** Park a call pending a human verdict. Resolves when {@link resolve} is called. */
  request(info: PendingConfirmation): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      this.pending.set(info.callId, { resolve, info });
      this.listener?.(info);
    });
  }

  /** Deliver the human verdict; resolves the parked promise. No-op if unknown. */
  resolve(callId: string, approved: boolean): void {
    const entry = this.pending.get(callId);
    if (!entry) return;
    this.pending.delete(callId);
    entry.resolve(approved);
  }

  /**
   * Resolve every outstanding hold as DENIED. Called when a turn is cancelled /
   * interrupted, so a held gate await never leaks past the turn.
   */
  rejectAll(): void {
    for (const entry of this.pending.values()) entry.resolve(false);
    this.pending.clear();
  }

  hasPending(): boolean {
    return this.pending.size > 0;
  }

  pendingInfo(callId: string): PendingConfirmation | undefined {
    return this.pending.get(callId)?.info;
  }
}

export type { NormalizedToolCall };
