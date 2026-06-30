import type { WorkspaceInfo } from './engine-bridge';

// The active-workspace header chip (Phase 114, T5). Shows the chosen folder name
// and the PROJECT-BLIND state — whether any AGENTS.md/CLAUDE.md/.claude/rules
// context was assembled for the agent. It renders only the root + per-file sizes
// that crossed on the host `ready`; the systemContext CONTENTS never reach here.
// The path is user-chosen via the native OS dialog (not model/tool output), and
// React escapes text children, so the chip is plain trusted text.

export function WorkspaceIndicator({ info }: { info: WorkspaceInfo | null }) {
  if (!info) return null;
  const name = basename(info.root);
  const n = info.sources.length;
  return (
    <span
      className="app__workspace"
      data-blind={!info.available}
      title={info.root}
    >
      <span className="app__workspace-name">{name}</span>
      {info.available ? (
        <span className="app__workspace-ctx">
          {n} context {n === 1 ? 'source' : 'sources'}
        </span>
      ) : (
        <span className="app__workspace-blind">project-blind</span>
      )}
    </span>
  );
}

/** Last path segment of a POSIX or Windows path (the displayed folder name). */
function basename(p: string): string {
  const parts = p.split(/[/\\]+/).filter(Boolean);
  return parts.at(-1) ?? p;
}
