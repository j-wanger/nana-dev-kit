#!/usr/bin/env bash
# residual-audit.sh — the GATE of the cross-session retention screen (Phase 77).
#
# Deterministic provenance check (NO model judge, NO fuzzy match). For each pre-registered decision
# it answers ONE question: is the decision's discriminating token already recoverable from the inputs
# a SUBSTRATE-FREE (OFF) session would have — the subject's source tree, tests, and git COMMIT MESSAGES
# — or is it carried ONLY by the dev-wiki substrate?
#
#   RECOVERABLE  — the token appears in an OFF channel ⇒ the substrate adds nothing here (degenerate).
#   RESIDUAL     — the token is ABSENT from every OFF channel ⇒ the substrate's unique cross-session
#                  payload. The residual is the ONLY set the T2/T3 OFF/ON ablation is allowed to run on.
#   EXCLUDED     — superseded/stale/unresolvable-at-HEAD (recovering a dead or reversed decision is a
#                  MISS, never headroom; adversarial constraints #8/#10).
#
# OFF CHANNELS (pinned in pre-registration.md at T2; default tree,gitmsg):
#   tree    — every file under <subject> EXCEPT the substrate (.dev-wiki/.claude/AGENTS.md), .git,
#             __pycache__, and binary/data blobs. This is the code + tests an OFF session reads.
#   gitmsg  — `git log` commit-message BODIES (decision-rich here, and themselves partly a harness
#             product — see screen-record's git-log-as-channel caveat). NOTE: `git log -p` is
#             DELIBERATELY EXCLUDED — the substrate is in git HISTORY, so -p diffs would resurrect the
#             very substrate the OFF condition strips, manufacturing a false-empty residual.
#
# Token list (TSV, '#'/blank lines ignored):  <slug>\t<token>\t<kind>\t<status>
#   slug    — decision identifier (its article must resolve at HEAD, else auto-EXCLUDED stale)
#   token   — the discriminating string (the value/clause that distinguishes the CHOSEN path from the
#             rejected one), grepped fixed-string + case-insensitive. Curated to the TERMINAL value.
#   kind    — fact | negative | process   (recorded, not scored — for the record's readability)
#   status  — live | superseded | stale   (superseded/stale ⇒ EXCLUDED)
#
# Modes:
#   residual-audit.sh --tokens <tsv> --subject <path> [--channels tree,gitmsg] [--out residual.md]
#   residual-audit.sh --selftest    → exits 0 iff the planted both-ways control pair classifies correctly
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLOOR=3                                   # eligible-item floor, pinned (see spec / pre-registration.md)
SUBSTRATE_PATHS=".dev-wiki .claude AGENTS.md"   # stripped from the OFF corpus (the substrate under test)

CORP_TREE=""; CORP_GITMSG=""              # temp corpus files, set by assemble_corpus
# return 0 explicitly: a bare `[ -n "" ] && rm` short-circuits to status 1, which under `set -e`
# would kill the script (the temps are empty after an audit() command-substitution subshell).
_cleanup() { [ -n "$CORP_TREE" ] && rm -f "$CORP_TREE"; [ -n "$CORP_GITMSG" ] && rm -f "$CORP_GITMSG"; return 0; }
trap _cleanup EXIT

# Assemble the OFF corpus ONCE for a subject, into CORP_TREE and CORP_GITMSG temp files.
assemble_corpus() {  # <subject> <channels-csv>
  local subject="$1" channels="$2"
  CORP_TREE="$(mktemp)"; CORP_GITMSG="$(mktemp)"
  if printf '%s' ",$channels," | grep -q ',tree,'; then
    # text files only; substrate + vcs + build + binary/data blobs excluded
    # binary/data/cache blobs are EXCLUDED per the pre-registered OFF-corpus spec (a NUL-containing
    # corpus makes grep treat the whole temp as binary; excluding caches keeps it clean text).
    find "$subject" -type f \
      -not -path '*/.git/*' -not -path '*/.dev-wiki/*' -not -path '*/.claude/*' \
      -not -path '*/__pycache__/*' -not -path '*/.venv/*' -not -path '*/node_modules/*' \
      -not -path '*/.mypy_cache/*' -not -path '*/.pytest_cache/*' -not -path '*/.ruff_cache/*' \
      -not -path '*/.hypothesis/*' \
      -not -name 'AGENTS.md' -not -name '.coverage' -not -name '.coverage.*' \
      -not -name '*.pyc' -not -name '*.parquet' -not -name '*.feather' -not -name '*.pkl' \
      -not -name '*.csv' -not -name '*.csv.gz' -not -name '*.gz' -not -name '*.zip' \
      -not -name '*.db' -not -name '*.png' -not -name '*.jpg' -not -name '*.pdf' -print0 2>/dev/null \
      | xargs -0 cat >> "$CORP_TREE" 2>/dev/null || true
  fi
  if printf '%s' ",$channels," | grep -q ',gitmsg,'; then
    if [ -d "$subject/.git" ] || git -C "$subject" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$subject" log --format='%B' >> "$CORP_GITMSG" 2>/dev/null || true
    fi
  fi
}

# Is <slug>'s decision article present at HEAD of <subject>?  (HEAD-resolvability guard, adversarial #10)
slug_resolves() {  # <subject> <slug>
  local subject="$1" slug="$2"
  [ -f "$subject/.dev-wiki/articles/decisions/$slug.md" ]
}

# Classify a single token against the already-assembled corpus.
classify_token() {  # <subject> <slug> <token> <status>  → echoes RECOVERABLE:<ch> | RESIDUAL | EXCLUDED:<why>
  local subject="$1" slug="$2" token="$3" status="$4"
  case "$status" in
    superseded) echo "EXCLUDED:superseded"; return 0;;
    stale)      echo "EXCLUDED:stale";      return 0;;
  esac
  if ! slug_resolves "$subject" "$slug"; then echo "EXCLUDED:unresolved-at-HEAD"; return 0; fi
  # -a: treat the corpus as text even if a stray NUL survives the binary/cache exclusions above.
  if [ -s "$CORP_TREE" ]   && LC_ALL=C grep -a -F -i -q -- "$token" "$CORP_TREE";   then echo "RECOVERABLE:tree";   return 0; fi
  if [ -s "$CORP_GITMSG" ] && LC_ALL=C grep -a -F -i -q -- "$token" "$CORP_GITMSG"; then echo "RECOVERABLE:gitmsg"; return 0; fi
  echo "RESIDUAL"
}

audit() {  # <tokens-tsv> <subject> <channels> <out>
  local tokens="$1" subject="$2" channels="$3" out="$4"
  [ -f "$tokens" ] || { echo "residual-audit: token list not found: $tokens" >&2; return 2; }
  [ -d "$subject" ] || { echo "residual-audit: subject not found: $subject" >&2; return 2; }
  assemble_corpus "$subject" "$channels"

  local rows="" residual=0 recoverable=0 excluded=0 slug token kind status cls
  while IFS=$'\t' read -r slug token kind status; do
    case "${slug:-}" in ''|\#*) continue;; esac
    : "${status:=live}"; : "${kind:=fact}"
    cls="$(classify_token "$subject" "$slug" "$token" "$status")"
    case "$cls" in
      RESIDUAL)      residual=$((residual+1));;
      RECOVERABLE:*) recoverable=$((recoverable+1));;
      EXCLUDED:*)    excluded=$((excluded+1));;
    esac
    rows="${rows}| ${slug} | ${kind} | \`${token}\` | ${cls} |
"
  done < "$tokens"

  local gate
  if   [ "$residual" -ge "$FLOOR" ]; then gate="PROCEED  (residual ${residual} >= floor ${FLOOR} → run T2/T3 ablation on the residual)"
  elif [ "$residual" -eq 0 ];       then gate="HALT-TERMINATE  (residual 0 → PROGRAM-VERDICT TERMINATE; no OFF/ON run)"
  else                                   gate="HALT-INCONCLUSIVE  (0 < residual ${residual} < floor ${FLOOR} → INCONCLUSIVE; n=1/2 lucky-draw guard)"
  fi

  {
    echo "# Cross-Session Residual Audit (Phase 77 — T1/T2 gate)"
    echo
    echo "- subject: \`${subject}\`"
    echo "- channels: ${channels}  (OFF corpus = code + tests + git commit MESSAGES; \`git log -p\` excluded)"
    echo "- generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "- floor: ${FLOOR} distinct residual decisions"
    echo
    echo "## Per-decision provenance"
    echo
    echo "| slug | kind | discriminating token | classification |"
    echo "|---|---|---|---|"
    printf '%s' "$rows"
    echo
    echo "## Summary"
    echo
    echo "recoverable: ${recoverable}   excluded: ${excluded}   **RESIDUAL-COUNT: ${residual}**"
    echo
    echo "GATE: ${gate}"
  } > "$out"

  echo "RESIDUAL-COUNT: ${residual}"
  echo "GATE: ${gate%% *}"
}

# ---- selftest: planted fixtures, both-ways control pair + substrate-strip + superseded + gitmsg ----
selftest() {
  local fail=0 fx gx tok out summ
  _ck() { if [ "$2" = "$3" ]; then echo "ok: $1 → $3"; else echo "FAIL: $1 expected [$2] got [$3]"; fail=1; fi; }

  fx="$(mktemp -d)"
  mkdir -p "$fx/src" "$fx/tests" "$fx/.dev-wiki/articles/decisions"
  printf 'def f():\n    return "PRESENT_IN_CODE_marker"\n' > "$fx/src/foo.py"            # code = OFF channel
  printf 'project AGENTS file: ONLY_IN_AGENTS_marker\n'   > "$fx/AGENTS.md"             # substrate → stripped
  printf 'decision: ONLY_IN_SUBSTRATE_marker chosen\n'    > "$fx/.dev-wiki/articles/decisions/d_substrate.md"  # substrate → stripped
  # HEAD-resolvability: each scored slug needs its article present; d_unresolved deliberately has none.
  for s in d_present d_absent d_agents d_dead; do printf 'article\n' > "$fx/.dev-wiki/articles/decisions/$s.md"; done

  tok="$(mktemp)"   # token list lives OUTSIDE the subject tree (else it self-pollutes the OFF corpus)
  {
    printf 'd_present\tPRESENT_IN_CODE\tfact\tlive\n'        # in code              → RECOVERABLE:tree
    printf 'd_absent\tABSENT_TOKEN_XQ7\tnegative\tlive\n'    # nowhere              → RESIDUAL
    printf 'd_substrate\tONLY_IN_SUBSTRATE\tprocess\tlive\n' # only in .dev-wiki    → RESIDUAL (stripped)
    printf 'd_agents\tONLY_IN_AGENTS\tfact\tlive\n'          # only in AGENTS.md    → RESIDUAL (stripped)
    printf 'd_dead\tPRESENT_IN_CODE\tfact\tsuperseded\n'     # superseded           → EXCLUDED
    printf 'd_unresolved\tWHATEVER\tfact\tlive\n'            # no article           → EXCLUDED:unresolved-at-HEAD
  } > "$tok"

  assemble_corpus "$fx" "tree"
  _ck "present-in-code recoverable" "RECOVERABLE:tree"            "$(classify_token "$fx" d_present   PRESENT_IN_CODE   live)"
  _ck "absent survives"             "RESIDUAL"                    "$(classify_token "$fx" d_absent    ABSENT_TOKEN_XQ7  live)"
  _ck "substrate-only survives"     "RESIDUAL"                    "$(classify_token "$fx" d_substrate ONLY_IN_SUBSTRATE live)"
  _ck "agents-only survives"        "RESIDUAL"                    "$(classify_token "$fx" d_agents    ONLY_IN_AGENTS    live)"
  _ck "superseded excluded"         "EXCLUDED:superseded"         "$(classify_token "$fx" d_dead      PRESENT_IN_CODE   superseded)"
  _ck "unresolved excluded"         "EXCLUDED:unresolved-at-HEAD" "$(classify_token "$fx" d_unresolved WHATEVER         live)"
  _cleanup; CORP_TREE=""; CORP_GITMSG=""

  # end-to-end audit(): 3 residual (absent + substrate + agents), 1 recoverable, 2 excluded → count 3, PROCEED
  out="$(mktemp)"
  summ="$(audit "$tok" "$fx" "tree" "$out")"
  _ck "audit residual-count" "RESIDUAL-COUNT: 3"  "$(printf '%s\n' "$summ" | grep '^RESIDUAL-COUNT:')"
  _ck "audit gate"           "GATE: PROCEED"      "$(printf '%s\n' "$summ" | grep '^GATE:')"
  _cleanup; CORP_TREE=""; CORP_GITMSG=""

  # gitmsg channel: a token present ONLY in a commit MESSAGE must be RECOVERABLE:gitmsg, and RESIDUAL
  # when the gitmsg channel is gated off (proves channel selection actually gates).
  gx="$(mktemp -d)"
  mkdir -p "$gx/.dev-wiki/articles/decisions"; printf 'a\n' > "$gx/.dev-wiki/articles/decisions/d_msg.md"
  ( cd "$gx" && git init -q && git config user.email t@t && git config user.name t \
      && printf 'code without the token\n' > f.py && git add -A \
      && git commit -q -m "feat: chose GITMSG_ONLY_TOKEN over the rejected path" ) >/dev/null 2>&1
  assemble_corpus "$gx" "tree,gitmsg"
  _ck "gitmsg-only recoverable"   "RECOVERABLE:gitmsg" "$(classify_token "$gx" d_msg GITMSG_ONLY_TOKEN live)"
  _cleanup; CORP_TREE=""; CORP_GITMSG=""
  assemble_corpus "$gx" "tree"
  _ck "gitmsg-gated-off survives" "RESIDUAL"           "$(classify_token "$gx" d_msg GITMSG_ONLY_TOKEN live)"
  _cleanup; CORP_TREE=""; CORP_GITMSG=""

  rm -rf "$fx" "$gx"; rm -f "$tok" "$out"
  [ "$fail" -eq 0 ] && { echo "SELFTEST: PASS"; return 0; } || { echo "SELFTEST: FAIL"; return 1; }
}

# ---- arg parsing ----
TOKENS=""; SUBJECT="/Users/jwang/edge-screener"; CHANNELS="tree,gitmsg"; OUT="$DIR/residual.md"
case "${1:---help}" in
  --selftest) selftest; exit $?;;
  --help|-h)  sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --tokens)   TOKENS="$2"; shift 2;;
    --subject)  SUBJECT="$2"; shift 2;;
    --channels) CHANNELS="$2"; shift 2;;
    --out)      OUT="$2"; shift 2;;
    *) echo "residual-audit: unknown arg: $1" >&2; exit 2;;
  esac
done
[ -n "$TOKENS" ] || { echo "residual-audit: --tokens <tsv> required (or --selftest)" >&2; exit 2; }
audit "$TOKENS" "$SUBJECT" "$CHANNELS" "$OUT"
