// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest';
import { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { useCommandShortcuts } from '../../src/ui/use-command-shortcuts';
import { buildCommands, type CommandContext } from '../../src/ui/commands';

// T4 (axis 3): the global keyboard shortcut layer. Drives the REAL command
// registry (T1). Two task-bound felt-safety footguns are the heart of this test:
//   (1) bare Enter must NEVER auto-approve a held destructive gate — only a
//       deliberate Cmd/Ctrl+Enter approves;
//   (2) single-key shortcuts must NOT fire while focus is on an editable element
//       (the composer is assistant-ui ComposerPrimitive.Input — a textarea /
//       contenteditable), except Cmd+K which stays reachable while typing.

function makeCtx(over: Partial<CommandContext> = {}): CommandContext {
  return {
    gateHeld: false,
    isRunning: false,
    revertiblePaths: [],
    stop: vi.fn(),
    approveGate: vi.fn(),
    denyGate: vi.fn(),
    revertLast: vi.fn(),
    newConversation: vi.fn(),
    focusComposer: vi.fn(),
    changeWorkspace: vi.fn(),
    ...over,
  };
}

let root: Root | null = null;
const extras: HTMLElement[] = [];

function mount(opts: Parameters<typeof useCommandShortcuts>[0]) {
  function Harness() {
    useCommandShortcuts(opts);
    return null;
  }
  const container = document.createElement('div');
  document.body.appendChild(container);
  extras.push(container);
  root = createRoot(container);
  act(() => root!.render(createElement(Harness)));
}

afterEach(() => {
  if (root) act(() => root!.unmount());
  root = null;
  while (extras.length) extras.pop()!.remove();
});

function key(target: EventTarget, k: string, mods: { meta?: boolean; ctrl?: boolean } = {}) {
  act(() => {
    target.dispatchEvent(
      new KeyboardEvent('keydown', { key: k, metaKey: !!mods.meta, ctrlKey: !!mods.ctrl, bubbles: true }),
    );
  });
}

describe('useCommandShortcuts (T4)', () => {
  it('Cmd+K opens the palette', () => {
    const onOpenPalette = vi.fn();
    mount({ commands: buildCommands(makeCtx()), onOpenPalette, paletteOpen: false });
    key(document.body, 'k', { meta: true });
    expect(onOpenPalette).toHaveBeenCalledOnce();
  });

  it('Esc and Cmd+. dispatch stop when a turn is running', () => {
    const ctx = makeCtx({ isRunning: true });
    mount({ commands: buildCommands(ctx), onOpenPalette: vi.fn(), paletteOpen: false });
    key(document.body, 'Escape');
    key(document.body, '.', { meta: true });
    expect(ctx.stop).toHaveBeenCalledTimes(2);
  });

  it('stop does NOT fire when no turn is running (respects enabled())', () => {
    const ctx = makeCtx({ isRunning: false });
    mount({ commands: buildCommands(ctx), onOpenPalette: vi.fn(), paletteOpen: false });
    key(document.body, 'Escape');
    expect(ctx.stop).not.toHaveBeenCalled();
  });

  it('Cmd+N starts a new conversation', () => {
    const ctx = makeCtx();
    mount({ commands: buildCommands(ctx), onOpenPalette: vi.fn(), paletteOpen: false });
    key(document.body, 'n', { meta: true });
    expect(ctx.newConversation).toHaveBeenCalledOnce();
  });

  it('FOOTGUN: bare Enter does NOT approve a held gate', () => {
    const ctx = makeCtx({ gateHeld: true });
    mount({ commands: buildCommands(ctx), onOpenPalette: vi.fn(), paletteOpen: false });
    key(document.body, 'Enter');
    expect(ctx.approveGate).not.toHaveBeenCalled();
  });

  it('deliberate Cmd+Enter approves ONLY when a gate is held', () => {
    const held = makeCtx({ gateHeld: true });
    mount({ commands: buildCommands(held), onOpenPalette: vi.fn(), paletteOpen: false });
    key(document.body, 'Enter', { meta: true });
    expect(held.approveGate).toHaveBeenCalledOnce();

    act(() => root!.unmount());
    root = null;

    const notHeld = makeCtx({ gateHeld: false });
    mount({ commands: buildCommands(notHeld), onOpenPalette: vi.fn(), paletteOpen: false });
    key(document.body, 'Enter', { meta: true });
    expect(notHeld.approveGate).not.toHaveBeenCalled();
  });

  it('FOCUS-GUARD: single-key shortcuts do NOT fire while a TEXTAREA is focused', () => {
    const ctx = makeCtx({ isRunning: true });
    mount({ commands: buildCommands(ctx), onOpenPalette: vi.fn(), paletteOpen: false });
    const ta = document.createElement('textarea');
    document.body.appendChild(ta);
    extras.push(ta);
    ta.focus();
    key(ta, 'Escape');
    expect(ctx.stop).not.toHaveBeenCalled();
  });

  it('FOCUS-GUARD: single-key shortcuts do NOT fire while a CONTENTEDITABLE is focused', () => {
    const ctx = makeCtx({ isRunning: true });
    mount({ commands: buildCommands(ctx), onOpenPalette: vi.fn(), paletteOpen: false });
    const ce = document.createElement('div');
    ce.setAttribute('contenteditable', 'true');
    document.body.appendChild(ce);
    extras.push(ce);
    key(ce, 'Escape');
    expect(ctx.stop).not.toHaveBeenCalled();
  });

  it('Cmd+K STILL opens the palette while a textarea is focused (reachable mid-typing)', () => {
    const onOpenPalette = vi.fn();
    mount({ commands: buildCommands(makeCtx()), onOpenPalette, paletteOpen: false });
    const ta = document.createElement('textarea');
    document.body.appendChild(ta);
    extras.push(ta);
    key(ta, 'k', { meta: true });
    expect(onOpenPalette).toHaveBeenCalledOnce();
  });

  it('Esc consumes the key (preventDefault) ONLY when it actually stops', () => {
    const running = makeCtx({ isRunning: true });
    mount({ commands: buildCommands(running), onOpenPalette: vi.fn(), paletteOpen: false });
    const e1 = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true });
    act(() => {
      document.body.dispatchEvent(e1);
    });
    expect(running.stop).toHaveBeenCalledOnce();
    expect(e1.defaultPrevented).toBe(true);

    act(() => root!.unmount());
    root = null;

    const idle = makeCtx({ isRunning: false });
    mount({ commands: buildCommands(idle), onOpenPalette: vi.fn(), paletteOpen: false });
    const e2 = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true });
    act(() => {
      document.body.dispatchEvent(e2);
    });
    expect(idle.stop).not.toHaveBeenCalled();
    expect(e2.defaultPrevented).toBe(false); // a no-op Esc is left for any native handler
  });

  it('does nothing while the palette is already open (palette owns its keys)', () => {
    const ctx = makeCtx({ isRunning: true });
    const onOpenPalette = vi.fn();
    mount({ commands: buildCommands(ctx), onOpenPalette, paletteOpen: true });
    key(document.body, 'Escape');
    key(document.body, 'k', { meta: true });
    expect(ctx.stop).not.toHaveBeenCalled();
    expect(onOpenPalette).not.toHaveBeenCalled();
  });
});
