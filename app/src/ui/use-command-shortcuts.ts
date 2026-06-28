import { useEffect, useRef } from 'react';
import type { Command } from './commands';

// The global keyboard shortcut layer (Phase 113, T4 / axis 3). Drives the pure
// command registry (T1). It re-dispatches EXISTING actions only — it never
// reaches the host except through a command's ctx callback (the no-bypass
// invariant, T5).
//
// Two task-bound felt-safety footguns:
//   1. NO bare key approves a held destructive gate. The ONLY keyboard approve
//      is a deliberate Cmd/Ctrl+Enter — bare Enter never approves.
//   2. Single-key shortcuts are suppressed while focus is on an editable element
//      (input / textarea / contenteditable — the composer is assistant-ui's
//      ComposerPrimitive.Input). Cmd+K is the one exception so the palette stays
//      reachable mid-typing.

export interface CommandShortcutOptions {
  /** The live command set (buildCommands(ctx)); rebuilt each render, read fresh on each key. */
  commands: Command[];
  /** Open the Cmd+K palette. */
  onOpenPalette: () => void;
  /** When the palette is open it owns its own keys — the global layer stands down. */
  paletteOpen: boolean;
  /** Seam for tests/SSR; defaults to the document. */
  target?: Document | HTMLElement | Window;
}

function isEditable(t: EventTarget | null): boolean {
  const el = t as Element | null;
  if (!el || typeof el.closest !== 'function') return false;
  return !!el.closest(
    'input, textarea, select, [contenteditable=""], [contenteditable="true"], [contenteditable="plaintext-only"]',
  );
}

/** Run the command if present + enabled; returns whether it actually ran. */
function run(commands: Command[], id: string): boolean {
  const cmd = commands.find((c) => c.id === id);
  if (cmd && cmd.enabled()) {
    cmd.run();
    return true;
  }
  return false;
}

export function useCommandShortcuts(opts: CommandShortcutOptions): void {
  // Keep the latest commands/callbacks in a ref so the listener attaches ONCE
  // but never goes stale (the registry is rebuilt on every render).
  const ref = useRef(opts);
  ref.current = opts;

  useEffect(() => {
    const target: Document | HTMLElement | Window = ref.current.target ?? document;
    const handler: EventListener = (ev) => {
      const e = ev as KeyboardEvent;
      const { commands, onOpenPalette, paletteOpen } = ref.current;
      if (paletteOpen) return; // the palette owns keys while open
      const mod = e.metaKey || e.ctrlKey;

      // Cmd/Ctrl+K opens the palette — checked BEFORE the focus-guard so it stays
      // reachable while the composer is focused.
      if (mod && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        onOpenPalette();
        return;
      }

      // Everything below must NOT fire while the user is typing.
      if (isEditable(e.target)) return;

      // Deliberate Cmd/Ctrl+Enter approves a HELD gate. Bare Enter never does
      // (footgun 1) — and enabled() makes it a no-op unless a gate is held.
      if (mod && e.key === 'Enter') {
        e.preventDefault();
        run(commands, 'approve-gate');
        return;
      }
      // Cmd/Ctrl+N → new conversation.
      if (mod && e.key.toLowerCase() === 'n') {
        e.preventDefault();
        run(commands, 'new-conversation');
        return;
      }
      // Esc or Cmd/Ctrl+. → stop the in-flight turn. Only consume the key when we
      // actually stop something, so a no-op Esc still reaches any native handler.
      if (e.key === 'Escape' || (mod && e.key === '.')) {
        if (run(commands, 'stop')) e.preventDefault();
        return;
      }
    };
    target.addEventListener('keydown', handler);
    return () => target.removeEventListener('keydown', handler);
  }, []);
}
