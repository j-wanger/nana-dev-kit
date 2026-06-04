#!/usr/bin/env bash
#
# cand.sh — detect drift between an INSTALLED copy of a tool's config tree and
# its SOURCE tree (templates/.claude).
#
# Usage:
#   cand.sh <installed-root>
#
# Compares every kit-managed file (everything under SOURCE/skills/ and
# SOURCE/rules/) byte-for-byte against the same relative path under the
# installed root. Prints each managed file that is MISSING from or DIFFERS in
# the installed root (path relative to .claude/, e.g. skills/<name>/<file> or
# rules/<file>). Exits 0 if nothing drifts; non-zero if any file drifts.

set -u

# Resolve the SOURCE tree relative to this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/../templates/.claude"

# Argument: the installed root to compare against.
if [ "$#" -lt 1 ]; then
    echo "usage: $(basename "$0") <installed-root>" >&2
    exit 2
fi
INSTALLED_ROOT="$1"

drift=0

# Iterate every managed file under SOURCE/skills/ and SOURCE/rules/.
# -print0 / read -d '' handles paths containing spaces or other oddities.
while IFS= read -r -d '' src_file; do
    # Path of this managed file relative to SOURCE (i.e. relative to .claude/).
    rel="${src_file#"$SOURCE"/}"

    installed_file="$INSTALLED_ROOT/$rel"

    if [ ! -f "$installed_file" ]; then
        # Missing in the installed root → drift.
        echo "$rel"
        drift=1
    elif ! cmp -s "$src_file" "$installed_file"; then
        # Present but byte content differs → drift.
        echo "$rel"
        drift=1
    fi
done < <(find "$SOURCE/skills" "$SOURCE/rules" -type f -print0 2>/dev/null)

if [ "$drift" -ne 0 ]; then
    exit 1
fi

exit 0
