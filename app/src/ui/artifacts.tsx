import { useCallback, useState, type ReactElement } from 'react';
import { DiffView } from './diff-view';
import type { RevertResult } from './engine-bridge';
import type { Artifact } from './artifact-feed';

// Artifact preview + one-action revert (Phase 109, T4 / axes 5 + 2). Custom,
// owned components (NOT AI Elements — it covers 1/4 of these and forces a
// Tailwind/shadcn setup; "owned not adopted" per the spec). All dynamic content
// renders inert (React string children). The diff artifact uses DiffView
// (diff-view.tsx); test-runs and command output use the views below.

export interface TestResult {
  name: string;
  status: 'pass' | 'fail';
  message?: string;
}

/** A test run rendered with a pass/fail summary and per-test rows (semantic color via CSS). */
export function TestResults({ results }: { results: TestResult[] }): ReactElement {
  const passed = results.filter((r) => r.status === 'pass').length;
  const failed = results.length - passed;
  return (
    <div className="test-results" data-testid="test-results">
      <div className={`test-results__summary ${failed ? 'is-failing' : 'is-passing'}`}>
        {passed} passed{failed ? `, ${failed} failed` : ''}
      </div>
      <ul className="test-results__list">
        {results.map((r, i) => (
          <li key={i} className={`test-results__row test-results__row--${r.status}`} data-status={r.status}>
            <span className="test-results__dot" aria-hidden="true" />
            <span className="test-results__name">{r.name}</span>
            {r.message ? <span className="test-results__msg">{r.message}</span> : null}
          </li>
        ))}
      </ul>
    </div>
  );
}

/** Command / tool stdout rendered inert in a monospace block (whitespace preserved via CSS). */
export function TerminalOutput({ text }: { text: string }): ReactElement {
  return (
    <pre className="terminal" data-testid="terminal">
      {text}
    </pre>
  );
}

/**
 * The live artifact panel (Ph110 T6): each completed tool call's REAL output
 * rendered by its typed view — a unified diff via DiffView, everything else as
 * inert terminal text (the generic-text fallback, ledger A3). Owned components
 * over AI Elements (Ph109). The tool name heads each entry so the maintainer
 * sees WHICH call produced it. All dynamic content is a React string child
 * (escaped → inert); the artifact text is already redacted upstream (T5).
 */
export function ArtifactPanel({ artifacts }: { artifacts: Artifact[] }): ReactElement {
  if (artifacts.length === 0) {
    return (
      <p className="panel__empty">
        Tool outputs — diffs and command results — appear here as the agent works.
      </p>
    );
  }
  return (
    <ul className="artifact-list">
      {artifacts.map((a) => (
        <li key={a.id} className="artifact" data-kind={a.kind}>
          <span className="artifact__name">{a.name}</span>
          {a.kind === 'diff' ? <DiffView diff={a.diff} /> : <TerminalOutput text={a.text} />}
        </li>
      ))}
    </ul>
  );
}

export interface RevertControlProps {
  path: string;
  revert: (path: string) => Promise<RevertResult> | void;
}

/** One-action rewind (axis 2): revert a file to its pre-action bytes via the host. */
export function RevertControl({ path, revert }: RevertControlProps): ReactElement {
  const [state, setState] = useState<'idle' | 'reverting' | 'done' | 'error'>('idle');
  const onClick = useCallback(async () => {
    setState('reverting');
    try {
      const r = await revert(path);
      setState(r && r.ok === false ? 'error' : 'done');
    } catch {
      setState('error');
    }
  }, [path, revert]);
  return (
    <button
      type="button"
      className="revert"
      data-state={state}
      onClick={onClick}
      disabled={state === 'reverting'}
    >
      <span className="revert__label">
        {state === 'done' ? 'reverted' : state === 'error' ? 'revert failed' : 'Revert'}
      </span>
      <span className="revert__path">{path}</span>
    </button>
  );
}
