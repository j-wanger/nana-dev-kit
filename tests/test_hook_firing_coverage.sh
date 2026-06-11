#!/usr/bin/env bash
# Phase 67 — Hook firing-coverage gate.
#
# Makes the functional-smoke invariant ([[decision:functional-smoke-invariant-rule]], [[HEU-012]])
# MACHINE-CHECKABLE instead of prose: every registered hook that CAN be fired must have a test
# that actually invokes it and asserts an observable effect. That convention has eroded silently
# before (4 breakages, 8-33 phases each; the session-start.sh line-cap drift) — this gate stops it.
#
# Coverage is proven by a `# fires: <hook.sh> ...` declaration in a test that GENUINELY runs the hook,
# anchored to a NON-COMMENT reference to the hook in the same file. A bare filename mention does NOT
# count: every hook name appears in test_registration.sh / test_settings_template.sh (which only
# ENUMERATE hooks), so grep-for-name is a useless coverage signal — the declaration + non-comment
# anchor is what distinguishes "fires it" from "names it".
# (The anchor proves the hook is REFERENCED outside a comment, not literally executed — the `# fires:`
# declaration is the human-attested half of the contract; every real test invokes via run_hook/$HOOK=.)
#
# Denominator = the UNION of command-type .hooks[] (NOTE: command hooks carry NO `type` field — only
# the prompt hook has type:"prompt"; a literal select(.type=="command") matches ZERO and would falsely
# green the gate, so we use the negated predicate) PLUS every *.sh under the hook_dirs map's dirs
# (the session-start.d curators are shipped via hook_dirs, NOT registered in .hooks[]).
#
# The gate is un-gameable: a pinned exemption allow-list bounded by an exact count (each exemption
# machine-justified), a denominator-sanity floor (a classifier bug that empties the union FAILS rather
# than reporting green), and a permanent negative-control self-test (a bogus uncovered hook MUST be
# flagged — proving the detector is not vacuous).

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MODULES="$REPO_ROOT/modules.json"
HOOKS_SRC="$REPO_ROOT/templates/.claude/hooks"

# --- Sets (newline-separated strings; hook names are space-free, bash-3.2 safe) ---

# Firing-required = command-type .hooks[] + hook_dirs/*.sh curators.
required_set() {
  jq -r '.hooks[] | select((.type // "command") != "prompt") | .script' "$MODULES" | sed 's#.*/##'
  for d in $(jq -r '.hook_dirs[][]?' "$MODULES" 2>/dev/null); do
    if [ -d "$HOOKS_SRC/$d" ]; then
      ls "$HOOKS_SRC/$d"/*.sh 2>/dev/null | sed 's#.*/##'
    fi
  done
}

# Prompt-type hooks (not executable — get a structural test, not a firing test).
prompt_set() {
  jq -r '.hooks[] | select((.type // "command") == "prompt") | .script' "$MODULES" | sed 's#.*/##'
}

# Covered = hooks with a `# fires:` declaration ANCHORED to a non-comment reference in the same test.
covered_set() {
  local f decls decl
  for f in "$SCRIPT_DIR"/test_*.sh; do
    case "$f" in *test_hook_firing_coverage.sh) continue ;; esac
    # Parse `# fires: a.sh b.sh   # optional trailing note`: drop the prefix AND any trailing inline
    # comment, split on whitespace, keep only filename tokens (.sh/.md) — so comment words can't leak in.
    decls=$(grep -hE '^#[[:space:]]*fires:' "$f" 2>/dev/null \
            | sed -E 's/^#[[:space:]]*fires:[[:space:]]*//; s/[[:space:]]+#.*$//' \
            | tr ' \t' '\n\n' | grep -E '\.(sh|md)$' || true)
    for decl in $decls; do
      # ANCHOR: the declared hook basename must appear in a non-comment line of the SAME file
      # (a real invocation: HOOK=..., run_hook arg, or executed path) — not just the comment.
      if grep -v '^[[:space:]]*#' "$f" 2>/dev/null | grep -qF "$decl"; then
        echo "$decl"
      fi
    done
  done | sort -u
}

REQUIRED=$(required_set | sort -u)
COVERED=$(covered_set)
PROMPT_HOOKS=$(prompt_set)

# Pinned exemption allow-list. AIM: empty (every fireable hook gets a real firing test).
# To add an exemption you MUST (1) add it here, (2) bump EXEMPT_EXPECTED, (3) add a machine-justified
# reason check in the "per-exemption justification" block below. The count assertion forbids padding.
EXEMPT=""
EXEMPT_EXPECTED=0

# Floor: 17 command .hooks[] + 3 session-start.d curators = expected union of 20 (Phase 74 converted;
# detect-loop cut Phase 88
# py-review prompt->command, 17->18). A wrong classifier (e.g. literal type=="command") collapses this
# toward 0 — catch it instead of reporting 100% green. (expected >= 20)
REQUIRED_FLOOR=20

echo "=== Phase 67 Hook Firing-Coverage Gate ==="

req_count=$(printf '%s\n' "$REQUIRED" | grep -c . || true)
test_start "denominator-sanity: firing-required union >= $REQUIRED_FLOOR (17 command + 3 curators)"
if [ "$req_count" -ge "$REQUIRED_FLOOR" ]; then
  test_pass
else
  test_fail "union collapsed to $req_count (< $REQUIRED_FLOOR) — classifier bug? (literal type==command matches zero hooks)"
fi

test_start "coverage denominator includes the hook_dirs curators (not only .hooks[])"
# Sanity: at least one known curator is in the required set.
if printf '%s\n' "$REQUIRED" | grep -qxF "wk-prune.sh"; then test_pass; else test_fail "hook_dirs curators missing from union"; fi

exempt_count=$(printf '%s\n' "$EXEMPT" | grep -c . || true)
test_start "exemption allow-list bounded (== $EXEMPT_EXPECTED pinned, each machine-justified)"
if [ "$exempt_count" -eq "$EXEMPT_EXPECTED" ]; then
  test_pass
else
  test_fail "EXEMPT has $exempt_count entries (expected $EXEMPT_EXPECTED) — justify each, don't pad the allow-list"
fi

# --- per-exemption justification block (runs only when EXEMPT is non-empty) ---
for ex in $EXEMPT; do
  test_start "exemption is machine-justified: $ex"
  # No justified exemptions defined yet. Any entry reaching here without a case below FAILS.
  case "$ex" in
    # Example shape (none active): a prompt-type hook would be justified by:
    #   *) if [ "$(jq -r --arg s "$ex" '.hooks[]|select(.script==$s)|.type' "$MODULES")" = "prompt" ]; then test_pass; ...
    *) test_fail "$ex has no machine-justification — remove it or add a verifiable reason" ;;
  esac
done

# --- prompt-type hooks: structural test (not firing) ---
for p in $PROMPT_HOOKS; do
  pf="$HOOKS_SRC/$p"
  test_start "prompt-type hook is a valid prompt (non-empty, no shebang): $p"
  if [ -s "$pf" ] && ! head -1 "$pf" | grep -q '^#!'; then
    test_pass
  else
    test_fail "$p missing/empty or looks like a script (misregistered type?)"
  fi
done

# --- the gate: every firing-required hook is covered or exempt ---
gap=""
for h in $REQUIRED; do
  if printf '%s\n' "$COVERED" | grep -qxF "$h"; then continue; fi
  if printf '%s\n' "$EXEMPT"  | grep -qxF "$h"; then continue; fi
  gap="$gap $h"
done

test_start "every firing-required hook has an invocation-anchored firing test"
if [ -z "$(printf '%s' "$gap" | tr -d ' ')" ]; then
  test_pass
else
  test_fail "UNTESTED hooks (no anchored '# fires:' declaration):$gap
      -> add a firing test that pipes a synthesized event and asserts an OBSERVABLE EFFECT (stdout
         marker or file side-effect, NOT exit code alone), then declare it with '# fires: <hook>' in
         that test. For a NEW hook, also run 'make template' to regenerate settings.json."
fi

# --- NEGATIVE CONTROL (permanent): the detector must REJECT a bogus uncovered hook ---
test_start "negative control: a bogus uncovered hook is flagged (detector is not vacuous)"
neg_gap=""
for h in $REQUIRED "__bogus_uncovered_hook__.sh"; do
  if printf '%s\n' "$COVERED" | grep -qxF "$h"; then continue; fi
  if printf '%s\n' "$EXEMPT"  | grep -qxF "$h"; then continue; fi
  neg_gap="$neg_gap $h"
done
case " $neg_gap " in
  *" __bogus_uncovered_hook__.sh "*) test_pass ;;
  *) test_fail "detector did NOT flag a bogus uncovered hook — the gate is vacuous" ;;
esac

# Report the authoritative covered/required tallies for the planning checkpoint.
cov_count=$(printf '%s\n' "$COVERED" | grep -c . || true)
echo ""
echo "  coverage: $cov_count / $req_count firing-required hooks covered"
[ -n "$(printf '%s' "$gap" | tr -d ' ')" ] && echo "  gap:$gap"

test_summary "hook-firing-coverage"
