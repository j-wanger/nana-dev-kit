// @vitest-environment jsdom
import { describe, it, expect, vi } from 'vitest';
import { act, createElement, type ReactElement } from 'react';
import { createRoot } from 'react-dom/client';
import { renderToStaticMarkup } from 'react-dom/server';
import { DiffView } from '../../src/ui/diff-view';
import { GateConfirmView, GateConfirm } from '../../src/ui/gate-confirm';
import type { GatePending } from '../../src/ui/engine-bridge';

// T3 (axis 1 — preview & approve BEFORE it lands). Mechanics only; felt quality
// is the maintainer's call at delivery (Ph59/80).

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

const PENDING: GatePending = {
  callId: 'c1',
  toolName: 'bash',
  diff: '$ rm -rf build',
  summary: 'destructive shell command requires explicit human confirmation',
};

describe('DiffView (T3/T4)', () => {
  it('renders diff lines inert with +/- classes (no live markup)', () => {
    const diff = ['--- a.ts (current)', '+++ a.ts (proposed)', '-const x = 1;', '+const x = <script>2</script>;'].join('\n');
    const html = renderToStaticMarkup(createElement(DiffView, { diff }));
    expect(html).not.toContain('<script>'); // payload is inert
    expect(html).toContain('&lt;script&gt;');
    expect(html).toContain('diff__meta'); // ---/+++ header lines
    expect(html).toContain('diff__del'); // removed line
    expect(html).toContain('diff__add'); // added line
  });
});

describe('GateConfirmView (T3)', () => {
  it('presents the held action (tool, reason, diff) and both verdict controls', () => {
    const html = renderToStaticMarkup(
      createElement(GateConfirmView, { pending: PENDING, onApprove: () => {}, onDeny: () => {} }),
    );
    expect(html).toContain('bash');
    expect(html).toContain('requires explicit human confirmation');
    expect(html).toContain('rm -rf build');
    expect(html).toContain('gate-confirm__approve');
    expect(html).toContain('gate-confirm__deny');
  });

  it('clicking Approve / Deny fires the right callback', async () => {
    const onApprove = vi.fn();
    const onDeny = vi.fn();
    const c = await mount(createElement(GateConfirmView, { pending: PENDING, onApprove, onDeny }));
    await click(c.querySelector('.gate-confirm__approve'));
    expect(onApprove).toHaveBeenCalledTimes(1);
    await click(c.querySelector('.gate-confirm__deny'));
    expect(onDeny).toHaveBeenCalledTimes(1);
  });
});

describe('GateConfirm wired to the bridge (T3 full flow)', () => {
  function mockBridge() {
    let listener: ((p: GatePending) => void) | undefined;
    const respondGate = vi.fn();
    return {
      bridge: {
        onGatePending: (l: (p: GatePending) => void) => {
          listener = l;
          return () => {
            listener = undefined;
          };
        },
        respondGate,
      },
      emit: (p: GatePending) => listener?.(p),
      respondGate,
    };
  }

  it('shows nothing until a hold arrives, then approve posts the verdict and advances', async () => {
    const { bridge, emit, respondGate } = mockBridge();
    const c = await mount(createElement(GateConfirm, { bridge }));
    expect(c.querySelector('.gate-confirm')).toBeNull();

    await act(async () => {
      emit(PENDING);
    });
    expect(c.querySelector('.gate-confirm__tool')?.textContent).toBe('bash');

    await click(c.querySelector('.gate-confirm__approve'));
    expect(respondGate).toHaveBeenCalledWith('c1', true);
    expect(c.querySelector('.gate-confirm')).toBeNull(); // advanced past the resolved hold
  });

  it('queues multiple holds and denies them in order', async () => {
    const { bridge, emit, respondGate } = mockBridge();
    const c = await mount(createElement(GateConfirm, { bridge }));
    await act(async () => {
      emit({ ...PENDING, callId: 'a', toolName: 'write' });
      emit({ ...PENDING, callId: 'b', toolName: 'bash' });
    });
    expect(c.querySelector('.gate-confirm__tool')?.textContent).toBe('write'); // first
    await click(c.querySelector('.gate-confirm__deny'));
    expect(respondGate).toHaveBeenCalledWith('a', false);
    expect(c.querySelector('.gate-confirm__tool')?.textContent).toBe('bash'); // advanced to second
  });
});
