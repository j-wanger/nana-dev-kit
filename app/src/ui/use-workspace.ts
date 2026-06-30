import { useEffect, useState } from 'react';
import type { BridgeClient, WorkspaceInfo } from './engine-bridge';

// Subscribe the header to the bridge's active-workspace state (Phase 114, T5).
// onWorkspace fires immediately with the current value (if a ready already
// arrived) and on every subsequent ready — including the re-spawn after a
// workspace change (T4). Returns null until the first ready or when disconnected.
export function useWorkspace(bridge: BridgeClient | null): WorkspaceInfo | null {
  const [ws, setWs] = useState<WorkspaceInfo | null>(bridge?.currentWorkspace ?? null);
  useEffect(() => {
    if (!bridge) {
      setWs(null);
      return;
    }
    setWs(bridge.currentWorkspace);
    return bridge.onWorkspace(setWs);
  }, [bridge]);
  return ws;
}
