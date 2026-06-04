#!/usr/bin/env bash
# nana-drift.sh — score an OFF re-derivation A' of the kit drift-comparator's core on its spec-implied
# assertions: silent-when-synced + detects-drift. Builds a throwaway kit-shaped sandbox (a source tree
# + a synced installed-root + a drifted one) and runs A' against each. Prints PASS | FAIL:<assertion-id>.
# NO LLM. (Contract pinned in pre-registration: `cand.sh <installed-root>`, source resolved at
# $scriptdir/../templates/.claude.)
set -uo pipefail
out="${1:-}"
[ -f "$out" ] || { echo "FAIL:NO-OUTPUT"; exit 0; }
sb="$(mktemp -d)"; trap 'rm -rf "$sb"' EXIT
src="$sb/templates/.claude"; mkdir -p "$src/skills/foo" "$src/rules" "$sb/scripts"
printf 'hello\n'     > "$src/skills/foo/SKILL.md"
printf 'rule body\n' > "$src/rules/bar.md"
cp "$out" "$sb/scripts/cand.sh"; chmod +x "$sb/scripts/cand.sh"
# synced installed-root (identical to source)
synced="$sb/synced"; mkdir -p "$synced/skills/foo" "$synced/rules"
cp "$src/skills/foo/SKILL.md" "$synced/skills/foo/SKILL.md"; cp "$src/rules/bar.md" "$synced/rules/bar.md"
# drifted installed-root (one managed file differs)
drift="$sb/drift"; mkdir -p "$drift/skills/foo" "$drift/rules"
printf 'CHANGED\n' > "$drift/skills/foo/SKILL.md"; cp "$src/rules/bar.md" "$drift/rules/bar.md"

run() { ( cd "$sb/scripts" && bash ./cand.sh "$1" ); }
# silent-when-synced: exit 0 AND no drift output
so="$(run "$synced" 2>/dev/null)"; sc=$?
if [ "$sc" -ne 0 ] || [ -n "$so" ]; then echo "FAIL:silent-when-synced"; exit 0; fi
# detects-drift: nonzero exit OR names the changed file
do_="$(run "$drift" 2>/dev/null)"; dc=$?
if [ "$dc" -eq 0 ] && ! printf '%s' "$do_" | grep -q 'foo/SKILL.md'; then echo "FAIL:detects-drift"; exit 0; fi
echo PASS
