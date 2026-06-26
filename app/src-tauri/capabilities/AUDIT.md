# Capability Manifest Audit (Phase 108, T6)

The Tauri capability manifest is **the security boundary**, not the CSP alone: an
over-broad filesystem/shell capability chained with an XSS is RCE. So the
manifest is audited and justified grant-by-grant, never defaulted wide.

## Current grants (`default.json`)

| Permission | Justification |
|---|---|
| `core:default` | Window/app/event/lifecycle core only. No filesystem, shell, http, or dialog access is granted to the webview. |

## Explicitly NOT granted (the renderer cannot reach these)

- `fs:*` — no filesystem access from the webview. File mutations go through the
  in-process gate + checkpoint layer (T3/T5) in the Node/Rust layer, never the
  renderer.
- `shell:*` — no shell execution from the webview.
- `http:*` — no arbitrary network from the webview (CSP `connect-src 'self'`
  also blocks remote fetches from injected content).
- `dialog:*`, `os:*`, `process:*` — not granted.

## Invariant

Any new capability must be added here with a justification before it ships. The
test `tests/security/inert-render.test.ts` fails if `default.json` grants a
broad `fs:` / `shell:` / `http:` / `process:` scope, so a wide grant cannot land
silently.

## Runtime verification (deferred)

CSP enforcement + the capability manifest are webview-runtime properties. They
are verified end-to-end when the Tauri shell is compiled and launched (the
deferred "compile + launch the Tauri shell" task — spec exit criterion #1).
