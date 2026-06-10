#!/usr/bin/env bash
# Eval runner — executes benchmark corpus and produces scored results.
# Usage: bash scripts/eval-runner.sh [--quick]
# Requires: jq

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CORPUS_DIR="$REPO_ROOT/eval/corpus"
HOOKS_DIR="$REPO_ROOT/templates/.claude/hooks"
VALIDATORS_DIR="$REPO_ROOT/eval/validators"

# --- jq check ---
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not found." >&2
  echo "Install: brew install jq (macOS) or apt-get install jq (Linux)" >&2
  exit 1
fi

QUICK=false
if [ "${1:-}" = "--quick" ]; then
  QUICK=true
fi

# --- Scenario discovery ---
SCENARIOS=()
while IFS= read -r -d '' manifest; do
  SCENARIOS+=("$manifest")
done < <(find "$CORPUS_DIR" -name 'scenario.json' -print0 2>/dev/null | sort -z)

if [ ${#SCENARIOS[@]} -eq 0 ]; then
  echo "No scenarios found in $CORPUS_DIR"
  echo "Score: 0/0 (0%)"
  exit 0
fi

# --- Counters ---
TOTAL=0
PASSED=0
FAILED=0
HOOK_TOTAL=0; HOOK_PASSED=0
SKILL_TOTAL=0; SKILL_PASSED=0
LIFECYCLE_TOTAL=0; LIFECYCLE_PASSED=0
CONTEXT_TOTAL=0; CONTEXT_PASSED=0

# --- Cleanup ---
TMPDIRS=()
cleanup() {
  for d in "${TMPDIRS[@]}"; do
    rm -rf "$d" 2>/dev/null || true
  done
}
trap cleanup EXIT

stage_files() {
  local manifest="$1" scenario_dir="$2" target_dir="$3" jq_path="$4"
  local entries
  entries=$(jq -r "$jq_path // {} | to_entries[] | \"\(.key)\t\(.value)\"" "$manifest" 2>/dev/null || true)
  [ -z "$entries" ] && return 0
  while IFS=$'\t' read -r dest src; do
    [ -z "$dest" ] && continue
    mkdir -p "$target_dir/$(dirname "$dest")"
    if [ -f "$scenario_dir/$src" ]; then
      cp "$scenario_dir/$src" "$target_dir/$dest"
    else
      printf '%s' "$src" > "$target_dir/$dest"
    fi
  done <<< "$entries"
}

run_hook() {
  local hook_script="$1" input_data="$2" work_dir="$3" eval_home="$4"
  local stderr_file
  stderr_file=$(mktemp)
  TMPDIRS+=("$stderr_file")

  # CLAUDE_PROJECT_DIR must point INSIDE the sandbox: hooks open with `cd "${CLAUDE_PROJECT_DIR:-.}"`,
  # so an inherited value would let them escape the sandbox into the caller's live project.
  local actual_exit=0
  HOOK_STDOUT=$(cd "$work_dir" && printf '%s' "$input_data" | HOME="$eval_home" CLAUDE_PROJECT_DIR="$work_dir" bash "$hook_script" 2>"$stderr_file") || actual_exit=$?
  HOOK_STDERR=$(cat "$stderr_file" 2>/dev/null || true)
  HOOK_EXIT=$actual_exit
}

check_patterns() {
  local text="$1" manifest="$2" jq_path="$3" mode="$4"
  local patterns
  patterns=$(jq -r "$jq_path // [] | .[]" "$manifest" 2>/dev/null || true)
  [ -z "$patterns" ] && return 0
  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    if [ "$mode" = "contains" ]; then
      echo "$text" | grep -q "$pattern" || return 1
    else
      echo "$text" | grep -q "$pattern" && return 1
    fi
  done <<< "$patterns"
  return 0
}

# --- Run scenarios ---
for manifest in "${SCENARIOS[@]}"; do
  SCENARIO_DIR="$(dirname "$manifest")"
  SCENARIO_NAME="$(basename "$SCENARIO_DIR")"

  CATEGORY=$(jq -r '.category' "$manifest")

  if [ "$QUICK" = true ] && [ "$CATEGORY" != "hook" ]; then
    continue
  fi

  TOTAL=$((TOTAL + 1))
  case "$CATEGORY" in
    hook) HOOK_TOTAL=$((HOOK_TOTAL + 1)) ;;
    skill) SKILL_TOTAL=$((SKILL_TOTAL + 1)) ;;
    lifecycle) LIFECYCLE_TOTAL=$((LIFECYCLE_TOTAL + 1)) ;;
    context) CONTEXT_TOTAL=$((CONTEXT_TOTAL + 1)) ;;
  esac

  WORK_DIR=$(mktemp -d)
  EVAL_HOME=$(mktemp -d)
  TMPDIRS+=("$WORK_DIR" "$EVAL_HOME")

  SCORE=1

  case "$CATEGORY" in
    hook)
      stage_files "$manifest" "$SCENARIO_DIR" "$WORK_DIR" '.setup.cwd_files'
      stage_files "$manifest" "$SCENARIO_DIR" "$EVAL_HOME" '.setup.home_files'

      # Touch old: set specific files to old mtime (before git init)
      while IFS= read -r tpath; do
        [ -z "$tpath" ] && continue
        touch -t "202601010000" "$WORK_DIR/$tpath" 2>/dev/null || true
      done < <(jq -r '.setup.touch_old // [] | .[]' "$manifest" 2>/dev/null)

      # Git init if requested (commit timestamp = now, after touch_old)
      INIT_GIT=$(jq -r '.setup.init_git // empty' "$manifest" 2>/dev/null || true)
      if [ -n "$INIT_GIT" ]; then
        git -C "$WORK_DIR" init -q 2>/dev/null
        git -C "$WORK_DIR" add . 2>/dev/null
        GIT_MSG="$INIT_GIT"
        [ "$GIT_MSG" = "true" ] && GIT_MSG="eval init"
        git -C "$WORK_DIR" -c user.email="eval@test" -c user.name="eval" commit -q -m "$GIT_MSG" 2>/dev/null || true
      fi

      HOOK=$(jq -r '.hook' "$manifest")
      HOOK_SCRIPT="$HOOKS_DIR/$HOOK"

      if [ ! -f "$HOOK_SCRIPT" ]; then
        printf "  %-45s FAIL (hook not found: %s)\n" "$SCENARIO_NAME" "$HOOK"
        FAILED=$((FAILED + 1))
        SCORE=0
        continue
      fi

      INPUT_FILE=$(jq -r '.input_file // empty' "$manifest" 2>/dev/null || true)
      if [ -n "$INPUT_FILE" ] && [ -f "$SCENARIO_DIR/$INPUT_FILE" ]; then
        INPUT_DATA=$(cat "$SCENARIO_DIR/$INPUT_FILE")
      else
        INPUT_DATA=$(jq -r '.input // "{}"' "$manifest")
      fi

      EXPECTED_EXIT=$(jq -r '.expected.exit_code // 0' "$manifest")

      run_hook "$HOOK_SCRIPT" "$INPUT_DATA" "$WORK_DIR" "$EVAL_HOME"

      if [ "$HOOK_EXIT" -ne "$EXPECTED_EXIT" ]; then
        SCORE=0
      fi

      if ! check_patterns "$HOOK_STDOUT" "$manifest" '.expected.stdout_contains' 'contains'; then
        SCORE=0
      fi
      if ! check_patterns "$HOOK_STDERR" "$manifest" '.expected.stderr_contains' 'contains'; then
        SCORE=0
      fi
      if ! check_patterns "$HOOK_STDOUT" "$manifest" '.expected.stdout_not_contains' 'not_contains'; then
        SCORE=0
      fi
      ;;

    skill)
      ARTIFACT=$(jq -r '.artifact_file' "$manifest")
      ARTIFACT_TYPE=$(jq -r '.artifact_type' "$manifest")
      VALIDATOR="$VALIDATORS_DIR/validate-${ARTIFACT_TYPE}.sh"

      if [ ! -f "$VALIDATOR" ]; then
        printf "  %-45s FAIL (validator not found)\n" "$SCENARIO_NAME"
        FAILED=$((FAILED + 1))
        SCORE=0
        continue
      fi

      EXPECTED_VALID=$(jq -r '.expected.valid' "$manifest")

      set +e
      bash "$VALIDATOR" "$SCENARIO_DIR/$ARTIFACT" >/dev/null 2>&1
      VAL_EXIT=$?
      set -e

      if [ "$EXPECTED_VALID" = "true" ] && [ "$VAL_EXIT" -ne 0 ]; then
        SCORE=0
      elif [ "$EXPECTED_VALID" = "false" ] && [ "$VAL_EXIT" -eq 0 ]; then
        SCORE=0
      fi
      ;;

    lifecycle)
      stage_files "$manifest" "$SCENARIO_DIR" "$WORK_DIR" '.setup.cwd_files'
      stage_files "$manifest" "$SCENARIO_DIR" "$EVAL_HOME" '.setup.home_files'

      # Git init if requested (same semantics as the hook category)
      INIT_GIT=$(jq -r '.setup.init_git // empty' "$manifest" 2>/dev/null || true)
      if [ -n "$INIT_GIT" ]; then
        git -C "$WORK_DIR" init -q 2>/dev/null
        git -C "$WORK_DIR" add . 2>/dev/null
        GIT_MSG="$INIT_GIT"
        [ "$GIT_MSG" = "true" ] && GIT_MSG="eval init"
        git -C "$WORK_DIR" -c user.email="eval@test" -c user.name="eval" commit -q -m "$GIT_MSG" 2>/dev/null || true
      fi

      STEPS=$(jq '.steps | length' "$manifest")

      for ((i=0; i<STEPS; i++)); do
        stage_files "$manifest" "$SCENARIO_DIR" "$WORK_DIR" ".steps[$i].setup_delta.cwd_files"
        stage_files "$manifest" "$SCENARIO_DIR" "$EVAL_HOME" ".steps[$i].setup_delta.home_files"

        STEP_HOOK=$(jq -r ".steps[$i].hook" "$manifest")
        STEP_SCRIPT="$HOOKS_DIR/$STEP_HOOK"

        STEP_INPUT_FILE=$(jq -r ".steps[$i].input_file // empty" "$manifest" 2>/dev/null || true)
        if [ -n "$STEP_INPUT_FILE" ] && [ -f "$SCENARIO_DIR/$STEP_INPUT_FILE" ]; then
          STEP_INPUT=$(cat "$SCENARIO_DIR/$STEP_INPUT_FILE")
        else
          STEP_INPUT=$(jq -r ".steps[$i].input // \"{}\"" "$manifest")
        fi

        STEP_EXPECTED=$(jq -r ".steps[$i].expected.exit_code // 0" "$manifest")

        run_hook "$STEP_SCRIPT" "$STEP_INPUT" "$WORK_DIR" "$EVAL_HOME"

        if [ "$HOOK_EXIT" -ne "$STEP_EXPECTED" ]; then
          SCORE=0
        fi

        if ! check_patterns "$HOOK_STDOUT" "$manifest" ".steps[$i].expected.stdout_contains" 'contains'; then
          SCORE=0
        fi
        if ! check_patterns "$HOOK_STDERR" "$manifest" ".steps[$i].expected.stderr_contains" 'contains'; then
          SCORE=0
        fi
      done
      ;;

    context)
      stage_files "$manifest" "$SCENARIO_DIR" "$WORK_DIR" '.setup.cwd_files'
      stage_files "$manifest" "$SCENARIO_DIR" "$EVAL_HOME" '.setup.home_files'

      CHECK_COUNT=$(jq '.checks | length' "$manifest")
      for ((ci=0; ci<CHECK_COUNT; ci++)); do
        CHECK_TYPE=$(jq -r ".checks[$ci].type" "$manifest")
        case "$CHECK_TYPE" in
          file_exists)
            CHECK_PATH=$(jq -r ".checks[$ci].path" "$manifest")
            if [ ! -f "$EVAL_HOME/$CHECK_PATH" ]; then
              SCORE=0
            fi
            ;;
          section_present)
            CHECK_PATH=$(jq -r ".checks[$ci].path" "$manifest")
            SECTIONS=$(jq -r ".checks[$ci].sections[]" "$manifest" 2>/dev/null || true)
            while IFS= read -r section; do
              [ -z "$section" ] && continue
              if ! grep -qF "$section" "$EVAL_HOME/$CHECK_PATH" 2>/dev/null; then
                SCORE=0
              fi
            done <<< "$SECTIONS"
            ;;
          hook_output)
            CHECK_HOOK=$(jq -r ".checks[$ci].hook" "$manifest")
            CHECK_HOOK_SCRIPT="$HOOKS_DIR/$CHECK_HOOK"
            CHECK_INPUT=$(jq -r ".checks[$ci].input // \"\"" "$manifest")
            if [ -f "$CHECK_HOOK_SCRIPT" ]; then
              run_hook "$CHECK_HOOK_SCRIPT" "$CHECK_INPUT" "$WORK_DIR" "$EVAL_HOME"
              if ! check_patterns "$HOOK_STDOUT" "$manifest" ".checks[$ci].stdout_contains" 'contains'; then
                SCORE=0
              fi
            else
              SCORE=0
            fi
            ;;
        esac
      done
      ;;

    *)
      printf "  %-45s FAIL (unknown category: %s)\n" "$SCENARIO_NAME" "$CATEGORY"
      FAILED=$((FAILED + 1))
      SCORE=0
      continue
      ;;
  esac

  if [ "$SCORE" -eq 1 ]; then
    PASSED=$((PASSED + 1))
    case "$CATEGORY" in
      hook) HOOK_PASSED=$((HOOK_PASSED + 1)) ;;
      skill) SKILL_PASSED=$((SKILL_PASSED + 1)) ;;
      lifecycle) LIFECYCLE_PASSED=$((LIFECYCLE_PASSED + 1)) ;;
      context) CONTEXT_PASSED=$((CONTEXT_PASSED + 1)) ;;
    esac
    printf "  %-45s PASS\n" "$SCENARIO_NAME"
  else
    FAILED=$((FAILED + 1))
    printf "  %-45s FAIL\n" "$SCENARIO_NAME"
  fi
done

# --- Report ---
echo ""
echo "=== Eval Report ==="
echo ""

if [ "$HOOK_TOTAL" -gt 0 ]; then
  printf "  %-15s %d/%d (%d%%)\n" "hook" "$HOOK_PASSED" "$HOOK_TOTAL" "$((HOOK_PASSED * 100 / HOOK_TOTAL))"
fi
if [ "$SKILL_TOTAL" -gt 0 ]; then
  printf "  %-15s %d/%d (%d%%)\n" "skill" "$SKILL_PASSED" "$SKILL_TOTAL" "$((SKILL_PASSED * 100 / SKILL_TOTAL))"
fi
if [ "$LIFECYCLE_TOTAL" -gt 0 ]; then
  printf "  %-15s %d/%d (%d%%)\n" "lifecycle" "$LIFECYCLE_PASSED" "$LIFECYCLE_TOTAL" "$((LIFECYCLE_PASSED * 100 / LIFECYCLE_TOTAL))"
fi
if [ "$CONTEXT_TOTAL" -gt 0 ]; then
  printf "  %-15s %d/%d (%d%%)\n" "context" "$CONTEXT_PASSED" "$CONTEXT_TOTAL" "$((CONTEXT_PASSED * 100 / CONTEXT_TOTAL))"
fi

echo ""
if [ "$TOTAL" -gt 0 ]; then
  OVERALL_PCT=$((PASSED * 100 / TOTAL))
  echo "Score: $PASSED/$TOTAL ($OVERALL_PCT%)"
else
  echo "Score: 0/0 (0%)"
fi
