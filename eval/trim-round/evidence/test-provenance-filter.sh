#!/usr/bin/env bash
# Seeded-fixture test for filter-enforcement-log.sh (Phase 88 T1 RED).
# Controls-first: the filter's output counts only after this fixture — with a KNOWN
# composition — classifies correctly. A filter that miscounts any cell fails here.
set -uo pipefail
cd "$(dirname "$0")"

FILTER="./filter-enforcement-log.sh"
[ -x "$FILTER" ] || { echo "FAIL: $FILTER missing or not executable"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Synthetic slice — known composition for hook=enforce-memory:
#   phase 87: 2 allow, 1 block   | phase 88: 1 allow, 1 block
#   legacy (no phase field): 1 allow
#   other-hook noise that must NOT be counted: 3 lines
cat > "$TMP/fixture.log" << 'EOF'
{"schema_version":1,"ts":"2026-06-10T10:00:00Z","hook":"enforce-memory","action":"allow","reason":"allowlisted-path","phase":"87"}
{"schema_version":1,"ts":"2026-06-10T10:01:00Z","hook":"enforce-memory","action":"allow","reason":"memory-consulted","phase":"87"}
{"schema_version":1,"ts":"2026-06-10T10:02:00Z","hook":"enforce-memory","action":"block","reason":"no-memory-search","phase":"87"}
{"schema_version":1,"ts":"2026-06-11T09:00:00Z","hook":"enforce-memory","action":"allow","reason":"allowlisted-path","phase":"88"}
{"schema_version":1,"ts":"2026-06-11T09:05:00Z","hook":"enforce-memory","action":"block","reason":"no-memory-search","phase":"88"}
{"ts":"2026-05-25T17:33:50Z","hook":"enforce-memory","action":"allow","reason":"allowlisted-path"}
{"ts":"2026-05-25T17:33:51Z","hook":"enforce-spec","action":"block","reason":"no-approved-spec"}
{"schema_version":1,"ts":"2026-06-10T10:03:00Z","hook":"dev-wiki-scope-check","action":"allow","reason":"allowlisted-path","phase":"87"}
{"schema_version":1,"ts":"2026-06-10T10:04:00Z","hook":"enforce-loop","action":"allow","reason":"all-checks-passed","phase":"87"}
EOF

OUT=$("$FILTER" "$TMP/fixture.log" enforce-memory) || { echo "FAIL: filter exited non-zero"; exit 1; }

declare -i fails=0
assert_cell() { # assert_cell <key> <expected>
  local got
  got=$(grep -E "^$1=" <<< "$OUT" | cut -d= -f2)
  if [ "$got" != "$2" ]; then echo "FAIL: $1 expected=$2 got=${got:-<missing>}"; fails+=1; fi
}

assert_cell total 6
assert_cell allow 4
assert_cell block 2
assert_cell unattributed 1
assert_cell "phase_87" 3
assert_cell "phase_88" 2
# block lines echoed for downstream follow-through pairing — exactly the 2 seeded blocks
blines=$(grep -cE '^BLOCK ' <<< "$OUT")
[ "$blines" = "2" ] || { echo "FAIL: BLOCK lines expected=2 got=$blines"; fails+=1; }

if [ "$fails" -eq 0 ]; then echo "PASS: provenance filter classifies seeded fixture correctly"; exit 0; fi
exit 1
