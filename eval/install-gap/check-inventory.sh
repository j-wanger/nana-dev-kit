#!/usr/bin/env bash
# check-inventory.sh — format validator for the Phase-85 install-path inventory artifact.
# An inventory row without a status, or a missing causal-path verdict, must FAIL loudly:
# the artifact is checkpoint-1 evidence, and an empty section header must not pass as evidence.
#
# Usage:
#   check-inventory.sh [inventory.md]   # validate; exit 0 = well-formed, 1 = violation
#   check-inventory.sh --selftest       # seeded good/bad fixtures; exit 0 iff all behave
#
# Checks:
#   1. file exists
#   2. every data row of the "## Shipping paths" table has status fixed | exempt: <rationale> | pending
#   3. a line "causal-path verdict: confirmed|refuted" exists (the A1 hypothesis is machine-checked)
#   4. "## Consumption status" section has content (A3 checkpoint input)
#   5. "## Mode-drift exemption" section has content (reasoned exemption, not an oversight)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

validate() {
  local file="$1" v=0
  [ -f "$file" ] || { echo "inventory: file not found: $file" >&2; return 1; }

  # 2. Shipping-paths table rows. State-flag awk (EOF-safe): inside the section, every
  # row that looks like a data row (starts with '| ' and is not header/separator) must
  # end in a valid status cell.
  awk '
    /^## Shipping paths/ { insec=1; next }
    /^## /               { insec=0 }
    insec && /^\|/ {
      if ($0 ~ /^\|[- |]+\|$/) next                       # separator row
      if ($0 ~ /^\| *path *\|/) next                      # header row
      rows++
      if ($0 !~ /\| (fixed|exempt: [^|]+|pending) \|$/) {
        print "inventory: row without valid status: " $0 > "/dev/stderr"; bad=1
      }
    }
    END {
      if (rows < 1) { print "inventory: no data rows in ## Shipping paths" > "/dev/stderr"; exit 1 }
      exit bad ? 1 : 0
    }
  ' "$file" || v=1

  # 3. machine-checkable A1 verdict
  grep -qE '^causal-path verdict: (confirmed|refuted)$' "$file" \
    || { echo "inventory: missing 'causal-path verdict: confirmed|refuted' line" >&2; v=1; }

  # 4./5. named sections must have non-empty content (header alone fails)
  for sec in "Consumption status" "Mode-drift exemption"; do
    awk -v sec="$sec" '
      $0 ~ "^## " sec { insec=1; next }
      /^## /          { insec=0 }
      insec && /[^[:space:]]/ { found=1 }
      END { exit found ? 0 : 1 }
    ' "$file" || { echo "inventory: section '## $sec' missing or empty" >&2; v=1; }
  done

  return $v
}

selftest() {
  local d pass=0 fail=0
  d="$(mktemp -d)"
  trap 'rm -rf "$d"' RETURN

  # good fixture
  cat > "$d/good.md" << 'EOF'
# Inventory
causal-path verdict: confirmed
## Shipping paths
| path | evidence | status |
|---|---|---|
| a | e | pending |
| b | e | exempt: recursive |
## Consumption status
- registration-dead
## Mode-drift exemption
- sourced files
EOF
  # bad: row without status
  sed 's/| a | e | pending |/| a | e |  |/' "$d/good.md" > "$d/bad-row.md"
  # bad: missing verdict line
  grep -v '^causal-path verdict' "$d/good.md" > "$d/bad-verdict.md"
  # bad: empty consumption section
  sed 's/^- registration-dead$//' "$d/good.md" > "$d/bad-empty-sec.md"

  validate "$d/good.md" >/dev/null 2>&1        && pass=$((pass+1)) || { echo "selftest FAIL: good fixture rejected" >&2; fail=1; }
  validate "$d/bad-row.md" >/dev/null 2>&1     && { echo "selftest FAIL: statusless row accepted" >&2; fail=1; } || pass=$((pass+1))
  validate "$d/bad-verdict.md" >/dev/null 2>&1 && { echo "selftest FAIL: missing verdict accepted" >&2; fail=1; } || pass=$((pass+1))
  validate "$d/bad-empty-sec.md" >/dev/null 2>&1 && { echo "selftest FAIL: empty section accepted" >&2; fail=1; } || pass=$((pass+1))

  echo "selftest: $pass/4 fixtures behaved"
  return $fail
}

case "${1:-}" in
  --selftest) selftest ;;
  *) validate "${1:-$SCRIPT_DIR/inventory.md}" && echo "inventory: well-formed" ;;
esac
