// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { renderInert, isStrictCsp } from '../../src/ui/inert';

const here = dirname(fileURLToPath(import.meta.url));

// Prompt-injected tool output renders inert and does not execute; the CSP is
// strict; and the capability manifest grants no broad fs/shell/http scope
// (Phase 108, T6). CSP/capabilities are also webview-runtime properties verified
// at the Tauri-launch step; here we assert the policy + the renderer mechanics.

describe('inert rendering of untrusted model/tool output', () => {
  it('renders prompt-injected output as inert text — no script/handler executes', () => {
    (globalThis as unknown as { __xss?: () => void }).__xss = () => {
      (globalThis as unknown as { __xssFired?: boolean }).__xssFired = true;
    };
    (globalThis as unknown as { __xssFired?: boolean }).__xssFired = false;

    const malicious =
      '<script>globalThis.__xss && globalThis.__xss()</script>' +
      '<img src=x onerror="globalThis.__xss && globalThis.__xss()">' +
      '<a href="javascript:globalThis.__xss()">click</a> hello-world';

    const el = document.createElement('div');
    renderInert(el, malicious);
    document.body.appendChild(el);

    expect((globalThis as unknown as { __xssFired?: boolean }).__xssFired).toBe(false);
    // No live DOM was created — content is pure text, not parsed markup.
    expect(el.childElementCount).toBe(0);
    expect(el.querySelector('script')).toBeNull();
    expect(el.querySelector('img')).toBeNull();
    // The payload is present, shown literally (escaped), so the user still sees it.
    expect(el.textContent).toContain('<script>');
    expect(el.textContent).toContain('hello-world');
  });

  it('the configured webview CSP is strict (no unsafe-inline/eval, locked script-src)', () => {
    const conf = JSON.parse(readFileSync(resolve(here, '../../src-tauri/tauri.conf.json'), 'utf8'));
    const csp: string = conf.app.security.csp;
    expect(isStrictCsp(csp)).toBe(true);
    expect(csp).not.toMatch(/unsafe-inline[^;]*script|script[^;]*unsafe-inline/);
  });

  it('the capability manifest grants no broad fs/shell/http/process scope', () => {
    const cap = JSON.parse(readFileSync(resolve(here, '../../src-tauri/capabilities/default.json'), 'utf8'));
    const perms: string[] = cap.permissions ?? [];
    const broad = /^(fs|shell|http|process|os|dialog):/;
    const offenders = perms.filter((p) => broad.test(p));
    expect(offenders).toEqual([]);
  });
});
