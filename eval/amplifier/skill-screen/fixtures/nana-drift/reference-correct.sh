#!/usr/bin/env bash
# Faithful minimal reduction of check-install-drift.sh's CORE comparator (the cmp loop): compare every
# file under the kit source (templates/.claude) against <installed-root>/<relpath>; report missing/
# differing relative paths; exit 1 iff any drift else 0. The modules.json comparison-set scoping, the
# bounded exclusion allow-list, and the fail-open guards are the PROJECT-SPECIFIC parts (classified
# unstated-edge in the pre-registration) and are intentionally NOT encoded here — this is the spec-implied
# general core (detects-drift + silent-when-synced) the screen scores. Used as the correct anchor.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/../templates/.claude"
INSTALLED="${1:?usage: cand.sh <installed-root>}"
DRIFT=()
while IFS= read -r kit; do
  rel="${kit#"$SOURCE"/}"
  inst="$INSTALLED/$rel"
  if [ ! -f "$inst" ]; then DRIFT+=("missing: $rel")
  elif ! cmp -s "$kit" "$inst"; then DRIFT+=("differs: $rel"); fi
done < <(find "$SOURCE" -type f 2>/dev/null)
if [ "${#DRIFT[@]}" -gt 0 ]; then printf '%s\n' "${DRIFT[@]}"; exit 1; fi
exit 0
