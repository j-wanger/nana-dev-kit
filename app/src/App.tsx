import { useCallback, useEffect, useState } from 'react';
import { Thread } from './ui/Thread';
import { useChatRuntime } from './ui/chat-runtime';
import { useGatePending, GateConfirmView } from './ui/gate-confirm';
import { RevertControl } from './ui/artifacts';
import { BridgeClient, createBridgeClient } from './ui/engine-bridge';

// The composed harness surface (Phase 109, T5). Wires the webview BridgeClient
// (T6) to the chat (axis 4), the gate-confirm approve-loop (axis 1), and a
// one-action revert strip (axis 2). Degrades gracefully when no engine host is
// connected (e.g. `vite dev` in a plain browser) so the window still renders.

type ConnState = 'connecting' | 'connected' | 'offline';

export function App() {
  const [bridge, setBridge] = useState<BridgeClient | null>(null);
  const [conn, setConn] = useState<ConnState>('connecting');

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
        <span className={`app__status app__status--${conn}`} data-conn={conn}>
          {conn === 'connected' ? 'engine connected' : conn === 'offline' ? 'engine offline' : 'connecting…'}
        </span>
      </header>
      {bridge ? <HarnessSurface bridge={bridge} /> : <Disconnected conn={conn} />}
    </div>
  );
}

function HarnessSurface({ bridge }: { bridge: BridgeClient }) {
  const runtime = useChatRuntime(bridge);
  const { current, approve, deny } = useGatePending(bridge);
  const [reverts, setReverts] = useState<string[]>([]);

  const onApprove = useCallback(() => {
    const p = current?.path;
    if (p && (current.toolName === 'write' || current.toolName === 'edit')) {
      setReverts((prev) => (prev.includes(p) ? prev : [...prev, p]));
    }
    approve();
  }, [current, approve]);

  return (
    <div className="surface">
      <main className="surface__chat">
        <Thread runtime={runtime} />
      </main>
      <aside className="surface__side">
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
