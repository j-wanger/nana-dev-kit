#!/usr/bin/env bash
#
# cand.sh — detect drift between an INSTALLED .claude tree and its SOURCE.
#
# Contract:
#   cand.sh <installed-root>
#
# SOURCE is templates/.claude relative to this script. The kit-managed set is
# every file under SOURCE/skills/ and SOURCE/rules/. Each managed file is
# compared byte-for-byte against <installed-root>/<same-relative-path>. Any
# managed file that is MISSING from or DIFFERS in the installed root is printed
# (path relative to .claude/, e.g. skills/<name>/<file> or rules/<file>).
# Exit 0 if nothing drifts; non-zero if any file drifts.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/../templates/.claude"

if [ "$#" -lt 1 ]; then
    echo "usage: $(basename "$0") <installed-root>" >&2
    exit 2
fi

INSTALLED_ROOT="$1"

drift=0

# Walk every file under the two managed subtrees of SOURCE.
while IFS= read -r src_file; do
    # Path relative to SOURCE (the .claude root), e.g. skills/foo/bar or rules/baz.
    rel="${src_file#"$SOURCE"/}"
    installed_file="$INSTALLED_ROOT/$rel"

    if [ ! -e "$installed_file" ]; then
        # Missing from the installed root.
        printf '%s\n' "$rel"
        drift=1
    elif ! cmp -s -- "$src_file" "$installed_file"; then
        # Present but differs byte-for-byte.
        printf '%s\n' "$rel"
        drift=1
    fi
done < <(find "$SOURCE/skills" "$SOURCE/rules" -type f 2>/dev/null)

exit "$drift"
