// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import { createElement } from 'react';
import { ArtifactPanel } from '../../src/ui/artifacts';
import type { Artifact } from '../../src/ui/artifact-feed';

// Ph110 T6: the live artifact panel renders the typed views (DiffView /
// TerminalOutput, already owned from Ph109) over the now-real tool results.
// Mechanics + the inert rail only — felt quality is the maintainer's call.

describe('ArtifactPanel (Ph110 T6)', () => {
  it('renders a diff artifact via DiffView and a terminal artifact via TerminalOutput', () => {
    const artifacts: Artifact[] = [
      { kind: 'diff', id: 'a', name: 'edit', diff: '--- a\n+++ b\n-old\n+new' },
      { kind: 'terminal', id: 'b', name: 'bash', text: 'total 0\nfile.txt' },
    ];
    const html = renderToStaticMarkup(createElement(ArtifactPanel, { artifacts }));
    expect(html).toContain('data-testid="diff"');
    expect(html).toContain('data-testid="terminal"');
    expect(html).toContain('file.txt');
    expect(html).toContain('edit'); // the tool name header
  });

  it('renders an empty state when there are no artifacts', () => {
    const html = renderToStaticMarkup(createElement(ArtifactPanel, { artifacts: [] }));
    expect(html).toContain('panel__empty');
  });

  it('renders untrusted terminal text as escaped, inert content (no live script)', () => {
    const artifacts: Artifact[] = [
      { kind: 'terminal', id: 'a', name: 'bash', text: '<script>alert(1)</script>' },
    ];
    const html = renderToStaticMarkup(createElement(ArtifactPanel, { artifacts }));
    expect(html).not.toContain('<script>alert');
    expect(html).toContain('&lt;script&gt;');
  });
});
