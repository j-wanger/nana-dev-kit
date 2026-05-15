#!/usr/bin/env bash
# Shared test assertion functions. Source this from test scripts.

set -euo pipefail

_TESTS_RUN=0
_TESTS_PASSED=0
_TESTS_FAILED=0
_CURRENT_TEST=""

test_start() {
  _CURRENT_TEST="$1"
  _TESTS_RUN=$((_TESTS_RUN + 1))
  printf "  %-50s " "$1"
}

test_pass() {
  _TESTS_PASSED=$((_TESTS_PASSED + 1))
  echo "OK"
}

test_fail() {
  _TESTS_FAILED=$((_TESTS_FAILED + 1))
  echo "FAIL: $1"
}

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-values differ}"
  if [ "$expected" = "$actual" ]; then
    test_pass
  else
    test_fail "$msg (expected '$expected', got '$actual')"
  fi
}

assert_file_exists() {
  local path="$1" msg="${2:-file missing: $1}"
  if [ -f "$path" ]; then
    test_pass
  else
    test_fail "$msg"
  fi
}

assert_contains() {
  local file="$1" pattern="$2" msg="${3:-pattern not found: $2}"
  if grep -q "$pattern" "$file" 2>/dev/null; then
    test_pass
  else
    test_fail "$msg"
  fi
}

assert_exit_code() {
  local expected="$1"
  shift
  local actual
  set +e
  "$@" >/dev/null 2>&1
  actual=$?
  set -e
  if [ "$expected" = "$actual" ]; then
    test_pass
  else
    test_fail "expected exit code $expected, got $actual"
  fi
}

test_summary() {
  local suite="${1:-tests}"
  echo ""
  echo "$suite: $_TESTS_RUN run, $_TESTS_PASSED passed, $_TESTS_FAILED failed"
  [ "$_TESTS_FAILED" -eq 0 ]
}
