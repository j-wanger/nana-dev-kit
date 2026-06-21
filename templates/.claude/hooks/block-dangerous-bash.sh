#!/usr/bin/env bash
# PreToolUse hook for Bash tool — blocks dangerous commands.
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude as reason).
# Claude Code pipes tool input JSON to stdin.

set -euo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || true  # Phase 79: resolve project-relative refs regardless of CWD

command -v jq >/dev/null 2>&1 || { echo "[nana:block] jq not found, hook skipped" >&2; exit 0; }

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .input.command // empty' 2>/dev/null || echo "")

# Block rm -rf ONLY when a dangerous TARGET (root, a system top-level dir, home, parent, or the cwd
# itself) appears as a standalone argument. The prior pattern matched `/` anywhere after `rm -rf`, so
# any relative path containing a slash (e.g. `.claude/foo`, `build/`) was wrongly blocked; it also
# required `r` before `f`, silently MISSING `rm -fr /`. Here: (1) recognize recursive+force in either
# order, combined or separate, incl. --recursive/--force; (2) require a dangerous target token bounded
# by whitespace within the SAME simple command ([^;&|]* never crosses a ; && || separator). POSIX
# [[:space:]] (not \s) for portability. A relative subdir delete (`.claude/x`, `dist/assets`) is allowed.
RM_RF='rm[[:space:]]+([^;&|]*[[:space:]])?(-[a-zA-Z]*[rR][a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*[rR]|-[rR][[:space:]]+(-[a-zA-Z]*)?f|(-[a-zA-Z]*)?f[[:space:]]+-[a-zA-Z]*[rR]|--recursive[[:space:]]+([^;&|]*[[:space:]])?(--force|-[a-zA-Z]*f)|(--force|-[a-zA-Z]*f)[[:space:]]+([^;&|]*[[:space:]])?--recursive|--recursive[[:space:]]+([^;&|]*[[:space:]])?-[a-zA-Z]*f|-[rR][[:space:]]+([^;&|]*[[:space:]])?--force|--force[[:space:]]+([^;&|]*[[:space:]])?-[rR])'
# Dangerous target as a standalone arg (always whitespace-preceded after the flags). Scope = exactly what
# the prior pattern protected, minus the relative-path false positive: an ABSOLUTE path (starts with `/` —
# covers /, /*, /etc, /tmp/x, ...), `~`/`$HOME` (home), `..`/`../` (parent), or `.`/`./`/`.*` (the cwd
# itself). A RELATIVE subpath (no leading slash: `.claude/x`, `build/`, `dist/assets`) is NOT a target and
# is allowed — that is the fix. (A leading `/` always means absolute; relative paths can never start with one.)
TGT='(/|~(/|[[:space:]]|$|\*|")|\$\{?HOME|\.\.(/|[[:space:]]|$|")|\.(/)?([[:space:]]|$|")|\./?\*)'
# Optional leading double-quote ([\"]?) lets a quoted target (rm -rf "$HOME", rm -rf "/") still match.
if echo "$COMMAND" | grep -qE "${RM_RF}[^;&|]*[[:space:]][\"]?${TGT}"; then
  echo "[nana:block] Blocked: recursive force-delete targeting an absolute path (/...), home (~ / \$HOME), the parent (..), or the current directory. Use a path relative to your project (e.g. build/, .claude/x)." >&2
  exit 2
fi

# Block force-push
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+-f'; then
  echo "[nana:block] Blocked: force-push is not allowed. Open a PR instead, or use --force-with-lease if you must overwrite." >&2
  exit 2
fi

# Block --no-verify on commit/push
if echo "$COMMAND" | grep -qE 'git\s+(commit|push)\s+.*--no-verify'; then
  echo "[nana:block] Blocked: --no-verify bypasses pre-commit hooks. Fix the underlying hook failure instead." >&2
  exit 2
fi

# Block git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "[nana:block] Blocked: git reset --hard discards uncommitted changes. Use git stash or git checkout for specific files." >&2
  exit 2
fi

exit 0
