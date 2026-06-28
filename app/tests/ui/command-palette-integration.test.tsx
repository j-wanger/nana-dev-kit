// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest';
import { act, createElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { HarnessSurface } from '../../src/App';
import { BridgeClient, type TauriBridge } from '../../src/ui/engine-bridge';

// T5 (axis 3): the palette + shortcuts wired into the real composed surface,
// driven by REAL commands built from live runtime/gate/revert state. Uses the
// real BridgeClient over a fake Tauri transport so gate-pending can be injected.

let root: Root | null = null;
let container: HTMLDivElement | null = null;
let feed: ((payload: string) => void) | null = null;

function makeBridge(): BridgeClient {
  const tauri: TauriBridge = {
    invoke: vi.fn(async () => undefined),
    listen: async (_event, handler) => {
      feed = handler;
      return () => {};
    },
  };
  return new BridgeClient(tauri);
}

async function mount(bridge: BridgeClient) {
  await bridge.start();
  container = document.createElement('div');
  document.body.appendChild(container);
  root = createRoot(container);
  await act(async () => {
    root!.render(createElement(HarnessSurface, { bridge }));
  });
}

function cmdK() {
  act(() => {
    document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'k', metaKey: true, bubbles: true }));
  });
}

function paletteIds(): string[] {
  return Array.from(document.querySelectorAll('.command-palette__item')).map(
    (i) => i.getAttribute('data-command-id')!,
  );
}

afterEach(() => {
  if (root) act(() => root!.unmount());
  root = null;
  container?.remove();
  container = null;
  feed = null;
});

describe('command palette integration (T5)', () => {
  it('Cmd+K opens the palette wired to the real command registry', async () => {
    await mount(makeBridge());
    expect(document.querySelector('.command-palette')).toBeNull();

    cmdK();
    expect(document.querySelector('.command-palette')).not.toBeNull();
    // always-enabled real commands are present
    const ids = paletteIds();
    expect(ids).toContain('new-conversation');
    expect(ids).toContain('focus-composer');
  });

  it('deny-gate appears only when a gate is held; approve-gate is NEVER in the palette (footgun fix)', async () => {
    await mount(makeBridge());

    cmdK();
    expect(paletteIds()).not.toContain('approve-gate');
    expect(paletteIds()).not.toContain('deny-gate');
    // close the palette
    act(() => {
      document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    });

    // The host surfaces a held destructive call via the real bridge route.
    expect(feed).toBeTruthy();
    await act(async () => {
      feed!(
        JSON.stringify({
          type: 'gate-pending',
          callId: 'c1',
          toolName: 'bash',
          diff: '',
          summary: 'rm -rf /tmp/x',
        }),
      );
    });

    cmdK();
    const ids = paletteIds();
    // deny (the SAFE direction) is reachable by palette search...
    expect(ids).toContain('deny-gate');
    // ...but APPROVE (destructive) is dangerous → excluded so a reflexive
    // Cmd+K then Enter can never approve a held action.
    expect(ids).not.toContain('approve-gate');
  });
});
