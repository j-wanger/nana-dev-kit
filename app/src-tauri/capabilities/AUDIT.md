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

## Dialog plugin (Phase 114, T3) — registered Rust-side, NO webview grant

The workspace picker registers `tauri-plugin-dialog`, but the renderer is granted
**no `dialog:` permission**. The native folder dialog is opened from Rust inside
the `pick_workspace` command (`app.dialog().file().blocking_pick_folder()`), and a
Rust-side plugin call bypasses the webview ACL entirely — the permission system
only gates webview→core IPC. So the webview can invoke `pick_workspace` (app
commands are allowed by default) but cannot open a dialog itself, cannot pass a
path into it, and gains no `dialog:`/`fs:` reach. This is deliberately tighter
than a `dialog:allow-open` grant: the renderer never sees the dialog API at all.

The picker is **Rust-atomic** by design (decision A4): the gate auto-allows
in-workspace writes, so the chosen folder IS the free-write zone. If the webview
could supply the root, that would relocate the gate boundary — so `pick_workspace`
takes no path argument and the root is chosen only through the native OS dialog.

## Invariant

Any new capability must be added here with a justification before it ships. The
test `tests/security/inert-render.test.ts` fails if `default.json` grants a
broad `fs:` / `shell:` / `http:` / `process:` scope, and
`tests/security/workspace-picker.test.ts` fails if any capability file grants a
broad `fs/shell/http/process/os` scope or any `dialog:` permission beyond
`dialog:allow-open`, and if `pick_workspace` ever takes a webview-supplied path —
so a wide grant or a webview-relocatable gate root cannot land silently.

## Runtime verification (deferred)

CSP enforcement + the capability manifest are webview-runtime properties. They
are verified end-to-end when the Tauri shell is compiled and launched (the
deferred "compile + launch the Tauri shell" task — spec exit criterion #1).
