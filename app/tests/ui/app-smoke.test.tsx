// @vitest-environment jsdom
import { describe, it, expect } from 'vitest';
import { act, createElement } from 'react';
import { createRoot } from 'react-dom/client';
import { App } from '../../src/App';

// T5: the composed surface boots and degrades gracefully when no engine host is
// connected (a plain browser / `vite dev`), so the window always renders. The
// connected, drivable surface + felt quality is the maintainer's launch check.

describe('App composition smoke (T5)', () => {
  it('boots, renders the brand + a status, and shows the disconnected view (no crash, no live engine)', async () => {
    const container = document.createElement('div');
    document.body.appendChild(container);
    const root = createRoot(container);

    await act(async () => {
      root.render(createElement(App));
    });
    // let the bridge-connect effect settle a few ticks (no Tauri => offline)
    for (let i = 0; i < 8; i++) {
      await act(async () => {
        await new Promise((r) => setTimeout(r, 5));
      });
    }

    expect(container.querySelector('.app__brand')?.textContent).toBe('nana');
    expect(container.querySelector('.app__status')).not.toBeNull();
    // bridge is null without Tauri => the graceful disconnected view renders
    expect(container.querySelector('.disconnected')).not.toBeNull();
    expect(container.querySelector('.surface')).toBeNull();

    act(() => root.unmount());
  });
});
