#!/usr/bin/env bash
# Phase 89 — window-events attestation checker (exit criterion c7).
# Asserts evidence/window-events.md: (1) carries BOTH verbatim trigger texts, extracted at
# runtime from pre-registration.md's quoted "Trigger: ..." strings (whitespace-normalized
# match — the checker can never drift from the pinned text); (2) has a Phase 89 H2 section;
# (3) attestation completeness — every "### Session <n>" id in evidence/sessions.md (row id
# pinned as session-<n> or <n>) plus every id on the "kit-side sessions:" manifest line
# (exact field match) has one row per window (ak AND wk); (4) every row whose event is not
# "none" carries a "filed" marker. Zero events across all rows is a VALID outcome.
# --selftest: seeded fixtures under checker-fixtures/evidence-*/ against the REAL
# pre-registration.md; clean-on-seed = instrument-dead.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIX="$SCRIPT_DIR/checker-fixtures"

extract_triggers() { # $1 = pre-registration.md -> one normalized trigger text per line
  awk '
    function t(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s}
    !inq && /"Trigger:/ { s=$0; sub(/^.*"Trigger:/,"Trigger:",s)
      if (s ~ /"/) { sub(/".*/,"",s); print t(s) } else { buf=t(s); inq=1 }; next }
    inq { s=$0
      if (s ~ /"/) { sub(/".*/,"",s); buf=buf " " t(s); print buf; inq=0 }
      else buf=buf " " t(s) }
  ' "$1"
}

normalize() { tr '\n' ' ' < "$1" | tr -s '[:space:]' ' '; }

has_row() { # $1=window-events $2=id pattern $3=window(ak|wk) $4=mode(re|exact)
  awk -F'|' -v p="$2" -v w="$3" -v m="$4" '
    function t(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s}
    /^\|/ { if (t($4)==w && ((m=="re" && t($3) ~ p) || (m=="exact" && t($3)==p))) ok=1 }
    END{exit ok?0:1}' "$1"
}

check_filed() { # $1=window-events — every non-"none" event row must say filed
  awk -F'|' '
    function t(s){gsub(/^[[:space:]]+|[[:space:]]+$/,"",s); return s}
    /^\|/ { w=t($4); e=t($7)
      if ((w=="ak"||w=="wk") && e!="" && e !~ /^none/ && e !~ /filed/) bad=1 }
    END{exit bad?1:0}' "$1"
}

check_window() { # $1=window-events.md $2=sessions.md $3=pre-registration.md
  local wf="$1" sf="$2" pf="$3" v=0 norm trig ntrig=0 n id kitline ids
  [ -f "$wf" ] || { echo "FAIL: $wf missing" >&2; return 1; }
  norm=$(normalize "$wf")
  while IFS= read -r trig; do
    ntrig=$((ntrig+1))
    grep -qF "$trig" <<<"$norm" \
      || { echo "FAIL: verbatim trigger text absent: $trig" >&2; v=1; }
  done < <(extract_triggers "$pf")
  [ "$ntrig" -ge 2 ] || { echo "FAIL: extracted $ntrig trigger(s) from $pf (need 2)" >&2; v=1; }
  grep -qE '^## .*Phase 89' "$wf" || { echo "FAIL: no Phase 89 H2 section" >&2; v=1; }
  kitline=$(grep -m1 '^kit-side sessions:' "$wf" || true)
  [ -n "$kitline" ] || { echo "FAIL: 'kit-side sessions:' manifest line absent" >&2; v=1; }
  if [ -f "$sf" ]; then
    while IFS= read -r n; do
      [ -n "$n" ] || continue
      for w in ak wk; do
        has_row "$wf" "^(session-)?${n}\$" "$w" re \
          || { echo "FAIL: Session $n unattested for window $w" >&2; v=1; }
      done
    done < <(grep -E '^### Session [0-9]+' "$sf" | sed -E 's/^### Session ([0-9]+).*/\1/')
  else
    echo "FAIL: $sf missing (cannot enumerate session universe)" >&2; v=1
  fi
  ids=$(sed -E 's/^kit-side sessions: *//; s/,/ /g' <<<"$kitline")
  read -ra kit_ids <<< "$ids"
  for id in ${kit_ids[@]+"${kit_ids[@]}"}; do
    [ "$id" = "none" ] && continue
    for w in ak wk; do
      has_row "$wf" "$id" "$w" exact \
        || { echo "FAIL: kit-side session $id unattested for window $w" >&2; v=1; }
    done
  done
  check_filed "$wf" || { echo "FAIL: trigger-event row(s) lack the filed marker" >&2; v=1; }
  return "$v"
}

selftest() {
  local pass=0 fail=0 fx
  [ "$(extract_triggers "$SCRIPT_DIR/pre-registration.md" | wc -l | tr -d ' ')" = "2" ] \
    && pass=$((pass+1)) || { echo "SELFTEST FAIL: trigger extraction != 2 from real pre-registration" >&2; fail=1; }
  if check_window "$FIX/evidence-valid/window-events.md" "$FIX/evidence-valid/sessions.md" \
      "$SCRIPT_DIR/pre-registration.md" >/dev/null 2>&1; then pass=$((pass+1))
  else echo "SELFTEST FAIL: valid window-events fixture rejected" >&2; fail=1; fi
  for fx in window-events-unattested window-events-unfiled window-events-missing-trigger; do
    if check_window "$FIX/evidence-malformed/$fx.md" "$FIX/evidence-valid/sessions.md" \
        "$SCRIPT_DIR/pre-registration.md" >/dev/null 2>&1; then
      echo "SELFTEST FAIL: $fx accepted (instrument-dead)" >&2; fail=1
    else pass=$((pass+1)); fi
  done
  [ "$fail" -eq 0 ] && echo "SELFTEST PASS ($pass/5 controls)" || { echo "SELFTEST FAIL" >&2; exit 1; }
}

if [ "${1:-}" = "--selftest" ]; then selftest; exit 0; fi
if check_window "${1:-$SCRIPT_DIR/evidence/window-events.md}" \
    "${2:-$SCRIPT_DIR/evidence/sessions.md}" "$SCRIPT_DIR/pre-registration.md"; then
  echo "WINDOW-EVENTS: PASS"
else
  echo "WINDOW-EVENTS: FAIL" >&2; exit 1
fi
