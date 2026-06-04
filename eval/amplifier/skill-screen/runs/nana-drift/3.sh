#!/usr/bin/env bash
#
# cand.sh — detect drift between an INSTALLED copy of a tool's .claude config
# tree and its SOURCE tree (templates/.claude).
#
# Usage: cand.sh <installed-root>
#
# Reports every kit-managed file (under SOURCE/skills/ and SOURCE/rules/)
# whose installed copy is MISSING or DIFFERS, printing the path relative to
# .claude/ (e.g. skills/<skill>/<file> or rules/<file>).
#
# Exit 0 if synced; non-zero if any managed file drifts.

set -u

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <installed-root>" >&2
    exit 2
fi

INSTALLED_ROOT="$1"

# Resolve SOURCE relative to this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/../templates/.claude"

drift=0

# Iterate every managed file under skills/ and rules/.
for subtree in skills rules; do
    src_subtree="$SOURCE/$subtree"

    # Skip absent subtrees (nothing managed there).
    [ -d "$src_subtree" ] || continue

    # Find all regular files; NUL-delimited to survive odd names.
    while IFS= read -r -d '' src_file; do
        # Path relative to SOURCE (i.e. relative to .claude/).
        rel="${src_file#"$SOURCE"/}"

        installed_file="$INSTALLED_ROOT/$rel"

        if [ ! -e "$installed_file" ]; then
            # Missing from installed root.
            printf '%s\n' "$rel"
            drift=1
        elif ! cmp -s -- "$src_file" "$installed_file"; then
            # Byte-for-byte differs.
            printf '%s\n' "$rel"
            drift=1
        fi
    done < <(find "$src_subtree" -type f -print0)
done

if [ "$drift" -ne 0 ]; then
    exit 1
fi

exit 0
