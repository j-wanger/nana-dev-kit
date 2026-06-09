#!/usr/bin/env bash
# coverage-check.sh — deterministic scope-track completeness-by-construction check (Phase 80, T3).
#
# A SURFACER output is COVERAGE-COMPLETE iff every HIGH-cost scope item carries >=1 [scope:<item>]
# assumption. This checks the scope track's completeness PROPERTY (no declared high-cost item left without
# an assumption) — NOT recovery (the screen's job, scored by check.sh). NO LLM.
#
# Modes:
#   coverage-check.sh --check <items-file> <output-file>   -> "COMPLETE" | "GAP:<item>" (first uncovered)
#   coverage-check.sh --selftest                           -> exit 0 iff a compliant output is COMPLETE
#                                                              AND a gappy output is flagged GAP
#
# <items-file>: one high-cost scope-item id per line ('#'/blank ignored).
# <output-file>: surfacer output; coverage counts a line matching '[scope:<item>]' (case-insensitive,
#                literal item id) as covering <item>.
set -euo pipefail

check() {  # <items-file> <output-file>  -> echoes COMPLETE or GAP:<item>
  local items="$1" out="$2" item
  while IFS= read -r item; do
    case "${item:-}" in ''|\#*) continue;; esac
    # a covering line tags the item: [scope:<item>]  (brackets + literal id, case-insensitive)
    if ! grep -Fiq "[scope:${item}]" "$out"; then
      echo "GAP:${item}"; return 0
    fi
  done < "$items"
  echo "COMPLETE"
}

selftest() {
  local d; d="$(mktemp -d)"; trap 'rm -rf "$d"' RETURN
  printf '%s\n' 'hooks-install' 'memory-path' 'session-start-budget' > "$d/items"

  # compliant: every high-cost item has a [scope:<item>] assumption
  cat > "$d/good" <<'EOF'
[scope:memory-path] Memory must actually persist at the configured path, not a sibling dir.
[scope:hooks-install] The enforcement hook must be installed AND firing, not merely registered.
[scope:session-start-budget] session-start.sh must stay within its line budget.
[framing] This problem is worth solving at all.
EOF

  # gappy: 'memory-path' high-cost item left with no [scope:memory-path] assumption
  cat > "$d/bad" <<'EOF'
[scope:hooks-install] The enforcement hook must be installed AND firing.
[scope:session-start-budget] session-start.sh must stay within its line budget.
[framing] This problem is worth solving.
EOF

  local rg rb; rg="$(check "$d/items" "$d/good")"; rb="$(check "$d/items" "$d/bad")"
  if [ "$rg" = COMPLETE ] && [ "$rb" = "GAP:memory-path" ]; then
    echo "selftest OK (compliant=COMPLETE, gappy=$rb)"; return 0
  fi
  echo "selftest FAIL (compliant=$rg, gappy=$rb)" >&2; return 1
}

case "${1:-}" in
  --check)    shift; check "$@";;
  --selftest) selftest;;
  *) echo "usage: $0 --check <items-file> <output-file> | --selftest" >&2; exit 2;;
esac
