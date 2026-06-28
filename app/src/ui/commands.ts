// The command registry (Phase 113, T1 / axis 3 — "every action reachable by
// button, shortcut, or palette search"). A PURE, engine-neutral list of the
// harness's actions. The Cmd+K palette (T3) and the keyboard shortcut layer (T4)
// are thin consumers: each only reads `title`/`keywords`/`shortcut`, asks
// `enabled()`, and calls `run()`. No React/DOM import — node-testable, and it
// outlives whatever the palette UI becomes.
//
// SECURITY: every command re-dispatches an EXISTING action through the ctx
// callbacks the app already owns (stop/approve/deny/revert/new/focus). The
// registry introduces NO new privileged path — it cannot reach the host except
// through a callback the shell wired from an existing bridge/runtime method.

/** Live harness state + the action callbacks a command may invoke. */
export interface CommandContext {
  /** A destructive tool call is held at the gate, awaiting approve/deny. */
  gateHeld: boolean;
  /** A turn is streaming (a tool/model run is in flight). */
  isRunning: boolean;
  /** Files with a one-action revert available (most-recent last). */
  revertiblePaths: readonly string[];

  stop: () => void;
  approveGate: () => void;
  denyGate: () => void;
  revertLast: () => void;
  newConversation: () => void;
  focusComposer: () => void;
}

/** One palette/shortcut action. `enabled`/`run` are bound to a ctx snapshot. */
export interface Command {
  id: string;
  title: string;
  keywords: string[];
  /** Display hint for the palette/shortcut row (the actual key handling is T4). */
  shortcut?: string;
  /**
   * A destructive, irreversible-leaning action (approving a held gate). Dangerous
   * commands are EXCLUDED from the Cmd+K palette so a reflexive open-then-Enter
   * can never run one — they stay reachable only via a deliberate surface (the
   * gate-confirm modal button, or the deliberate Cmd/Ctrl+Enter shortcut).
   */
  dangerous?: boolean;
  enabled: () => boolean;
  run: () => void;
}

/**
 * Build the command set bound to the current ctx. Called fresh on each render so
 * `enabled()` reflects live state; consumers never re-derive predicates.
 */
export function buildCommands(ctx: CommandContext): Command[] {
  return [
    {
      id: 'stop',
      title: 'Stop generation',
      keywords: ['stop', 'interrupt', 'cancel', 'halt', 'abort'],
      shortcut: 'Esc',
      enabled: () => ctx.isRunning,
      run: () => ctx.stop(),
    },
    {
      id: 'approve-gate',
      title: 'Approve pending action',
      keywords: ['approve', 'allow', 'confirm', 'gate', 'run'],
      // Destructive: kept out of the palette (the gate-confirm modal button +
      // the deliberate Cmd/Ctrl+Enter are the only approve paths — never a
      // reflexive palette Enter).
      dangerous: true,
      enabled: () => ctx.gateHeld,
      run: () => ctx.approveGate(),
    },
    {
      id: 'deny-gate',
      title: 'Deny pending action',
      keywords: ['deny', 'reject', 'block', 'gate', 'cancel'],
      enabled: () => ctx.gateHeld,
      run: () => ctx.denyGate(),
    },
    {
      id: 'revert-last',
      title: 'Revert last edit',
      keywords: ['revert', 'undo', 'rewind', 'rollback', 'restore'],
      enabled: () => ctx.revertiblePaths.length > 0,
      run: () => ctx.revertLast(),
    },
    {
      id: 'new-conversation',
      title: 'New conversation',
      keywords: ['new', 'clear', 'reset', 'conversation', 'thread', 'fresh'],
      shortcut: 'Cmd+N',
      enabled: () => true,
      run: () => ctx.newConversation(),
    },
    {
      id: 'focus-composer',
      title: 'Focus composer',
      keywords: ['focus', 'compose', 'input', 'prompt', 'type'],
      enabled: () => true,
      run: () => ctx.focusComposer(),
    },
  ];
}
