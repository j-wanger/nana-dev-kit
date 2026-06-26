// GUI XSS rail (Phase 108, T6). Model and tool output is UNTRUSTED data. The
// terminal never had a renderer; a webview does, so prompt-injected tool output
// (<script>, onerror=, remote loads) must render INERT and never reach the DOM
// as live markup with IPC reach.

// The strict webview CSP. Mirrors tauri.conf.json app.security.csp. No inline
// scripts, no eval, no remote loads — script execution is locked to 'self'.
export const STRICT_CSP =
  "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " +
  "img-src 'self' data:; font-src 'self'; connect-src 'self'; object-src 'none'; " +
  "base-uri 'self'; frame-ancestors 'none'";

/**
 * True if a CSP is strict enough for rendering untrusted model/tool output:
 * script-src is 'self' with no unsafe-inline / unsafe-eval, and object-src is
 * locked down. (style-src may keep 'unsafe-inline' — it cannot execute JS.)
 */
export function isStrictCsp(csp: string): boolean {
  const scriptSrc = /script-src ([^;]*)/.exec(csp)?.[1] ?? '';
  if (scriptSrc === '') return false;
  if (/unsafe-inline|unsafe-eval/.test(scriptSrc)) return false;
  if (!/'self'/.test(scriptSrc)) return false;
  if (!/object-src\s+'none'/.test(csp)) return false;
  return true;
}

/**
 * Render untrusted content as INERT text. Uses textContent — NEVER innerHTML —
 * so any markup/script/attribute payload is shown literally and cannot execute,
 * fire an event handler, or trigger a remote load. A richer (markdown) renderer
 * must sanitize before this point; the safe default is plain text.
 */
export function renderInert(container: HTMLElement, content: string): void {
  container.textContent = content;
}
