import { resolve, sep } from 'node:path';
import { homedir } from 'node:os';
import { isDeniedPath } from '../security/secret-deny';
import type { GateDecision, NormalizedToolCall, ToolCallGate } from '../engine/types';

// The host-owned, engine-NEUTRAL pre-execution gate (Phase 108, T3). It runs at
// the in-process tool-dispatch site of EVERY adapter (Pi via tool_call, Claude
// via canUseTool) and decides allow / deny / modify BEFORE side effects. It is
// pure policy over a NormalizedToolCall — no engine SDK types — so the gate
// logic is written ONCE and reused (the decision [[engine-adapter-in-process-gate]]
// invariant). Destructive/irreversible actions are denied pending explicit human
// confirmation; tool output is untrusted data and the model choosing to act is
// not authorization.

export interface HostGateConfig {
  /** Writes/edits resolving outside this root are denied. */
  workspaceRoot: string;
  /** Home dir for the secret deny-list (injectable for tests). */
  home?: string;
}

// Destructive command patterns for the `bash` tool. Conservative + auditable:
// the spec's named set is rm / git push / force-push / out-of-workspace write.
const DESTRUCTIVE_BASH: readonly RegExp[] = [
  /\brm\b/i, // file delete
  /\brmdir\b/i,
  /\bgit\s+push\b/i, // push (incl. force-push, caught here and below)
  /--force\b/i,
  /--hard\b/i, // git reset --hard
  /\bmkfs\b/i,
  /\bdd\s+if=/i,
  /\b(shutdown|reboot|halt)\b/i,
  /:\(\)\s*\{/, // fork bomb
];

function deny(reason: string): GateDecision {
  return { action: 'deny', reason };
}

function asString(v: unknown): string | undefined {
  return typeof v === 'string' ? v : undefined;
}

/** Build the host gate. Returns a ToolCallGate consumed by every adapter. */
export function createHostGate(config: HostGateConfig): ToolCallGate {
  const root = resolve(config.workspaceRoot);
  const home = config.home ?? homedir();

  const isOutsideWorkspace = (p: string): boolean => {
    const abs = resolve(root, p);
    return abs !== root && !abs.startsWith(root + sep);
  };

  return (call: NormalizedToolCall): GateDecision => {
    const { name, args } = call;

    switch (name) {
      case 'bash': {
        const command = asString(args.command);
        // Schema-reject (never coerce): bash needs a string command.
        if (command === undefined) return deny('malformed bash call: missing string `command`');
        if (DESTRUCTIVE_BASH.some((re) => re.test(command))) {
          return deny('destructive shell command requires explicit human confirmation');
        }
        return { action: 'allow' };
      }

      case 'write':
      case 'edit': {
        const path = asString(args.path);
        if (path === undefined) return deny(`malformed ${name} call: missing string \`path\``);
        if (isDeniedPath(path, home)) return deny('write to a secret/key-store path is denied');
        if (isOutsideWorkspace(path)) {
          return deny('write outside the workspace root requires explicit human confirmation');
        }
        return { action: 'allow' };
      }

      case 'read': {
        const path = asString(args.path);
        if (path === undefined) return deny('malformed read call: missing string `path`');
        if (isDeniedPath(path, home)) return deny('read of a secret/key-store path is denied');
        return { action: 'allow' };
      }

      default: {
        // Unknown / custom / shadow tool: it still passes through THIS gate (the
        // tool_call hook fires for every tool). Apply the same destructive-pattern
        // and secret-path checks across all string args so a same-named shadow or
        // an unregistered tool cannot evade the policy by renaming.
        for (const value of Object.values(args)) {
          const s = asString(value);
          if (s === undefined) continue;
          if (isDeniedPath(s, home)) return deny(`tool '${name}': secret/key-store path denied`);
          if (DESTRUCTIVE_BASH.some((re) => re.test(s))) {
            return deny(`tool '${name}': destructive payload requires explicit human confirmation`);
          }
        }
        return { action: 'allow' };
      }
    }
  };
}
