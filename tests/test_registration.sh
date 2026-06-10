#!/usr/bin/env bash
# Bidirectional registration completeness test
# Direction A: every hook file on disk → modules.json entry
# Direction B: every modules.json hook entry → file on disk
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$SCRIPT_DIR/templates/.claude/hooks"
MODULES="$SCRIPT_DIR/modules.json"

source "$SCRIPT_DIR/tests/helpers.sh"

TESTS_RUN=0
TESTS_PASSED=0

# Collect all registered hooks from the canonical scope-tagged list
ALL_REGISTERED=$(jq -r '.hooks[].script' "$MODULES" | sort -u)

# Direction A: every hook file on disk has a modules.json entry
echo "=== Direction A: disk → modules.json ==="
for f in "$HOOKS_DIR"/*.sh "$HOOKS_DIR"/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f")
  TESTS_RUN=$((TESTS_RUN + 1))
  if echo "$ALL_REGISTERED" | grep -qx "$name"; then
    echo "  PASS: $name registered"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  FAIL: $name exists on disk but NOT in modules.json"
  fi
done

# Direction B: every modules.json hook entry exists on disk
echo ""
echo "=== Direction B: modules.json → disk ==="
for h in $ALL_REGISTERED; do
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -f "$HOOKS_DIR/$h" ]; then
    echo "  PASS: $h exists on disk"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "  FAIL: $h in modules.json but NOT on disk"
  fi
done

# Direction D: every canonical hook has a valid scope (project|global)
echo ""
echo "=== Direction D: hook scope validity ==="
TOTAL_HOOKS=$(jq '.hooks | length' "$MODULES")
TAGGED_HOOKS=$(jq '[.hooks[] | select(.scope == "project" or .scope == "global")] | length' "$MODULES")
TESTS_RUN=$((TESTS_RUN + 1))
if [ "$TOTAL_HOOKS" -eq "$TAGGED_HOOKS" ] && [ "$TOTAL_HOOKS" -gt 0 ]; then
  echo "  PASS: all $TOTAL_HOOKS hooks tagged project|global"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo "  FAIL: $TAGGED_HOOKS/$TOTAL_HOOKS hooks have a valid scope"
fi

# Direction C: hook_dirs entries exist
echo ""
echo "=== Direction C: hook_dirs → disk ==="
EXTRA_DIRS=$(jq -r '.hook_dirs[][]' "$MODULES" 2>/dev/null || true)
for d in $EXTRA_DIRS; do
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -d "$HOOKS_DIR/$d" ]; then
    echo "  PASS: $d/ exists"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    for f in "$HOOKS_DIR/$d"/*.sh; do
      [ -f "$f" ] || continue
      TESTS_RUN=$((TESTS_RUN + 1))
      fname=$(basename "$f")
      if grep -q "$fname" "$HOOKS_DIR/session-start.sh" 2>/dev/null; then
        echo "  PASS: $d/$fname sourced by session-start.sh"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo "  FAIL: $d/$fname not sourced by session-start.sh"
      fi
    done
  else
    echo "  FAIL: extra_dir $d/ missing"
  fi
done

echo ""
echo "Registration completeness: $TESTS_PASSED/$TESTS_RUN passed"
[ "$TESTS_PASSED" -eq "$TESTS_RUN" ] || exit 1
