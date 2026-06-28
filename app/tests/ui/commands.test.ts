import { describe, it, expect, vi } from 'vitest';
import { buildCommands, type CommandContext } from '../../src/ui/commands';

// T1 (axis 3): the pure command registry. buildCommands(ctx) returns the harness
// command set with enabled()/run() bound to the live ctx. No React/DOM here — the
// registry is engine-neutral and node-testable; the palette (T3) and shortcut
// layer (T4) are thin consumers of this list.

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
    ...over,
  };
}

function cmd(ctx: CommandContext, id: string) {
  const found = buildCommands(ctx).find((c) => c.id === id);
  if (!found) throw new Error(`no command with id ${id}`);
  return found;
}

describe('command registry (T1)', () => {
  it('every command has id, non-empty title, and keywords', () => {
    const cmds = buildCommands(makeCtx());
    expect(cmds.length).toBeGreaterThanOrEqual(6);
    for (const c of cmds) {
      expect(c.id).toBeTruthy();
      expect(c.title.trim().length).toBeGreaterThan(0);
      expect(Array.isArray(c.keywords)).toBe(true);
    }
    // ids are unique
    const ids = cmds.map((c) => c.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  describe('enabled() predicates', () => {
    it('stop is enabled ONLY when a turn is running', () => {
      expect(cmd(makeCtx({ isRunning: false }), 'stop').enabled()).toBe(false);
      expect(cmd(makeCtx({ isRunning: true }), 'stop').enabled()).toBe(true);
    });

    it('approve/deny gate are enabled ONLY when a gate is held', () => {
      expect(cmd(makeCtx({ gateHeld: false }), 'approve-gate').enabled()).toBe(false);
      expect(cmd(makeCtx({ gateHeld: false }), 'deny-gate').enabled()).toBe(false);
      expect(cmd(makeCtx({ gateHeld: true }), 'approve-gate').enabled()).toBe(true);
      expect(cmd(makeCtx({ gateHeld: true }), 'deny-gate').enabled()).toBe(true);
    });

    it('revert-last is enabled ONLY when a revertible edit exists', () => {
      expect(cmd(makeCtx({ revertiblePaths: [] }), 'revert-last').enabled()).toBe(false);
      expect(cmd(makeCtx({ revertiblePaths: ['src/a.ts'] }), 'revert-last').enabled()).toBe(true);
    });

    it('new-conversation and focus-composer are always enabled', () => {
      const ctx = makeCtx();
      expect(cmd(ctx, 'new-conversation').enabled()).toBe(true);
      expect(cmd(ctx, 'focus-composer').enabled()).toBe(true);
    });
  });

  describe('run() dispatches to the matching ctx callback', () => {
    it('stop -> ctx.stop', () => {
      const ctx = makeCtx({ isRunning: true });
      cmd(ctx, 'stop').run();
      expect(ctx.stop).toHaveBeenCalledOnce();
    });

    it('approve-gate -> ctx.approveGate; deny-gate -> ctx.denyGate (no cross-wiring)', () => {
      const ctx = makeCtx({ gateHeld: true });
      cmd(ctx, 'approve-gate').run();
      cmd(ctx, 'deny-gate').run();
      expect(ctx.approveGate).toHaveBeenCalledOnce();
      expect(ctx.denyGate).toHaveBeenCalledOnce();
      expect(ctx.stop).not.toHaveBeenCalled();
    });

    it('revert-last -> ctx.revertLast', () => {
      const ctx = makeCtx({ revertiblePaths: ['src/a.ts'] });
      cmd(ctx, 'revert-last').run();
      expect(ctx.revertLast).toHaveBeenCalledOnce();
    });

    it('new-conversation -> ctx.newConversation; focus-composer -> ctx.focusComposer', () => {
      const ctx = makeCtx();
      cmd(ctx, 'new-conversation').run();
      cmd(ctx, 'focus-composer').run();
      expect(ctx.newConversation).toHaveBeenCalledOnce();
      expect(ctx.focusComposer).toHaveBeenCalledOnce();
    });
  });
});
