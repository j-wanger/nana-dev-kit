// @vitest-environment jsdom
import { describe, it, expect, vi } from 'vitest';
import { act, createElement, type ReactElement } from 'react';
import { createRoot } from 'react-dom/client';
import { renderToStaticMarkup } from 'react-dom/server';
import { TestResults, TerminalOutput, RevertControl } from '../../src/ui/artifacts';

// T4 (axes 5 + 2 — instant artifact preview + one-action rewind). Mechanics only.

async function mount(el: ReactElement): Promise<HTMLElement> {
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  await act(async () => {
    root.render(el);
  });
  return container;
}
async function click(el: Element | null): Promise<void> {
  await act(async () => {
    el?.dispatchEvent(new MouseEvent('click', { bubbles: true }));
  });
}

describe('TestResults (T4 / axis 5)', () => {
  it('summarises pass/fail and renders a row per test with status', () => {
    const html = renderToStaticMarkup(
      createElement(TestResults, {
        results: [
          { name: 'gate denies rm', status: 'pass' },
          { name: 'revert to bytes', status: 'fail', message: 'expected X got Y' },
        ],
      }),
    );
    expect(html).toContain('1 passed, 1 failed');
    expect(html).toContain('test-results__row--pass');
    expect(html).toContain('test-results__row--fail');
    expect(html).toContain('expected X got Y');
  });

  it('renders a fail message inert (no live markup)', () => {
    const html = renderToStaticMarkup(
      createElement(TestResults, {
        results: [{ name: 't', status: 'fail', message: '<img src=x onerror=alert(1)>' }],
      }),
    );
    expect(html).not.toContain('<img');
    expect(html).toContain('&lt;img');
  });
});

describe('TerminalOutput (T4 / axis 5)', () => {
  it('renders command output inert', () => {
    const html = renderToStaticMarkup(createElement(TerminalOutput, { text: '<script>alert(1)</script>\n$ ok' }));
    expect(html).not.toContain('<script>');
    expect(html).toContain('&lt;script&gt;');
    expect(html).toContain('$ ok');
  });
});

describe('RevertControl (T4 / axis 2)', () => {
  it('invokes revert(path) on click and reflects the done state', async () => {
    const revert = vi.fn(async () => ({ ok: true }));
    const c = await mount(createElement(RevertControl, { path: '/ws/a.ts', revert }));
    const btn = c.querySelector('.revert') as HTMLButtonElement;
    expect(btn.getAttribute('data-state')).toBe('idle');
    await click(btn);
    expect(revert).toHaveBeenCalledWith('/ws/a.ts');
    expect(btn.getAttribute('data-state')).toBe('done');
  });

  it('shows an error state when the host reports a failed revert', async () => {
    const revert = vi.fn(async () => ({ ok: false, error: 'no checkpoint' }));
    const c = await mount(createElement(RevertControl, { path: '/ws/b.ts', revert }));
    const btn = c.querySelector('.revert') as HTMLButtonElement;
    await click(btn);
    expect(btn.getAttribute('data-state')).toBe('error');
  });
});
