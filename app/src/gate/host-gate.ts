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

// Arg keys that name a filesystem path across the common write-tool vocabularies
// (alternately-named write tools land in the `default` branch). Checked for
// out-of-workspace targets there so a `write_file`/`apply_patch`/etc. cannot
// evade the workspace boundary by not being literally named `write`/`edit`.
const PATH_ARG_KEYS: ReadonlySet<string> = new Set([
  'path',
  'file_path',
  'filepath',
  'filename',
  'file',
  'target_file',
  'dest',
  'destination',
  'output',
  'output_path',
  'out',
]);

// Standard non-file device sinks. Writing to these cannot escape the workspace
// or destroy data, and `2>/dev/null` / `>/dev/null 2>&1` are the most frequent
// shell idioms — exempt them so the gate doesn't flood the human with confirm
// holds for harmless redirects (alert fatigue erodes the gate; Ph111 review).
const DEV_SINK = /^\/dev\/(null|zero|stdout|stderr|tty|fd\/\d+)$/;

function stripQuotes(s: string): string {
  const q = s[0];
  if (s.length >= 2 && (q === '"' || q === "'") && s[s.length - 1] === q) return s.slice(1, -1);
  return s;
}

// Heuristic extraction of bash file-WRITE targets (redirects / tee / cp|mv dest
// / dd of=). INCOMPLETE BY NATURE: string-gating arbitrary shell cannot be a
// complete boundary — a determined model evades via `python -c`, `node -e`,
// base64-encoded paths, or env indirection. This closes the demonstrated +
// common vectors (Phase 111 baseline probe); the COMPLETE fix is OS-sandboxing
// bash's filesystem to the workspace (routed to a follow-on phase).
function extractBashWriteTargets(command: string): string[] {
  const targets: string[] = [];
  const tokenClass = `"[^"]+"|'[^']+'|[^\\s;|&()<>]+`;
  // Output redirects: > >> &> N> N>>, and the force-clobber >| / N>| — capture the
  // following token. fd-dups (>&1) yield no capture (the target class excludes
  // '&'); the optional `\\|` consumes the clobber operator so `>| /path` is caught.
  for (const m of command.matchAll(new RegExp(`(?:\\d*&?)?>>?\\|?\\s*(${tokenClass})`, 'g'))) {
    targets.push(stripQuotes(m[1]));
  }
  // tee [-flags] FILE...
  for (const m of command.matchAll(/\btee\b((?:\s+(?:"[^"]+"|'[^']+'|[^\s;|&]+))*)/g)) {
    for (const a of m[1].trim().split(/\s+/).filter(Boolean)) {
      if (!a.startsWith('-')) targets.push(stripQuotes(a));
    }
  }
  // cp / mv: the last non-flag token of the segment is the destination.
  for (const m of command.matchAll(/\b(?:cp|mv)\b\s+([^;|&]+)/g)) {
    const args = m[1].trim().split(/\s+/).filter((a) => a && !a.startsWith('-'));
    if (args.length >= 1) targets.push(stripQuotes(args[args.length - 1]));
  }
  // dd of=PATH
  for (const m of command.matchAll(/\bof=("[^"]+"|'[^']+'|[^\s;|&]+)/g)) {
    targets.push(stripQuotes(m[1]));
  }
  return targets;
}

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
        // Workspace-boundary coverage for bash file-WRITES (the `write`/`edit`
        // path check below does not see redirect/tee/cp/mv/dd). Heuristic +
        // incomplete (see extractBashWriteTargets) — closes the common vectors.
        // Standard /dev sinks are exempt: harmless + extremely common (Ph111 review).
        if (
          extractBashWriteTargets(command)
            .filter((t) => !DEV_SINK.test(t))
            .some(isOutsideWorkspace)
        ) {
          return deny('bash write outside the workspace root requires explicit human confirmation');
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
        for (const [key, value] of Object.entries(args)) {
          const s = asString(value);
          if (s === undefined) continue;
          if (isDeniedPath(s, home)) return deny(`tool '${name}': secret/key-store path denied`);
          // Out-of-workspace WRITE coverage for alternately-named write tools:
          // a path-like arg resolving outside the root requires confirmation.
          if (PATH_ARG_KEYS.has(key) && isOutsideWorkspace(s)) {
            return deny(`tool '${name}': write outside the workspace root requires explicit human confirmation`);
          }
          if (DESTRUCTIVE_BASH.some((re) => re.test(s))) {
            return deny(`tool '${name}': destructive payload requires explicit human confirmation`);
          }
        }
        return { action: 'allow' };
      }
    }
  };
}
