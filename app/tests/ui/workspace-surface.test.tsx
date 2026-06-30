// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from 'vitest';
import { act, createElement, type ReactElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { WorkspaceIndicator } from '../../src/ui/workspace-indicator';
import { buildCommands, type CommandContext } from '../../src/ui/commands';
import { BridgeClient, type TauriBridge, type WorkspaceInfo } from '../../src/ui/engine-bridge';
import type { HostOutbound } from '../../src/host/engine-host';

// Phase 114, T5 — the workspace UI surface. The header shows the ACTIVE workspace
// + the PROJECT-BLIND state (whether any AGENTS.md/CLAUDE.md/.claude/rules context
// was found), carried on the host `ready` as workspaceRoot + available + sources —
// NOT the systemContext string (which holds the full project-instruction CONTENTS
// and must never leak into the chrome). A "Change workspace…" command is in the
// palette and invokes the picker through a ctx callback (no new privileged path).

let root: Root | null = null;
let container: HTMLDivElement | null = null;
afterEach(() => {
  if (root) act(() => root!.unmount());
  root = null;
  container?.remove();
  container = null;
});

function render(node: ReactElement): HTMLDivElement {
  container = document.createElement('div');
  document.body.appendChild(container);
  root = createRoot(container);
  act(() => root!.render(node));
  return container;
}

describe('WorkspaceIndicator — active workspace + project-blind state (T5)', () => {
  it('shows the workspace folder name and the context source count when available', () => {
    const info: WorkspaceInfo = {
      root: '/Users/jake/code/my-project',
      available: true,
      sources: [
        { path: 'AGENTS.md', bytes: 1200 },
        { path: '.claude/rules/active-phase.md', bytes: 800 },
      ],
    };
    const el = render(createElement(WorkspaceIndicator, { info }));
    expect(el.textContent).toContain('my-project');
    expect(el.textContent).toMatch(/2 context sources/i);
    expect(el.querySelector('[data-blind="true"]')).toBeNull();
  });

  it('flags PROJECT-BLIND when no project context was found', () => {
    const info: WorkspaceInfo = { root: '/tmp/blank', available: false, sources: [] };
    const el = render(createElement(WorkspaceIndicator, { info }));
    expect(el.textContent).toContain('blank');
    expect(el.textContent).toMatch(/project-blind/i);
    expect(el.querySelector('[data-blind="true"]')).not.toBeNull();
  });

  it('renders nothing before the first ready (no workspace info yet)', () => {
    const el = render(createElement(WorkspaceIndicator, { info: null }));
    expect(el.textContent).toBe('');
  });
});

function mockTauri() {
  let handler: ((p: string) => void) | undefined;
  const tauri: TauriBridge = {
    invoke: async () => undefined,
    listen: async (_e, h) => {
      handler = h;
      return () => {
        handler = undefined;
      };
    },
  };
  return { tauri, emit: (m: HostOutbound) => handler?.(JSON.stringify(m)) };
}

describe('BridgeClient surfaces workspace info from the host ready (T5)', () => {
  it('stores + notifies workspaceRoot and project-blind state from a widened ready', async () => {
    const m = mockTauri();
    const client = new BridgeClient(m.tauri);
    await client.start();
    const seen: WorkspaceInfo[] = [];
    client.onWorkspace((w) => seen.push(w));
    expect(client.currentWorkspace).toBeNull();

    m.emit({
      type: 'ready',
      workspaceRoot: '/ws/proj',
      available: true,
      sources: [{ path: 'AGENTS.md', bytes: 10 }],
    });

    expect(client.currentWorkspace).toEqual({
      root: '/ws/proj',
      available: true,
      sources: [{ path: 'AGENTS.md', bytes: 10 }],
    });
    expect(seen).toHaveLength(1);
    expect(seen[0]!.root).toBe('/ws/proj');
  });

  it('onWorkspace fires immediately with the current value for a late subscriber', async () => {
    const m = mockTauri();
    const client = new BridgeClient(m.tauri);
    await client.start();
    m.emit({ type: 'ready', workspaceRoot: '/ws/late', available: false, sources: [] });
    const seen: WorkspaceInfo[] = [];
    client.onWorkspace((w) => seen.push(w));
    expect(seen).toEqual([{ root: '/ws/late', available: false, sources: [] }]);
  });
});

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

describe('the "Change workspace…" palette command (T5)', () => {
  it('is registered, enabled, palette-eligible (not dangerous), and invokes ctx.changeWorkspace', () => {
    const changeWorkspace = vi.fn();
    const cmd = buildCommands(makeCtx({ changeWorkspace })).find((c) => c.id === 'change-workspace');
    expect(cmd).toBeDefined();
    expect(cmd!.title).toMatch(/change workspace/i);
    expect(cmd!.dangerous).toBeFalsy();
    expect(cmd!.enabled()).toBe(true);
    cmd!.run();
    expect(changeWorkspace).toHaveBeenCalledTimes(1);
  });
});
