import { useCallback, useEffect, useState } from 'react';
import { Thread } from './ui/Thread';
import { useChatRuntime } from './ui/chat-runtime';
import { useGatePending, GateConfirmView } from './ui/gate-confirm';
import { RevertControl, ArtifactPanel } from './ui/artifacts';
import { BridgeClient, createBridgeClient } from './ui/engine-bridge';
import { buildCommands, type CommandContext } from './ui/commands';
import { CommandPalette } from './ui/command-palette';
import { useCommandShortcuts } from './ui/use-command-shortcuts';
import { WorkspaceIndicator } from './ui/workspace-indicator';
import { useWorkspace } from './ui/use-workspace';

// The composed harness surface (Phase 109, T5). Wires the webview BridgeClient
// (T6) to the chat (axis 4), the gate-confirm approve-loop (axis 1), a one-action
// revert strip (axis 2), and (Phase 113, T5 / axis 3) the Cmd+K command palette +
// keyboard shortcut layer — every action reachable by button, shortcut, or palette
// search. Degrades gracefully when no engine host is connected (e.g. `vite dev` in
// a plain browser) so the window still renders.

type ConnState = 'connecting' | 'connected' | 'offline';

export function App() {
  const [bridge, setBridge] = useState<BridgeClient | null>(null);
  const [conn, setConn] = useState<ConnState>('connecting');
  const workspace = useWorkspace(bridge);

  useEffect(() => {
    let cancelled = false;
    createBridgeClient()
      .then((b) => {
        if (cancelled) {
          b.stop();
          return;
        }
        setBridge(b);
        setConn('connected');
      })
      .catch(() => {
        if (!cancelled) setConn('offline');
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="app">
      <header className="app__header">
        <span className="app__brand">nana</span>
        <span className="app__tagline">dev-harness</span>
        <WorkspaceIndicator info={workspace} />
        <span className={`app__status app__status--${conn}`} data-conn={conn}>
          {conn === 'connected' ? 'engine connected' : conn === 'offline' ? 'engine offline' : 'connecting…'}
        </span>
      </header>
      {bridge ? <HarnessSurface bridge={bridge} /> : <Disconnected conn={conn} />}
    </div>
  );
}

export function HarnessSurface({ bridge }: { bridge: BridgeClient }) {
  const { runtime, artifacts, isRunning, stop, newConversation } = useChatRuntime(bridge);
  const { current, approve, deny } = useGatePending(bridge);
  const [reverts, setReverts] = useState<string[]>([]);
  const [paletteOpen, setPaletteOpen] = useState(false);

  const onApprove = useCallback(() => {
    const p = current?.path;
    if (p && (current.toolName === 'write' || current.toolName === 'edit')) {
      setReverts((prev) => (prev.includes(p) ? prev : [...prev, p]));
    }
    approve();
  }, [current, approve]);

  // The command registry (axis 3) bound to live state. Every command re-dispatches
  // an EXISTING action — no new privileged path (the no-bypass invariant). The
  // shell composes the cross-cutting resets (revert list, composer focus) here.
  const ctx: CommandContext = {
    gateHeld: current != null,
    isRunning,
    revertiblePaths: reverts,
    stop,
    approveGate: onApprove,
    denyGate: deny,
    revertLast: () => {
      const last = reverts[reverts.length - 1];
      if (last) void bridge.revert(last);
    },
    newConversation: () => {
      newConversation();
      setReverts([]);
    },
    focusComposer: () => document.querySelector<HTMLElement>('.composer__input')?.focus(),
    // The native folder picker + sidecar re-spawn run Rust/host-side; the bridge
    // tears down the dead session and reconnects on the fresh `ready` (T4). A new
    // workspace means a fresh gate, so the local revert list no longer applies.
    changeWorkspace: () => {
      bridge.changeWorkspace().then(
        (root) => {
          if (root) setReverts([]);
        },
        // A dialog/respawn failure leaves the prior session intact; surface it
        // rather than letting it become a silent unhandled rejection (Ph114 review, F4).
        (e: unknown) => console.warn('workspace change failed', e),
      );
    },
  };
  const commands = buildCommands(ctx);
  useCommandShortcuts({ commands, onOpenPalette: () => setPaletteOpen(true), paletteOpen });

  return (
    <div className={isRunning ? 'surface surface--running' : 'surface'}>
      <main className="surface__chat">
        <Thread runtime={runtime} />
      </main>
      <aside className="surface__side">
        <section className="panel">
          <h2 className="panel__title">Artifacts</h2>
          <ArtifactPanel artifacts={artifacts} />
        </section>
        <section className="panel">
          <h2 className="panel__title">Recent edits</h2>
          {reverts.length === 0 ? (
            <p className="panel__empty">Approved file edits appear here — each is one-action revertible.</p>
          ) : (
            <ul className="revert-list">
              {reverts.map((path) => (
                <li key={path} className="revert-list__item">
                  <RevertControl path={path} revert={(p) => bridge.revert(p)} />
                </li>
              ))}
            </ul>
          )}
        </section>
      </aside>
      {current ? (
        <div className="gate-overlay" role="presentation">
          <GateConfirmView pending={current} onApprove={onApprove} onDeny={deny} />
        </div>
      ) : null}
      <CommandPalette commands={commands} open={paletteOpen} onClose={() => setPaletteOpen(false)} />
    </div>
  );
}

function Disconnected({ conn }: { conn: ConnState }) {
  return (
    <div className="disconnected">
      <p className="disconnected__msg">
        {conn === 'offline'
          ? 'No engine host connected. Launch the desktop app with `npm run app` to drive the harness.'
          : 'Connecting to the engine host…'}
      </p>
    </div>
  );
}
