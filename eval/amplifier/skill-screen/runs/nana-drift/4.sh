#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/../templates/.claude"

INSTALLED_ROOT="${1:-}"
if [ -z "$INSTALLED_ROOT" ]; then
    echo "usage: $0 <installed-root>" >&2
    exit 2
fi

drift=0

for sub in skills rules; do
    base="$SOURCE/$sub"
    [ -d "$base" ] || continue

    while IFS= read -r -d '' src_file; do
        rel="${src_file#$SOURCE/}"
        installed_file="$INSTALLED_ROOT/$rel"

        if [ ! -f "$installed_file" ]; then
            echo "$rel"
            drift=1
        elif ! cmp -s "$src_file" "$installed_file"; then
            echo "$rel"
            drift=1
        fi
    done < <(find "$base" -type f -print0)
done

if [ "$drift" -ne 0 ]; then
    exit 1
fi

exit 0
