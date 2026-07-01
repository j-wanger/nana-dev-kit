import type { SkillInfo, TemplateInfo } from '../engine/types';

// The command registry (Phase 113, T1 / axis 3 — "every action reachable by
// button, shortcut, or palette search"). A PURE, engine-neutral list of the
// harness's actions. The Cmd+K palette (T3) and the keyboard shortcut layer (T4)
// are thin consumers: each only reads `title`/`keywords`/`shortcut`, asks
// `enabled()`, and calls `run()`. No React/DOM import — node-testable, and it
// outlives whatever the palette UI becomes.
//
// Phase 119 T7 — the registry is a shared command SOURCE: the static harness
// actions PLUS the session's prompt-templates + skills (dynamic slash-commands).
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
  /** Open the native folder picker + re-spawn the sidecar at the chosen root (T5). */
  changeWorkspace: () => void;
  /** Ph119 T2: manually compact the engine context (a gated session mutation). */
  compact: () => void;
  /** Ph119 T4: cycle to the next available model (a gate-surviving mutation). */
  cycleModel: () => void;
  /** Ph119 T5: cycle to the next thinking level (a gate-surviving mutation). */
  cycleThinking: () => void;
  /**
   * Ph119 T7: submit `text` as a GATED prompt (through the composer's turn path →
   * engine.sendPrompt → the host gate). Prompt-template / skill commands use this —
   * they add NO new privileged path (the resulting turn's every tool call is gated).
   */
  submitPrompt: (text: string) => void;
}

/** Ph119 T7: the session's dynamic command sources (prompt templates + skills). */
export interface CommandSources {
  templates?: readonly TemplateInfo[];
  skills?: readonly SkillInfo[];
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
 * Ph119 T7 — the session's prompt-templates + skills as palette slash-commands.
 * Each SUBMITS a gated prompt (through ctx.submitPrompt → engine.sendPrompt → the
 * host gate). NOT dangerous, so they show in the palette (the dangerous-command
 * exclusion is honored) — but the submit still flows through the gate, so surfacing
 * them adds NO new privileged path (Ph115 no-bypass).
 */
export function buildDynamicCommands(ctx: CommandContext, sources: CommandSources): Command[] {
  const words = (s: string): string[] => s.toLowerCase().split(/\s+/).filter(Boolean);
  const cmds: Command[] = [];
  for (const t of sources.templates ?? []) {
    cmds.push({
      id: `template:${t.name}`,
      title: `/${t.name}${t.description ? ` — ${t.description}` : ''}`,
      keywords: ['template', 'prompt', t.name.toLowerCase(), ...words(t.description)],
      enabled: () => true,
      run: () => ctx.submitPrompt(t.content),
    });
  }
  for (const s of sources.skills ?? []) {
    cmds.push({
      id: `skill:${s.name}`,
      title: `/${s.name}${s.description ? ` — ${s.description}` : ''}`,
      keywords: ['skill', s.name.toLowerCase(), ...words(s.description)],
      enabled: () => true,
      run: () => ctx.submitPrompt(`Use the "${s.name}" skill.`),
    });
  }
  return cmds;
}

/**
 * Build the command set bound to the current ctx. Called fresh on each render so
 * `enabled()` reflects live state; consumers never re-derive predicates. Ph119 T7:
 * appends the session's prompt-template + skill commands when `sources` is supplied.
 */
export function buildCommands(ctx: CommandContext, sources: CommandSources = {}): Command[] {
  const staticCommands: Command[] = [
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
    {
      id: 'compact',
      title: 'Compact context',
      keywords: ['compact', 'compress', 'summarize', 'context', 'shrink', 'trim', 'window'],
      // Not dangerous: compaction is a safe maintenance action (Pi summarizes the
      // history) — every tool call still passes the gate. DISABLED while a turn is
      // running: Pi's compact() ABORTS the in-flight operation first, so mid-stream
      // it would kill the running turn (Ph119 review nit 1).
      enabled: () => !ctx.isRunning,
      run: () => ctx.compact(),
    },
    {
      id: 'cycle-model',
      title: 'Cycle model',
      keywords: ['model', 'switch', 'cycle', 'llm', 'local', 'hosted', 'provider', 'anthropic'],
      // Not dangerous: switching model is a gate-surviving session mutation (the
      // gate still governs every tool call after). DISABLED while running — a
      // mid-stream model swap is undefined (Ph119 review nit 1); switch between turns.
      enabled: () => !ctx.isRunning,
      run: () => ctx.cycleModel(),
    },
    {
      id: 'cycle-thinking',
      title: 'Cycle thinking level',
      keywords: ['thinking', 'reasoning', 'effort', 'cycle', 'level', 'minimal', 'low', 'medium', 'high'],
      // Not dangerous: a gate-surviving session mutation (synchronous field set).
      // DISABLED while running — the change takes effect next turn anyway.
      enabled: () => !ctx.isRunning,
      run: () => ctx.cycleThinking(),
    },
    {
      id: 'change-workspace',
      title: 'Change workspace…',
      keywords: ['workspace', 'folder', 'directory', 'project', 'open', 'switch', 'change', 'root', 'cwd'],
      // Not dangerous: it only opens the native folder dialog — the user must pick
      // a folder for anything to happen, and the re-spawn rebuilds a fresh gate at
      // the chosen root. So it stays in the palette (unlike approve-gate).
      enabled: () => true,
      run: () => ctx.changeWorkspace(),
    },
  ];
  return [...staticCommands, ...buildDynamicCommands(ctx, sources)];
}
