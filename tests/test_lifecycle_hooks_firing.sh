#!/usr/bin/env bash
# Phase 84 — firing tests for the two dormant lifecycle hooks, anchored on REAL captured events
# (tests/fixtures/real-events/, byte-for-byte; see capture-diagnosis.md). Branches per T2:
#   post-commit.sh  = redesign — PostToolUse fires ONLY on successful tool calls (live-probe
#                     finding), so event arrival is the success signal; legacy top-level
#                     .exit_code retained as a guard; textual prefilter + git-state recency
#                     confirmation rejects mention-only / failed-compound false positives.
#   detect-loop.sh  = upstream — no failure signal exists on the platform (no exit code in the
#                     event, no event on failure); hook untouched; legacy-shape path is
#                     non-regression surface only.
# Assertions check ARTIFACT CONTENT (.pending-commit hash/JSON, trigger text), never exit codes
# alone. All sandboxes are mktemp -d with HOME + CLAUDE_PROJECT_DIR overridden (HEU-012).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS="$REPO_ROOT/templates/.claude/hooks"
FIXTURES="$REPO_ROOT/tests/fixtures/real-events"

SANDBOXES=()
cleanup() { for d in "${SANDBOXES[@]}"; do rm -rf "$d" 2>/dev/null || true; done; }
trap cleanup EXIT

# sandbox <marker-mode: project|home|both|none> <commit-age: fresh|old|none>
# Builds an isolated project dir + HOME; echoes "<proj>|<home>".
sandbox() {
  local marker="$1" age="$2" proj home
  proj=$(mktemp -d); home=$(mktemp -d)
  SANDBOXES+=("$proj" "$home")
  mkdir -p "$proj/.dev-wiki" "$proj/.claude" "$home/.claude"
  case "$marker" in
    project) touch "$proj/.claude/enforce" ;;
    home)    touch "$home/.claude/enforce" ;;
    both)    touch "$proj/.claude/enforce" "$home/.claude/enforce" ;;
    none)    ;;
  esac
  if [ "$age" != "none" ]; then
    git -C "$proj" init -q
    echo x > "$proj/f.txt"
    git -C "$proj" add f.txt
    if [ "$age" = "old" ]; then
      GIT_COMMITTER_DATE="2020-01-01T00:00:00" GIT_AUTHOR_DATE="2020-01-01T00:00:00" \
        git -C "$proj" -c user.email=a@b.c -c user.name=t commit -q -m "old commit"
    else
      git -C "$proj" -c user.email=a@b.c -c user.name=t commit -q -m "fresh commit"
    fi
  fi
  echo "$proj|$home"
}

# fire <hook> <proj> <home> <json> [cpd: set|unset] -> stdout in $OUT, stderr in $ERR, exit in $EC
fire() {
  local hook="$1" proj="$2" home="$3" json="$4" cpd="${5:-set}"
  local outf errf; outf=$(mktemp); errf=$(mktemp); SANDBOXES+=("$outf" "$errf")
  EC=0
  if [ "$cpd" = "set" ]; then
    printf '%s' "$json" | HOME="$home" CLAUDE_PROJECT_DIR="$proj" bash "$HOOKS/$hook" >"$outf" 2>"$errf" || EC=$?
  else
    printf '%s' "$json" | HOME="$home" bash -c "cd '$proj' && env -u CLAUDE_PROJECT_DIR bash '$HOOKS/$hook'" >"$outf" 2>"$errf" || EC=$?
  fi
  OUT=$(cat "$outf"); ERR=$(cat "$errf")
}

REAL_COMMIT_EVENT=$(cat "$FIXTURES/post-commit-git-commit.json")
REAL_SUCCESS_EVENT=$(cat "$FIXTURES/detect-loop-success-event.json")

echo "=== Phase 84 Lifecycle Hook Firing Tests ==="

# ---- post-commit: REAL captured event (flag-interleaved `git -c … commit`) must fire ----
test_start "post-commit fires on the real captured commit event"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT"
WANT=$(git -C "$P" rev-parse HEAD)
if [ -f "$P/.dev-wiki/.pending-commit" ] && jq -e --arg h "$WANT" '.hash == $h' "$P/.dev-wiki/.pending-commit" >/dev/null 2>&1 \
   && echo "$OUT" | grep -q '\[dev-wiki:post-commit\]'; then
  test_pass
else
  test_fail "no marker/trigger (ec=$EC out=$OUT err=$ERR)"
fi

# ---- marker 4-matrix ----
test_start "marker matrix: CPD set + project-local marker fires"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT"
[ -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "project-local marker ignored (the line-56 defect)"

test_start "marker matrix: CPD set + HOME marker fires"
IFS='|' read -r P H <<< "$(sandbox home fresh)"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT"
[ -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "HOME marker path broken"

test_start "marker matrix: CPD unset + project-local marker fires (:-. fallback)"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT" unset
[ -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "unset-CPD + project marker broken"

test_start "marker matrix: CPD unset + HOME marker fires"
IFS='|' read -r P H <<< "$(sandbox home fresh)"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT" unset
[ -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "unset-CPD + HOME marker broken"

test_start "marker matrix: no marker anywhere stays silent (allow path)"
IFS='|' read -r P H <<< "$(sandbox none fresh)"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT"
if [ ! -f "$P/.dev-wiki/.pending-commit" ] && [ -z "$OUT" ] && [ "$EC" = "0" ]; then test_pass; else test_fail "fired without opt-in marker"; fi

# ---- false-positive guards (textual prefilter + git-state confirmation) ----
test_start "mention-only command does not fire (echo \"git commit\", old HEAD)"
IFS='|' read -r P H <<< "$(sandbox project old)"
fire post-commit.sh "$P" "$H" '{"tool_name":"Bash","tool_input":{"command":"echo \"git commit\""},"tool_response":{"stdout":"git commit\n","stderr":"","interrupted":false,"isImage":false}}'
[ ! -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "mention-only command wrote a marker"

test_start "failed compound commit does not fire (git commit || true, old HEAD)"
IFS='|' read -r P H <<< "$(sandbox project old)"
fire post-commit.sh "$P" "$H" '{"tool_name":"Bash","tool_input":{"command":"git commit -m nothing || true"},"tool_response":{"stdout":"","stderr":"nothing to commit","interrupted":false,"isImage":false}}'
[ ! -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "failed compound commit wrote a marker"

test_start "amend is skipped (not new work)"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" '{"tool_name":"Bash","tool_input":{"command":"git commit --amend --no-edit"},"tool_response":{"stdout":"","stderr":"","interrupted":false,"isImage":false}}'
[ ! -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "amend wrote a marker"

test_start "embedded quotes parse cleanly and fire (jq path, fresh HEAD)"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" '{"tool_name":"Bash","tool_input":{"command":"git commit -m \"say \\\"hi\\\" loudly\""},"tool_response":{"stdout":"","stderr":"","interrupted":false,"isImage":false}}'
[ -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "embedded-quote command did not fire (ec=$EC err=$ERR)"

test_start "non-dev-wiki project stays silent (machine-wide wake guard)"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
rm -rf "$P/.dev-wiki"
fire post-commit.sh "$P" "$H" "$REAL_COMMIT_EVENT"
if [ ! -e "$P/.dev-wiki/.pending-commit" ] && [ -z "$OUT" ]; then test_pass; else test_fail "fired in a non-dev-wiki project"; fi

# ---- legacy fallback retained (eval-corpus denominator stability) ----
test_start "legacy shape with exit_code 0 still fires"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" '{"tool_input":{"command":"git commit -m test"},"exit_code":0}'
[ -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "legacy success event no longer fires"

test_start "legacy shape with exit_code 1 is rejected (legacy failure guard)"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" '{"tool_input":{"command":"git commit -m test"},"exit_code":1}'
[ ! -f "$P/.dev-wiki/.pending-commit" ] && test_pass || test_fail "legacy FAILED commit wrote a marker"

# ---- HEU-002 fail-loud: signal absence is logged, not swallowed ----
test_start "command-less event logs signal-absence to stderr (fail-loud)"
IFS='|' read -r P H <<< "$(sandbox project fresh)"
fire post-commit.sh "$P" "$H" '{"tool_name":"Bash","tool_response":{"stdout":"","stderr":"","interrupted":false,"isImage":false}}'
if [ "$EC" = "0" ] && echo "$ERR" | grep -q 'nana:post-commit'; then test_pass; else test_fail "signal absence silently swallowed (err=$ERR)"; fi

# ---- detect-loop (upstream branch): real event must not crash; legacy path non-regression ----
test_start "detect-loop: real success event exits 0 silently (no crash on real shape)"
IFS='|' read -r P H <<< "$(sandbox home fresh)"
fire detect-loop.sh "$P" "$H" "$REAL_SUCCESS_EVENT"
if [ "$EC" = "0" ] && [ -z "$OUT" ]; then test_pass; else test_fail "crashed or warned on a real success event (ec=$EC out=$OUT)"; fi

test_start "detect-loop: legacy 3-failure path still warns (non-regression)"
IFS='|' read -r P H <<< "$(sandbox home none)"
LEGACY='{"tool_input":{"command":"badcmd"},"exit_code":1}'
fire detect-loop.sh "$P" "$H" "$LEGACY"
fire detect-loop.sh "$P" "$H" "$LEGACY"
fire detect-loop.sh "$P" "$H" "$LEGACY"
if echo "$OUT" | grep -q '\[nana:loop\]'; then test_pass; else test_fail "legacy loop warning regressed (out=$OUT)"; fi

test_summary "lifecycle-hooks-firing"
