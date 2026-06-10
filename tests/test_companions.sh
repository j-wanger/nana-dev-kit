#!/usr/bin/env bash
# Bidirectional companion validation for templates/.claude/skills/
# Direction A: every companion has parent: matching its owning skill directory
# Direction B: every Read ~/.claude/skills/ reference in SKILL.md resolves to a file

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../templates/.claude/skills"

echo "=== Companion Validation ==="

# --- Direction A: companion → parent field matches owning skill dir ---

echo ""
echo "Direction A: companion parent field validation"

COMPANIONS=$(find "$SKILLS_DIR" -name '*.md' ! -name 'SKILL.md' ! -name 'MANIFEST' | sort)
TOTAL_COMPANIONS=$(echo "$COMPANIONS" | wc -l | tr -d ' ')
A_PASS=0
A_FAIL=0

for companion in $COMPANIONS; do
  rel_path="${companion#"$SKILLS_DIR/"}"
  # Determine owning skill dir: first path component under skills/
  skill_dir=$(echo "$rel_path" | cut -d/ -f1)
  filename=$(basename "$companion")

  # Check frontmatter exists
  first_line=$(head -1 "$companion")
  if [ "$first_line" != "---" ]; then
    test_start "Direction A: $rel_path has frontmatter"
    test_fail "missing YAML frontmatter (first line: $first_line)"
    A_FAIL=$((A_FAIL + 1))
    continue
  fi

  # Check parent field matches skill dir
  parent_val=$(awk '/^---$/{n++; next} n==1 && /^parent:/{sub(/^parent: */, ""); print; exit}' "$companion")
  if [ "$parent_val" = "$skill_dir" ]; then
    A_PASS=$((A_PASS + 1))
  else
    test_start "Direction A: $rel_path parent"
    test_fail "expected parent: $skill_dir, got parent: $parent_val"
    A_FAIL=$((A_FAIL + 1))
  fi
done

test_start "Direction A: $A_PASS/$TOTAL_COMPANIONS companions have correct parent"
if [ "$A_FAIL" -eq 0 ]; then
  test_pass
else
  test_fail "$A_FAIL companions with wrong/missing parent"
fi

# --- Direction B: SKILL.md Read references → file exists ---

echo ""
echo "Direction B: SKILL.md Read reference resolution"

B_TOTAL=0
B_PASS=0
B_FAIL=0

for skill_md in $(find "$SKILLS_DIR" -name 'SKILL.md' | sort); do
  skill_name=$(basename "$(dirname "$skill_md")")

  # Extract Read references to companion files within ~/.claude/skills/
  # Patterns: Read `~/.claude/skills/X/Y.md`, read ~/.claude/skills/X/Y.md
  refs=$(grep -oE '~/.claude/skills/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+\.md' "$skill_md" 2>/dev/null | sort -u || true)

  for ref in $refs; do
    B_TOTAL=$((B_TOTAL + 1))
    rel_ref=$(echo "$ref" | sed 's|^~/.claude/skills/||')
    local_path="$SKILLS_DIR/$rel_ref"

    if [ -f "$local_path" ]; then
      B_PASS=$((B_PASS + 1))
    else
      test_start "Direction B: $skill_name/SKILL.md → $ref"
      test_fail "referenced file not found at $local_path"
      B_FAIL=$((B_FAIL + 1))
    fi
  done
done

test_start "Direction B: $B_PASS/$B_TOTAL Read references resolve"
if [ "$B_FAIL" -eq 0 ]; then
  test_pass
else
  test_fail "$B_FAIL dangling references"
fi

# ---- Direction C (Phase 82): orphan companions — every companion must be referenced ----
# 8 stale referenced_at values and 3 orphan files accumulated invisibly while Directions A/B
# passed. Pinned exemption allow-list (the 3 known orphans, filed as subtraction-review
# candidates in Phase 82) keeps this green today while catching any NEW orphan.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ORPHAN_EXEMPT="dev-wiki/stale-queue-spec.md knowledge-wiki/registry-schema.md knowledge-wiki/session-context.md"

test_start "Direction C: no NEW orphan companions (pinned 3-entry exemption)"
C_FAIL=0
while IFS= read -r comp; do
  rel="${comp#"$SKILLS_DIR"/}"
  case " $ORPHAN_EXEMPT " in *" $rel "*) continue ;; esac
  case "$rel" in knowledge-wiki/domain-profiles/*) continue ;; esac  # dynamic dispatch: wiki-init reads <domain>.md built at runtime
  base=$(basename "$comp")
  # Cross-skill references are legitimate (dev-plan reads dev-wiki templates) — grep the WHOLE tree.
  REFS=$(grep -rl --include='*.md' "$base" "$SKILLS_DIR" 2>/dev/null | grep -v "^$comp\$" || true)
  if [ -z "$REFS" ] \
     && ! grep -rl -q "$base" "$REPO_ROOT/scripts" "$REPO_ROOT/Makefile" "$REPO_ROOT/modules.json" 2>/dev/null; then
    echo "  ORPHAN: $rel (referenced nowhere)"
    C_FAIL=$((C_FAIL + 1))
  fi
done < <(find "$SKILLS_DIR" -mindepth 2 -name '*.md' ! -name 'SKILL.md')
if [ "$C_FAIL" -eq 0 ]; then test_pass; else test_fail "$C_FAIL new orphan companion(s)"; fi

# ---- Direction D (Phase 82): referenced_at "Step N" pointers must name a real step ----
test_start "Direction D: referenced_at Step-N values resolve to a heading in the parent SKILL.md"
D_FAIL=0
while IFS= read -r comp; do
  dir=$(dirname "$comp")
  skill="$dir/SKILL.md"
  [ -f "$skill" ] || continue
  REF=$(sed -n 's/^referenced_at: *"\(.*\)"/\1/p' "$comp" | head -1)
  NUMS=$(echo "$REF" | grep -oE 'Step [0-9]+(\.[0-9]+)?(-[0-9]+)?' | head -1 | sed 's/^Step //' || true)
  [ -z "$NUMS" ] && continue   # free-text pointers (e.g. "companion") are not step-checked
  # Accept singular or plural heading style: "Step 2", "Steps 2-4" — match the full stated range.
  if ! grep -qE "Steps? ${NUMS}([^0-9]|\$)" "$skill"; then
    echo "  STALE: ${comp#"$SKILLS_DIR"/} says '$REF' but 'Step(s) ${NUMS}' not found in SKILL.md"
    D_FAIL=$((D_FAIL + 1))
  fi
done < <(find "$SKILLS_DIR" -mindepth 2 -name '*.md' ! -name 'SKILL.md')
if [ "$D_FAIL" -eq 0 ]; then test_pass; else test_fail "$D_FAIL stale referenced_at pointer(s)"; fi

echo ""
test_summary "companion-validation"
