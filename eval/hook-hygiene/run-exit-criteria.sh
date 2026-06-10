#!/usr/bin/env bash
# Phase 84 — machine-checkable exit-criteria aggregator (spec: specs/phase-84-hook-registration-hygiene.md).
# Criteria 3-5 carry the spec's N/A-upstream pass rule: a hook whose T2 branch verdict is
# `upstream` (capture-diagnosis.md) has no in-script fix by design — its pinned repro is
# expected dormant and the criterion passes as N/A-upstream, never silently.
set -uo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"
DIAG=eval/hook-hygiene/capture-diagnosis.md
PASS=0; TOTAL=10
ok()  { PASS=$((PASS+1)); printf '  %d. PASS %s\n' "$1" "$2"; }
bad() { printf '  %d. FAIL %s\n' "$1" "$2"; }

branch_of() { awk -v h="$1" '$0 ~ "^hook: "h {f=1} f && /^branch: /{print $2; exit}' "$DIAG" 2>/dev/null; }

echo "=== Phase 84 Exit Criteria ==="

# 1. make test green
if make test >/dev/null 2>&1; then ok 1 "make test green"; else bad 1 "make test"; fi

# 2. make eval green + eval-diff explains flips
EVAL_OUT=$(make eval 2>&1 | tail -1)
if echo "$EVAL_OUT" | grep -q '52/52' && grep -q '## Baseline' eval/hook-hygiene/eval-diff.md && grep -q '## Post-fix diff' eval/hook-hygiene/eval-diff.md; then
  ok 2 "make eval $EVAL_OUT + eval-diff baseline & post-fix sections"
else bad 2 "eval=$EVAL_OUT or eval-diff sections missing"; fi

# 3. pinned line-48 repro (post-commit, real shape) — N/A-upstream rule
B=$(branch_of "post-commit.sh")
if [ "$B" = "upstream" ]; then ok 3 "N/A-upstream (post-commit)"; else
  T=$(mktemp -d) && mkdir -p "$T/h/.claude" && touch "$T/h/.claude/enforce" && cd "$T" && git init -q && git -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m test && mkdir .dev-wiki && printf '{"tool_name":"Bash","tool_input":{"command":"git commit -m test"},"tool_response":{"stdout":"done","stderr":""}}' | HOME="$T/h" CLAUDE_PROJECT_DIR="$T" bash "$REPO/templates/.claude/hooks/post-commit.sh" >/dev/null 2>&1; test -f "$T/.dev-wiki/.pending-commit"; RC=$?; cd "$REPO"; rm -rf "$T"
  if [ "$RC" = 0 ]; then ok 3 "line-48 repro (real-shape dormancy) fixed"; else bad 3 "line-48 repro still dormant"; fi
fi

# 4. pinned line-52 repro (detect-loop) — N/A-upstream rule
B=$(branch_of "detect-loop.sh")
if [ "$B" = "upstream" ]; then ok 4 "N/A-upstream (detect-loop: no failure signal on platform — filed)"; else
  T=$(mktemp -d) && mkdir -p "$T/h/.claude" "$T/.claude" && touch "$T/h/.claude/enforce" && cd "$T" && OUT=$(for i in 1 2 3; do printf '{"tool_name":"Bash","tool_input":{"command":"badcmd"},"tool_response":{"stdout":"","stderr":"boom"}}' | HOME="$T/h" CLAUDE_PROJECT_DIR="$T" bash "$REPO/templates/.claude/hooks/detect-loop.sh"; done); cd "$REPO"; rm -rf "$T"
  if [ -n "$OUT" ]; then ok 4 "line-52 repro fixed"; else bad 4 "line-52 repro still dormant"; fi
fi

# 5. pinned line-56 repro (project-local marker) — applies to the fixed hook (post-commit)
B=$(branch_of "post-commit.sh")
if [ "$B" = "upstream" ]; then ok 5 "N/A-upstream (post-commit)"; else
  T=$(mktemp -d) && mkdir -p "$T/h/.claude" "$T/.claude" "$T/.dev-wiki" && touch "$T/.claude/enforce" && cd "$T" && git init -q && git -c user.email=a@b.c -c user.name=t commit -q --allow-empty -m test && printf '{"tool_input":{"command":"git commit -m test"},"exit_code":0}' | HOME="$T/h" CLAUDE_PROJECT_DIR="$T" bash "$REPO/templates/.claude/hooks/post-commit.sh" >/dev/null 2>&1; test -f "$T/.dev-wiki/.pending-commit"; RC=$?; cd "$REPO"; rm -rf "$T"
  if [ "$RC" = 0 ]; then ok 5 "line-56 repro (project-local marker) fixed"; else bad 5 "line-56 repro still dormant"; fi
fi

# 6. harness hermeticity: grep + leak test + seeded-leak self-check (inside the test)
if grep -q CLAUDE_PROJECT_DIR scripts/eval-runner.sh && bash tests/test_eval_hermeticity.sh >/dev/null 2>&1 && grep -q 'seeded leaky runner' tests/test_eval_hermeticity.sh; then
  ok 6 "eval-runner neutralizes CLAUDE_PROJECT_DIR + hermetic-leak test + RED-on-seed control"
else bad 6 "hermeticity"; fi

# 7. kit-owned live extraction == scope:global set OR documented exceptions
LIVE=$(jq -r '.hooks | to_entries[] | .value[].hooks[]?.command // empty' "$HOME/.claude/settings.json" 2>/dev/null | grep -oE '[a-z0-9-]+\.sh' | sort -u)
KIT=$(jq -r '.hooks[].script' modules.json | sort -u)
GLOBAL=$(jq -r '.hooks[] | select(.scope == "global") | .script' modules.json | sort -u)
LIVE_KIT=$(comm -12 <(echo "$LIVE") <(echo "$KIT"))
if [ "$LIVE_KIT" = "$GLOBAL" ]; then ok 7 "live kit-owned globals == scope:global set ($GLOBAL)";
elif grep -qE '^maintainer-decision: (approve|partial|defer)' eval/hook-hygiene/registration-exceptions.md 2>/dev/null; then ok 7 "documented exceptions (registration-exceptions.md)";
else bad 7 "registration mismatch and no exceptions file"; fi

# 8. coverage matrix complete (delegate to its validator)
if bash eval/hook-hygiene/check-matrix.sh >/dev/null 2>&1 && grep -q 'installed-copy' eval/hook-hygiene/coverage-matrix.md; then
  ok 8 "coverage matrix complete (rows x 11, registration + copy-currency)"; else bad 8 "matrix"; fi

# 9. backup + restore-exercised
BK=$(sed -n 's/^backup-created: \([^ ]*\).*/\1/p' eval/hook-hygiene/rehearsal.log | head -1)
if [ -n "$BK" ] && [ -f "$BK" ] && grep -q 'restore-exercised' eval/hook-hygiene/rehearsal.log; then
  ok 9 "timestamped backup on disk + restore exercised in sandbox"; else bad 9 "backup/restore"; fi

# 10. install drift 0
DRIFT=$(bash scripts/check-install-drift.sh --count 2>/dev/null)
if [ "$DRIFT" = "0" ]; then ok 10 "install drift 0"; else bad 10 "drift=$DRIFT"; fi

echo ""
echo "$PASS/10 PASS"
[ "$PASS" = 10 ]
