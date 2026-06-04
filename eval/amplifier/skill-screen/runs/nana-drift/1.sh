#!/usr/bin/env bash
#
# cand.sh — detect drift between an INSTALLED copy of a tool's config tree
# and its SOURCE tree.
#
# Usage: cand.sh <installed-root>
#
# The SOURCE tree is templates/.claude resolved relative to this script.
# The kit-managed set is every file under SOURCE/skills/ and SOURCE/rules/.
# For each managed file, compare byte-for-byte against
# <installed-root>/<same-relative-path>. Print each managed file that is
# MISSING from or DIFFERS in the installed root (path relative to .claude/).
# Exit 0 if nothing differs; non-zero if any file drifts.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/../templates/.claude"

INSTALLED_ROOT="${1:-}"
if [ -z "$INSTALLED_ROOT" ]; then
    echo "usage: $(basename "${BASH_SOURCE[0]}") <installed-root>" >&2
    exit 2
fi

drift=0

# Iterate over every file under the kit-managed subtrees.
for subtree in skills rules; do
    src_dir="$SOURCE/$subtree"
    [ -d "$src_dir" ] || continue

    while IFS= read -r -d '' src_file; do
        # Path of the managed file relative to .claude/ (e.g. skills/foo/bar
        # or rules/baz). This is both the comparison key and the reported path.
        rel="${src_file#$SOURCE/}"

        installed_file="$INSTALLED_ROOT/$rel"

        if [ ! -f "$installed_file" ]; then
            # Missing from the installed root.
            echo "$rel"
            drift=1
        elif ! cmp -s "$src_file" "$installed_file"; then
            # Present but differs byte-for-byte.
            echo "$rel"
            drift=1
        fi
    done < <(find "$src_dir" -type f -print0)
done

exit "$drift"
