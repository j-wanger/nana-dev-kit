#!/usr/bin/env bash
# leak-check.sh — assert every frozen OFF prompt is clean (cross-boundary retention screen, Phase 71).
#
# Two guards, both deterministic (no model judge):
#   (a) GLOBAL answer-method vocab (leak-vocab.txt) — an OFF prompt must not smuggle the very method/cue
#       a harness rule would inject (e.g. "check for structuring"); that manufactures a false DEGENERATE.
#   (b) PER-ITEM target-decision vocab (checks/<item>.offleak) — the OFF residual must not restate the
#       counter-default decision it is supposed to have DROPPED; otherwise OFF cannot fail and HAS-HEADROOM
#       is impossible (the residual-leak confound). One token per line; blanks/#-comments ignored.
#
# ONLY *-off.txt prompts are scanned. *-on.txt INTENTIONALLY carry the decision in the [HARNESS STATE]
# block — scanning them would false-positive. Exits 0 iff every OFF prompt is clean.
#
#   leak-check.sh            → scans this screen's prompts/  (default; used at T2/T5)
#   leak-check.sh --selftest → plants clean + global-leak + decision-leak OFF fixtures, asserts detection
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_VOCAB="$DIR/leak-vocab.txt"
[ -f "$GLOBAL_VOCAB" ] || { echo "leak-check: leak-vocab.txt absent" >&2; exit 1; }

# Scan one OFF prompt against the global vocab + its per-item offleak (in <checksdir>). Echoes LEAK
# lines to stderr; returns 1 on any leak. <checksdir> lets --selftest point at a planted tmp tree.
scan_off() {  # <off-prompt> <checksdir>
  local p="$1" checksdir="$2" rc=0 term base item itemleak
  base="$(basename "$p")"; item="${base%-off.txt}"
  while IFS= read -r term; do
    case "${term:-}" in ''|\#*) continue;; esac
    if grep -iqF -- "$term" "$p"; then
      echo "LEAK(global): $base contains forbidden answer-cue '$term'" >&2; rc=1
    fi
  done < "$GLOBAL_VOCAB"
  itemleak="$checksdir/$item.offleak"
  if [ -f "$itemleak" ]; then
    while IFS= read -r term; do
      case "${term:-}" in ''|\#*) continue;; esac
      if grep -iqF -- "$term" "$p"; then
        echo "LEAK(decision): $base restates its own dropped decision token '$term'" >&2; rc=1
      fi
    done < "$itemleak"
  fi
  return "$rc"
}

# Scan all *-off.txt under <promptsdir>, resolving per-item offleak from <checksdir>.
scan_tree() {  # <promptsdir> <checksdir>
  local pdir="$1" checksdir="$2" rc=0 n=0 p
  [ -d "$pdir" ] || { echo "leak-check: no prompts dir $pdir" >&2; return 1; }
  for p in "$pdir"/*-off.txt; do
    [ -e "$p" ] || continue
    n=$((n+1))
    scan_off "$p" "$checksdir" || rc=1
  done
  [ "$n" -gt 0 ] || { echo "leak-check: no *-off.txt prompts in $pdir" >&2; return 1; }
  [ "$rc" -eq 0 ] && echo "leak-check: OK ($n OFF prompts clean)"
  return "$rc"
}

selftest() {
  local t fail=0
  t="$(mktemp -d)"; trap 'rm -rf "$t"' RETURN
  mkdir -p "$t/prompts" "$t/checks"
  # clean OFF (poses the task, no method cue, does not restate the decision)
  printf 'A customer makes several cash deposits over a week. Assess whether this warrants escalation.\n' > "$t/prompts/clean-off.txt"
  # global-leak OFF (smuggles answer-method cues that live in the real leak-vocab.txt)
  printf 'Check this for structuring and file a suspicious activity report.\n' > "$t/prompts/leakg-off.txt"
  # decision-leak OFF (restates its own dropped decision token)
  printf 'The alert threshold here is 8000 euros. Proceed.\n' > "$t/prompts/leakd-off.txt"
  printf '8000 euros\n' > "$t/checks/leakd.offleak"

  # clean alone must pass
  mkdir -p "$t/prompts.clean"; cp "$t/prompts/clean-off.txt" "$t/prompts.clean/"
  if scan_tree "$t/prompts.clean" "$t/checks" >/dev/null 2>&1; then echo "ok: clean OFF passes"; else echo "FAIL: clean OFF flagged"; fail=1; fi
  # global leak must be caught
  mkdir -p "$t/p.g"; cp "$t/prompts/leakg-off.txt" "$t/p.g/"
  if scan_tree "$t/p.g" "$t/checks" >/dev/null 2>&1; then echo "FAIL: global leak NOT caught"; fail=1; else echo "ok: global leak caught"; fi
  # decision leak must be caught
  mkdir -p "$t/p.d"; cp "$t/prompts/leakd-off.txt" "$t/p.d/"
  if scan_tree "$t/p.d" "$t/checks" >/dev/null 2>&1; then echo "FAIL: decision leak NOT caught"; fail=1; else echo "ok: decision leak caught"; fi
  [ "$fail" -eq 0 ] && { echo "LEAK-SELFTEST: PASS"; return 0; } || { echo "LEAK-SELFTEST: FAIL"; return 1; }
}

case "${1:-}" in
  --selftest) selftest;;
  "")         scan_tree "$DIR/prompts" "$DIR/checks";;
  *)          echo "usage: leak-check.sh [--selftest]" >&2; exit 2;;
esac
