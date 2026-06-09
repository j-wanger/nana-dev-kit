#!/usr/bin/env bash
# check-assumption-ledger.sh — deterministic, NO-LLM validator for the Phase-81 assumption ledger.
# The dev-plan assumption gate is an LLM-executed skill step (no exit code); its FIRING evidence is the
# ledger row, so this check asserts on the row, not on prose ([[HEU-012]]: verify firing, not presence).
# Bash + grep/awk only — there is deliberately NO LLM anywhere in this path. Fail LOUD on a violation.
#
# ============================ ## Ledger schema ============================
# THE single source of truth for the ledger format. The dev-plan gate companion
# (templates/.claude/skills/dev-plan/assumption-gate.md) and the dev-debrief revisit step reference THIS
# file BY PATH — do NOT inline a divergent schema copy anywhere else.
#
#   File: .dev-wiki/assumption-ledger.md — APPEND-ONLY. One block per phase, newest at the bottom.
#   Prior blocks are NEVER rewritten except to fill a blank `revisit-status:` at debrief.
#
#     # Assumption Ledger                          (file title, once)
#
#     ## Phase <N> — <name>                        (block header; <N> is an integer, word-boundary matched)
#     - date: YYYY-MM-DD
#     - all_accept: true|false                     (true iff every position below is `accept`)
#     - A<k> | cost: <high|medium|low> | position: <accept|reject|don't-know> | revisit-status: <S> | "<text>"
#
#   revisit-status <S> ∈ { (blank) | held | bit | open }
#     (blank) = not yet revisited — filled at debrief;  held = assumption held (did not bite);
#     bit     = proved wrong / bit during implementation;  open = deferred (e.g. a deferred don't-know).
# ==========================================================================
#
# Usage:
#   check-assumption-ledger.sh --schema <file>             # block/field well-formedness; exit 1 on violation
#   check-assumption-ledger.sh --revisit <file> [phase]    # flag blank revisit-status (all blocks, or one phase)
#   check-assumption-ledger.sh --gate <file> <phase>       # flag a phase with no block / no positions taken
#   check-assumption-ledger.sh --append-only <cur> [base]  # no prior ## Phase block removed (base = git HEAD if omitted)
#   check-assumption-ledger.sh <file>                      # default: schema (hard) + append-only(vs HEAD, hard) + revisit (advisory)
#   check-assumption-ledger.sh --selftest                  # internal fixtures, both directions; exit 0 iff all pass

set -uo pipefail

# --- --schema: every block well-formed. EOF-safe via a state-flag + END flush (NOT range syntax). -----
validate_schema() {
  local file="$1"
  [ -f "$file" ] || { echo "schema: file not found: $file" >&2; return 1; }
  awk '
    function flush() {
      if (phase=="") return
      if (!have_date) { print "schema: Phase " phase " missing date:" > "/dev/stderr"; v=1 }
      if (!have_aa)   { print "schema: Phase " phase " missing all_accept:" > "/dev/stderr"; v=1 }
      if (n_assump<1) { print "schema: Phase " phase " has no assumption lines (no positions taken)" > "/dev/stderr"; v=1 }
    }
    /^## Phase / {
      flush()
      if ($0 !~ /^## Phase [0-9]+/) { print "schema: malformed phase header: " $0 > "/dev/stderr"; v=1; phase="?" }
      else phase=$3
      have_date=0; have_aa=0; n_assump=0; next
    }
    /^- date: / { if ($0 ~ /^- date: [0-9]{4}-[0-9]{2}-[0-9]{2}$/) have_date=1; else { print "schema: Phase " phase " bad date: " $0 > "/dev/stderr"; v=1 } next }
    /^- all_accept: / { if ($0 ~ /^- all_accept: (true|false)$/) have_aa=1; else { print "schema: Phase " phase " bad all_accept: " $0 > "/dev/stderr"; v=1 } next }
    /^- A[0-9]/ {
      n_assump++
      if ($0 !~ /cost: (high|medium|low)/)              { print "schema: Phase " phase " " $2 " bad/missing cost" > "/dev/stderr"; v=1 }
      if ($0 !~ /position: (accept|reject|don.t-know)/)  { print "schema: Phase " phase " " $2 " bad/missing position" > "/dev/stderr"; v=1 }
      if ($0 !~ /revisit-status:/)                       { print "schema: Phase " phase " " $2 " missing revisit-status field" > "/dev/stderr"; v=1 }
      if ($0 !~ /"[^"]+"/)                               { print "schema: Phase " phase " " $2 " missing quoted text" > "/dev/stderr"; v=1 }
      next
    }
    END { flush(); exit v }
  ' "$file"
}

# --- --revisit: flag blank revisit-status (optionally scoped to one phase). ----------------------------
check_revisit() {
  local file="$1" only="${2:-}"
  [ -f "$file" ] || { echo "revisit: file not found: $file" >&2; return 1; }
  awk -v only="$only" '
    /^## Phase / { phase=$3 }
    /^- A[0-9]/ {
      if (only!="" && phase!=only) next
      # blank = "revisit-status:" followed only by whitespace, then the next pipe or end-of-line
      if ($0 ~ /revisit-status:[[:space:]]*(\||$)/) { print "revisit: Phase " phase " " $2 " has blank revisit-status" > "/dev/stderr"; v=1 }
    }
    END { exit v }
  ' "$file"
}

# --- --gate: a phase must have a block AND >=1 assumption line (positions were taken). ------------------
check_gate() {
  local file="$1" phase="$2"
  [ -f "$file" ] || { echo "gate: file not found: $file" >&2; return 1; }
  if awk -v p="$phase" '
       $0 ~ ("^## Phase " p "([^0-9]|$)") { inblk=1; next }
       /^## Phase / { inblk=0 }
       inblk && /^- A[0-9]/ { found++ }
       END { exit (found>=1)?0:1 }
     ' "$file"; then
    return 0
  fi
  echo "gate: Phase $phase has no recorded positions (gate did not fire)" >&2
  return 1
}

# --- --append-only: no prior phase may LOSE assumption rows (truncation / row-deletion guard). ----------
# Per-block row count must be non-decreasing vs baseline. Catches both whole-block removal (count → 0)
# AND deletion of individual rows within a retained block (the subtle section-rewrite corruption the
# ledger's .dev-wiki/ location is meant to survive). The one permitted in-place edit — filling a blank
# revisit-status — does not change row count, so it is unaffected.
check_append_only() {
  local cur="$1" base="${2:-}" basetmp="" rc
  [ -f "$cur" ] || { echo "append-only: file not found: $cur" >&2; return 1; }
  if [ -z "$base" ]; then
    basetmp="$(mktemp)"
    if ( cd "$(dirname "$cur")" && git show "HEAD:./$(basename "$cur")" ) > "$basetmp" 2>/dev/null && [ -s "$basetmp" ]; then
      base="$basetmp"
    else
      rm -f "$basetmp"; return 0   # no committed baseline (first commit / untracked) → fail-open
    fi
  fi
  awk '
    FNR==NR { if ($0 ~ /^## Phase [0-9]+/) p=$3; if ($0 ~ /^- A[0-9]/ && p!="") base[p]++; next }
            { if ($0 ~ /^## Phase [0-9]+/) q=$3; if ($0 ~ /^- A[0-9]/ && q!="") cur[q]++ }
    END {
      for (ph in base) if (cur[ph] < base[ph]) {
        if (cur[ph]==0) print "append-only: prior block removed: Phase " ph > "/dev/stderr"
        else            print "append-only: Phase " ph " lost assumption rows (" base[ph] " -> " cur[ph]+0 ")" > "/dev/stderr"
        v=1
      }
      exit v
    }
  ' "$base" "$cur"
  rc=$?
  [ -n "$basetmp" ] && rm -f "$basetmp"
  return "$rc"
}

# --- default: schema + append-only hard; revisit advisory (blanks are expected mid-phase). -------------
check_default() {
  local file="$1" rc=0
  validate_schema "$file" || rc=1
  check_append_only "$file" || rc=1
  check_revisit "$file" || true   # advisory in default mode; --revisit enforces at debrief
  return "$rc"
}

# --- --selftest: build temp fixtures and assert each mode both directions. -----------------------------
selftest() {
  local d fail=0
  d="$(mktemp -d)"
  _expect() {  # <label> <expected-exit> <actual-exit>
    if [ "$2" = "$3" ]; then echo "ok: $1"; else echo "FAIL: $1 expected exit $2 got $3"; fail=1; fi
  }
  _rc() { "$@" >/dev/null 2>&1; echo $?; }

  cat > "$d/good.md" <<'EOF'
# Assumption Ledger

## Phase 80 — Screen
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "Forced verdicts engage cognition"
- A2 | cost: high | position: reject | revisit-status: held | "The agent-chosen set can be trusted"

## Phase 82 — Next
- date: 2026-06-10
- all_accept: true
- A1 | cost: medium | position: accept | revisit-status: held | "The store persists at the assumed path"
EOF
  cat > "$d/blank.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: | "The hook is firing"
EOF
  cat > "$d/nopos.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: false
EOF
  cat > "$d/missing.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: false
- A1 | cost: high | revisit-status: held | "The hook is firing"
EOF
  cat > "$d/base.md" <<'EOF'
# Assumption Ledger

## Phase 80 — Screen
- date: 2026-06-09
- all_accept: false
- A1 | cost: high | position: accept | revisit-status: held | "x"

## Phase 82 — Next
- date: 2026-06-10
- all_accept: true
- A1 | cost: medium | position: accept | revisit-status: held | "y"
EOF
  cat > "$d/trunc.md" <<'EOF'
# Assumption Ledger

## Phase 82 — Next
- date: 2026-06-10
- all_accept: true
- A1 | cost: medium | position: accept | revisit-status: held | "y"
EOF

  _expect "schema good"            0 "$(_rc validate_schema "$d/good.md")"
  _expect "schema no-positions"    1 "$(_rc validate_schema "$d/nopos.md")"
  _expect "schema missing-field"   1 "$(_rc validate_schema "$d/missing.md")"
  _expect "revisit good"           0 "$(_rc check_revisit "$d/good.md")"
  _expect "revisit blank"          1 "$(_rc check_revisit "$d/blank.md")"
  _expect "revisit blank phase-82" 1 "$(_rc check_revisit "$d/blank.md" 82)"
  _expect "gate good phase-82"     0 "$(_rc check_gate "$d/good.md" 82)"
  _expect "gate no-positions"      1 "$(_rc check_gate "$d/nopos.md" 82)"
  _expect "gate number-boundary"   1 "$(_rc check_gate "$d/good.md" 8)"
  _expect "append-only truncated"  1 "$(_rc check_append_only "$d/trunc.md" "$d/base.md")"
  _expect "append-only intact"     0 "$(_rc check_append_only "$d/good.md" "$d/base.md")"
  _expect "append-only row-loss"   1 "$(_rc check_append_only "$d/base.md" "$d/good.md")"

  rm -rf "$d"
  [ "$fail" -eq 0 ] && { echo "SELFTEST: PASS"; return 0; } || { echo "SELFTEST: FAIL"; return 1; }
}

# --- Dispatch ------------------------------------------------------------------------------------------
case "${1:---selftest}" in
  --schema)      shift; validate_schema "$@";;
  --revisit)     shift; check_revisit "$@";;
  --gate)        shift; check_gate "$@";;
  --append-only) shift; check_append_only "$@";;
  --selftest)    selftest;;
  --*)           echo "usage: check-assumption-ledger.sh --schema|--revisit|--gate|--append-only|--selftest <file> ..." >&2; exit 2;;
  *)             check_default "$1";;
esac
