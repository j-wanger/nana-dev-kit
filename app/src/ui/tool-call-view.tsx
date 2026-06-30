import type { ReactElement } from 'react';

export interface ToolCallViewProps {
  toolName: string;
  argsText?: string;
  result?: unknown;
  isError?: boolean;
  status?: { type: string };
}

/**
 * Render one tool call as INERT text (Phase 109, T1). Every dynamic value —
 * name, args, result, denial reason — is a React string child, which React
 * escapes, so prompt-injected markup in untrusted tool output renders literally
 * and cannot execute. NEVER inject raw HTML here (no React raw-HTML escape
 * hatch): this is the XSS rail (mirrors src/ui/inert.ts), defended further by
 * the strict webview CSP. The chat-stream test asserts no UI file uses the
 * raw-HTML escape hatch at all.
 *
 * A host-gate denial arrives as isError=true with the reason as `result`; it
 * renders as a distinct "blocked by gate" affordance — the security UX must be
 * visible, not a silent drop.
 */
export function ToolCallView(props: ToolCallViewProps): ReactElement {
  const denied = props.isError === true;
  const status = denied ? 'denied' : props.status?.type === 'complete' ? 'done' : 'called';
  return (
    <div className={`tool-call tool-call--${status}`} data-status={status}>
      <span className="tool-call__name">{props.toolName}</span>
      {/* In-flight cue: a tool executing on a slow local model is the longest
          wait and used to look frozen. Static markup (inert); the spin animates
          only while the turn is running (.surface--running) so a dangling
          'called' call after done/abort shows a static dot, never spins forever. */}
      {status === 'called' ? <span className="tool-call__spinner" aria-hidden="true" /> : null}
      {props.argsText ? <code className="tool-call__args">{props.argsText}</code> : null}
      {props.result != null ? (
        <span className="tool-call__result">
          {denied ? `blocked by gate: ${String(props.result)}` : String(props.result)}
        </span>
      ) : null}
    </div>
  );
}
