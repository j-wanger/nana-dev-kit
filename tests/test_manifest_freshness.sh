#!/usr/bin/env bash
# MANIFEST freshness test (Phase 82). The md5 inventory in templates/.claude/skills/MANIFEST
# was stale for ~100/121 files for 19 phases and silently missed Phase-81's new companions —
# no test asserted the checksums, only the description comments ("MANIFEST freshness" in
# test_templates.sh checks descriptions). This test makes the checksum block load-bearing:
#   A. every checksum line's path exists on disk and its md5 matches (self-line exempt);
#   B. every file on disk under templates/.claude/skills/ has a checksum line;
#   C. every skill dir has a `# <dir>: description` comment line.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_ROOT/templates/.claude/skills/MANIFEST"
SKILLS_DIR="$REPO_ROOT/templates/.claude/skills"

md5_of() {  # portable: macOS `md5 -q` / linux `md5sum`
  if command -v md5 >/dev/null 2>&1; then md5 -q "$1"; else md5sum "$1" | cut -d' ' -f1; fi
}

echo "=== MANIFEST Freshness Tests ==="

test_start "manifest: every checksum line matches disk (self-line exempt)"
BAD=""
while read -r sum path; do
  [ -n "$path" ] || continue
  [ "$path" = "templates/.claude/skills/MANIFEST" ] && continue
  if [ ! -f "$REPO_ROOT/$path" ]; then BAD="$BAD missing:$path"; continue; fi
  [ "$(md5_of "$REPO_ROOT/$path")" = "$sum" ] || BAD="$BAD stale:$path"
done < <(grep -v '^#' "$MANIFEST")
if [ -z "$BAD" ]; then test_pass; else test_fail "stale/missing checksum lines:$BAD"; fi

test_start "manifest: every skill file on disk has a checksum line"
MISSING=""
while IFS= read -r f; do
  rel="${f#"$REPO_ROOT"/}"
  [ "$rel" = "templates/.claude/skills/MANIFEST" ] && continue
  grep -q " $rel\$" "$MANIFEST" || MISSING="$MISSING $rel"
done < <(find "$SKILLS_DIR" -type f ! -name '.*')
if [ -z "$MISSING" ]; then test_pass; else test_fail "files with no MANIFEST line:$MISSING"; fi

test_start "manifest: every skill dir has a description comment"
NODESC=""
for d in "$SKILLS_DIR"/*/; do
  name=$(basename "$d")
  grep -q "^# $name:" "$MANIFEST" || NODESC="$NODESC $name"
done
if [ -z "$NODESC" ]; then test_pass; else test_fail "skill dirs without description:$NODESC"; fi

test_summary "manifest-freshness"
