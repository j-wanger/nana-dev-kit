#!/usr/bin/env bash
# Phase 82 exit-criteria runner — the spec's 10 machine-checkable criteria, verbatim semantics.
# Each criterion prints PASS/FAIL; exit 0 iff all pass.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
M="eval/qa-sweep/verification-matrix.md"
P=0; F=0
ok(){ echo "PASS: $1"; P=$((P+1)); }
no(){ echo "FAIL: $1"; F=$((F+1)); }

make test >/dev/null 2>&1 && ok "make test" || no "make test"
make eval 2>/dev/null | grep -q "52/52" && ok "make eval 52/52" || no "make eval 52/52"
[ "$(bash scripts/check-install-drift.sh | grep -c '^drift:')" -eq 0 ] && ok "drift converged" || no "drift converged"
[ "$(grep -c '^| ' "$M")" -ge 9 ] && ok "matrix >=9 rows" || no "matrix >=9 rows"
AREAS_OK=1
for a in wiring firing companions schema drift coverage docs usage; do
  grep -qiE "^\| *$a *\|" "$M" || AREAS_OK=0
done
[ "$AREAS_OK" = 1 ] && ok "8 area rows anchored" || no "8 area rows anchored"
bash scripts/check-assumption-ledger.sh --schema .dev-wiki/assumption-ledger.md >/dev/null 2>&1 && ok "ledger schema" || no "ledger schema"
[ "$(git log -p --format= -- .dev-wiki/assumption-ledger.md | grep -c '^-[^-]')" -eq 0 ] && ok "ledger append-only" || no "ledger append-only"
make template >/dev/null 2>&1 && git diff --quiet templates/.claude/settings.json && ok "template regen idempotent" || no "template regen idempotent"
# clean-verdict rows must carry a backticked command (area table: $3=command, $5=verdict)
BAD_CLEAN=$(awk -F'|' 'tolower($5) ~ /^[[:space:]]*clean[[:space:]]*$/ && $3 !~ /`/' "$M")
[ -z "$BAD_CLEAN" ] && ok "clean rows carry commands" || no "clean rows carry commands"
# deferred area rows must have a Blockers filing naming the area
MISS=$(awk -F'|' 'tolower($5) ~ /^[[:space:]]*deferred[[:space:]]*$/ {gsub(/ /,"",$2); print $2}' "$M" | while read -r a; do
  [ -n "$a" ] || continue
  grep -qi "$a" .dev-wiki/_CURRENT_STATE.md || echo "MISSING:$a"
done)
[ -z "$MISS" ] && ok "deferred rows filed as blockers" || no "deferred rows filed as blockers ($MISS)"

echo "----"
echo "exit-criteria: $P passed, $F failed"
[ "$F" -eq 0 ]
