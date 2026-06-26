import type { ReactElement } from 'react';

/**
 * Render a unified-diff string as INERT, line-classed rows (Phase 109, T3/T4).
 * Each line is a React string child (escaped — the XSS rail; never raw HTML),
 * classed so the UI can colorize +/- (semantic color: green add / red remove).
 * Shared by the gate-confirm preview (axis 1) and the artifact view (axis 5).
 */
export function DiffView({ diff }: { diff: string }): ReactElement {
  const lines = diff.length ? diff.split('\n') : [];
  return (
    <pre className="diff" data-testid="diff">
      {lines.map((line, i) => (
        <div key={i} className={`diff__line ${diffLineClass(line)}`}>
          {line === '' ? ' ' : line}
        </div>
      ))}
    </pre>
  );
}

function diffLineClass(line: string): string {
  if (line.startsWith('---') || line.startsWith('+++')) return 'diff__meta';
  if (line.startsWith('+')) return 'diff__add';
  if (line.startsWith('-')) return 'diff__del';
  return 'diff__ctx';
}
