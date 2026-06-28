// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest';
import { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { CommandPalette } from '../../src/ui/command-palette';
import type { Command } from '../../src/ui/commands';

// T3 (axis 3): the Cmd+K command palette — a custom, owned overlay (no cmdk dep).
// Controlled: the shell (T5) owns open/close + Cmd+K; this component renders the
// enabled commands, filters by query, runs the selected one on Enter, closes on
// Esc, and renders titles INERT (model-influenced paths must never be live HTML).

function fakeCommand(over: Partial<Command> & Pick<Command, 'id'>): Command {
  return {
    title: over.id,
    keywords: [],
    enabled: () => true,
    run: () => {},
    ...over,
  };
}

let root: Root | null = null;
let container: HTMLDivElement | null = null;

function render(node: React.ReactElement) {
  container = document.createElement('div');
  document.body.appendChild(container);
  root = createRoot(container);
  act(() => root!.render(node));
  return container;
}

afterEach(() => {
  if (root) act(() => root!.unmount());
  root = null;
  container?.remove();
  container = null;
});

const NATIVE_VALUE = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value')!.set!;
function type(input: HTMLInputElement, value: string) {
  act(() => {
    NATIVE_VALUE.call(input, value);
    input.dispatchEvent(new Event('input', { bubbles: true }));
  });
}
function press(el: Element, key: string) {
  act(() => {
    el.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true }));
  });
}

describe('CommandPalette (T3)', () => {
  it('lists ONLY enabled commands when open', () => {
    const cmds = [
      fakeCommand({ id: 'alpha', title: 'Alpha' }),
      fakeCommand({ id: 'beta', title: 'Beta', enabled: () => false }),
      fakeCommand({ id: 'gamma', title: 'Gamma' }),
    ];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose: () => {} }));
    const items = c.querySelectorAll('.command-palette__item');
    const ids = Array.from(items).map((i) => i.getAttribute('data-command-id'));
    expect(ids).toEqual(['alpha', 'gamma']);
  });

  it('EXCLUDES dangerous commands even when enabled (footgun: no reflexive palette approve)', () => {
    const cmds = [
      fakeCommand({ id: 'safe', title: 'Safe' }),
      fakeCommand({ id: 'approve-gate', title: 'Approve pending action', dangerous: true }),
      fakeCommand({ id: 'deny-gate', title: 'Deny pending action' }),
    ];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose: () => {} }));
    const ids = Array.from(c.querySelectorAll('.command-palette__item')).map((i) =>
      i.getAttribute('data-command-id'),
    );
    expect(ids).toEqual(['safe', 'deny-gate']); // approve-gate (dangerous) is never listed
  });

  it('renders nothing when closed', () => {
    const c = render(
      createElement(CommandPalette, { commands: [fakeCommand({ id: 'a' })], open: false, onClose: () => {} }),
    );
    expect(c.querySelector('.command-palette')).toBeNull();
  });

  it('filters by title AND keyword (case-insensitive)', () => {
    const cmds = [
      fakeCommand({ id: 'stop', title: 'Stop generation', keywords: ['interrupt', 'halt'] }),
      fakeCommand({ id: 'revert', title: 'Revert last edit', keywords: ['undo', 'rewind'] }),
    ];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose: () => {} }));
    const input = c.querySelector('.command-palette__input') as HTMLInputElement;

    type(input, 'HALT'); // matches stop via keyword, case-insensitive
    let ids = Array.from(c.querySelectorAll('.command-palette__item')).map((i) => i.getAttribute('data-command-id'));
    expect(ids).toEqual(['stop']);

    type(input, 'rev'); // matches revert via title
    ids = Array.from(c.querySelectorAll('.command-palette__item')).map((i) => i.getAttribute('data-command-id'));
    expect(ids).toEqual(['revert']);
  });

  it('Enter runs the selected (first) command and closes', () => {
    const run = vi.fn();
    const onClose = vi.fn();
    const cmds = [fakeCommand({ id: 'go', title: 'Go', run }), fakeCommand({ id: 'other', title: 'Other' })];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose }));
    const input = c.querySelector('.command-palette__input') as HTMLInputElement;

    press(input, 'Enter');
    expect(run).toHaveBeenCalledOnce();
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('ArrowDown moves selection so Enter runs the next command', () => {
    const first = vi.fn();
    const second = vi.fn();
    const cmds = [
      fakeCommand({ id: 'first', title: 'First', run: first }),
      fakeCommand({ id: 'second', title: 'Second', run: second }),
    ];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose: () => {} }));
    const input = c.querySelector('.command-palette__input') as HTMLInputElement;

    press(input, 'ArrowDown');
    press(input, 'Enter');
    expect(second).toHaveBeenCalledOnce();
    expect(first).not.toHaveBeenCalled();
  });

  it('Esc closes without running anything', () => {
    const run = vi.fn();
    const onClose = vi.fn();
    const cmds = [fakeCommand({ id: 'go', title: 'Go', run })];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose }));
    const input = c.querySelector('.command-palette__input') as HTMLInputElement;

    press(input, 'Escape');
    expect(onClose).toHaveBeenCalledOnce();
    expect(run).not.toHaveBeenCalled();
  });

  it('restores focus to the previously-focused element when it closes', () => {
    const prior = document.createElement('button');
    document.body.appendChild(prior);
    prior.focus();
    expect(document.activeElement).toBe(prior);

    container = document.createElement('div');
    document.body.appendChild(container);
    root = createRoot(container);
    const props = { commands: [fakeCommand({ id: 'a', title: 'A' })], onClose: () => {} };
    act(() => root!.render(createElement(CommandPalette, { ...props, open: true })));
    // palette input has focus now
    expect(document.activeElement).not.toBe(prior);
    act(() => root!.render(createElement(CommandPalette, { ...props, open: false })));
    expect(document.activeElement).toBe(prior); // focus handed back

    prior.remove();
  });

  it('renders a command title INERT (markup escaped, no live element)', () => {
    const cmds = [fakeCommand({ id: 'evil', title: '<img src=x onerror=alert(1)>' })];
    const c = render(createElement(CommandPalette, { commands: cmds, open: true, onClose: () => {} }));
    const item = c.querySelector('.command-palette__item') as HTMLElement;
    expect(c.querySelector('.command-palette img')).toBeNull(); // no live element
    expect(item.textContent).toContain('<img src=x onerror=alert(1)>'); // shown as inert text
  });
});
