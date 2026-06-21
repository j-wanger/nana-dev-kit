#!/usr/bin/env bash
# Phase 95 — Memory-Layer Disposition exit-criteria runner.
#
# Two modes:
#   --selftest   controls-first: seed MALFORMED verdict tables in a mktemp sandbox and assert the
#                table-structure validator REJECTS each (out-of-enum cell, non-keep writer row, missing
#                component row, destructive enforce-memory row with no zero-class marker), then seed a
#                well-formed table and assert it PASSES. Clean-on-seed = instrument-dead -> exit 1.
#   (no args)    run ALL spec exit criteria against the live artifacts; exit 0 iff every one passes.
#                This is the FINAL phase gate (T4) — it stays RED until the audit/spike/verdict/ledger
#                artifacts exist, by design.
#
# Verdict-table row schema is PINNED (spec Scope): `| <id> | <verdict> | <evidence> |` — the verdict is
# COLUMN 2 (the first cell after the id). Every table grep anchors on column 2; NONE match the enum token
# anywhere-in-line (the Tier-1 review showed an anywhere-match false-flags/false-passes wide tables).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TABLE="$ROOT/eval/memory-disposition/verdict-table.md"
AUDIT="$ROOT/eval/memory-disposition/enforce-memory-audit.md"
SPIKE="$ROOT/eval/memory-disposition/redesign-spike.md"
LEDGER="$ROOT/.dev-wiki/assumption-ledger.md"
WINDOW="$ROOT/eval/dogfood-round/evidence/window-events.md"
PH92_SPEC="$ROOT/specs/phase-92-memory-layer-prune.md"

COMPONENT='(memory-mcp-layer|bridge-writer|harvest-writer|enforce-memory)'
ENUM='(keep|cut|harden|disable-at-boundary|redesign|deferred-inadmissible)'

# ---- table-structure validator (column-2-anchored) -------------------------------------------------
# Returns 0 iff the table file at $1 satisfies every structural rule; prints the first violation to stderr.
validate_table_structure() {
  local f="$1" ok=0
  [ -f "$f" ] || { echo "  table missing: $f" >&2; return 1; }

  # exactly the 4 component rows present (id is the first cell)
  local nrows
  nrows=$(grep -oE "^\| $COMPONENT \|" "$f" | sort -u | wc -l | tr -d ' ')
  [ "$nrows" = 4 ] || { echo "  expected 4 component rows, found $nrows" >&2; ok=1; }

  # every component row carries a closed-enum verdict in COLUMN 2
  if grep -E "^\| $COMPONENT \|" "$f" | grep -vqE "^\| [a-z-]+ \| $ENUM \|"; then
    echo "  a component row lacks a closed-enum verdict in column 2" >&2; ok=1
  fi

  # both writer rows are keep in column 2
  if grep -E '^\| (bridge-writer|harvest-writer) \|' "$f" | grep -vqE '^\| [a-z-]+ \| keep \|'; then
    echo "  a writer row is not keep (evidence-split asymmetry violated)" >&2; ok=1
  fi

  # both trim rows present with a confirm|restore disposition in column 2
  local ntrim
  ntrim=$(grep -oE '^\| (ak-ride-along|wk-seeding) \|' "$f" | sort -u | wc -l | tr -d ' ')
  [ "$ntrim" = 2 ] || { echo "  expected 2 trim rows, found $ntrim" >&2; ok=1; }
  if grep -E '^\| (ak-ride-along|wk-seeding) \|' "$f" | grep -vqE '^\| [a-z-]+ \| (confirm|restore) \|'; then
    echo "  a trim row lacks a confirm|restore disposition in column 2" >&2; ok=1
  fi

  # a destructive enforce-memory verdict MUST carry its zero-class marker line
  if grep -qE '^\| enforce-memory \| (cut|disable-at-boundary) \|' "$f" \
     && ! grep -qE '^enforce-memory-zero-class: (couldnt-fire|didnt-fire)$' "$f"; then
    echo "  destructive enforce-memory verdict missing enforce-memory-zero-class line" >&2; ok=1
  fi

  return $ok
}

# ---- --selftest: controls-first over seeded fixtures -----------------------------------------------
selftest() {
  local tmp rc=0
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN

  # a well-formed reference table the mutations are derived from
  cat > "$tmp/good.md" <<'TBL'
| id | verdict | evidence |
|---|---|---|
| memory-mcp-layer | keep | ev-a |
| bridge-writer | keep | ev-b |
| harvest-writer | keep | ev-c |
| enforce-memory | keep | ev-d |
| ak-ride-along | confirm | ev-e |
| wk-seeding | confirm | ev-f |
SURVIVOR-SMOKE: N/A (no destructive verdict)
TBL

  # control 1: out-of-enum verdict cell
  sed 's/^| memory-mcp-layer | keep |/| memory-mcp-layer | banana |/' "$tmp/good.md" > "$tmp/c1.md"
  # control 2: a writer row with a non-keep cell
  sed 's/^| bridge-writer | keep |/| bridge-writer | cut |/' "$tmp/good.md" > "$tmp/c2.md"
  # control 3: a missing component row (drop harvest-writer)
  grep -v '^| harvest-writer |' "$tmp/good.md" > "$tmp/c3.md"
  # control 4: a destructive enforce-memory verdict with NO zero-class marker line
  sed 's/^| enforce-memory | keep |/| enforce-memory | cut |/' "$tmp/good.md" > "$tmp/c4.md"

  local name
  for name in c1 c2 c3 c4; do
    if validate_table_structure "$tmp/$name.md" 2>/dev/null; then
      echo "SELFTEST FAIL: malformed control $name was ACCEPTED (instrument-dead)"; rc=1
    else
      echo "selftest ok: control $name rejected"
    fi
  done
  if validate_table_structure "$tmp/good.md" 2>/dev/null; then
    echo "selftest ok: well-formed table accepted"
  else
    echo "SELFTEST FAIL: well-formed table was REJECTED"; rc=1
  fi

  [ "$rc" = 0 ] && echo "SELFTEST: PASS" || echo "SELFTEST: FAIL"
  return $rc
}

# ---- full exit-criteria run (the T4 final gate) ----------------------------------------------------
PASS=0; FAIL=0
chk() { # chk "<label>" <command...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "[PASS] $label"; PASS=$((PASS+1))
  else echo "[FAIL] $label"; FAIL=$((FAIL+1)); fi
}

run_all() {
  chk "controls-first --selftest"                 bash "${BASH_SOURCE[0]}" --selftest
  chk "table structure valid"                     validate_table_structure "$TABLE"
  chk "redesign only if SPIKE: PASS"              bash -c "! grep -qE '^\| enforce-memory \| redesign \|' '$TABLE' || grep -qx 'SPIKE: PASS' '$SPIKE'"
  chk "destructive enforce-memory has zero-class" bash -c "! grep -qE '^\| enforce-memory \| (cut|disable-at-boundary) \|' '$TABLE' || grep -qE '^enforce-memory-zero-class: (couldnt-fire|didnt-fire)\$' '$TABLE'"
  chk "non-keep enforce-memory supersedes Ph88"   bash -c "grep -qE '^\| enforce-memory \| keep \|' '$TABLE' || grep -qE '^supersedes: enforce-memory@Phase-88' '$TABLE'"
  chk "survivor-smoke recorded"                   bash -c "grep -qx 'SURVIVOR-SMOKE: N/A (no destructive verdict)' '$TABLE' || grep -qx 'SURVIVOR-SMOKE: PASS' '$TABLE'"
  chk "firing audit + positive control"           bash -c "test -f '$AUDIT' && grep -q 'POSITIVE-CONTROL: PASS' '$AUDIT'"
  chk "redesign spike closed verdict"             bash -c "test -f '$SPIKE' && grep -qE '^SPIKE: (PASS|FAIL)' '$SPIKE'"
  chk "Phase-83 A5 no longer open"                bash -c "! grep -E '^- A5 .*kit-side memory-layer' '$LEDGER' | grep -q 'revisit-status: open'"
  chk "ledger validator + gate 95"                bash -c "bash '$ROOT/scripts/check-assumption-ledger.sh' '$LEDGER' && bash '$ROOT/scripts/check-assumption-ledger.sh' --gate '$LEDGER' 95"
  chk "window-events Phase-95 attestation"        grep -q '^## Phase 95' "$WINDOW"
  chk "phase-92 spec superseded"                  bash -c "head -20 '$PH92_SPEC' | grep -qi 'supersed'"
  echo "---- $PASS passed, $FAIL failed ----"
  [ "$FAIL" = 0 ]
}

case "${1:-}" in
  --selftest) selftest ;;
  --validate-table) validate_table_structure "$TABLE" && echo "table OK" ;;
  *) run_all ;;
esac
