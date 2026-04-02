#!/usr/bin/env bash

# Test Harness — TAP output, assertions, test lifecycle

# ── Global State ──────────────────────────────────────────────────────
__TEST_COUNT=0
__TEST_PASSED=0
__TEST_FAILED=0
__CURRENT_GROUP=""
__STDOUT=""
__STDERR=""
__EXIT_CODE=0

# Temp files for output capture
__tmpout=$(mktemp)
__tmperr=$(mktemp)

# Clean up temp files on exit
trap "rm -f '$__tmpout' '$__tmperr'" EXIT INT TERM

# ── Output Capture ────────────────────────────────────────────────────

# Strip ANSI escape codes from a string
__strip_ansi() {
  printf '%s\n' "$1" | sed $'s/\033\[[0-9;]*m//g'
}

# Normalize path (resolve symlinks like /var -> /private/var on macOS)
__normalize_path() {
  if [ -e "$1" ]; then
    if command -v realpath >/dev/null 2>&1; then
      realpath "$1" 2>/dev/null && return
    fi
    if [ -d "$1" ]; then
      (cd "$1" && pwd -P)
      return
    fi
  fi
  printf '%s\n' "$1"
}

# Capture stdout, stderr, and exit code from a command
__capture() {
  __STDOUT=""
  __STDERR=""
  __EXIT_CODE=0

  { "$@"; __EXIT_CODE=$?; } >"$__tmpout" 2>"$__tmperr"

  __STDOUT="$(__strip_ansi "$(<"$__tmpout")")"
  __STDERR="$(__strip_ansi "$(<"$__tmperr")")"
}

# ── Assertions ────────────────────────────────────────────────────────

__test_pass() {
  __TEST_COUNT=$((__TEST_COUNT + 1))
  __TEST_PASSED=$((__TEST_PASSED + 1))
  printf 'ok %d - %s\n' "$__TEST_COUNT" "$1"
}

__test_fail() {
  __TEST_COUNT=$((__TEST_COUNT + 1))
  __TEST_FAILED=$((__TEST_FAILED + 1))
  printf 'not ok %d - %s\n' "$__TEST_COUNT" "$1"
  [ -n "${2:-}" ] && printf '  # %s\n' "$2"
}

assert_eq() {
  local actual="$1"
  local expected="$2"
  local msg="${3:-expected equality}"

  # Normalize paths if both look like absolute paths
  case "$actual" in
    /*)
      case "$expected" in
        /*)
          actual="$(__normalize_path "$actual")"
          expected="$(__normalize_path "$expected")"
          ;;
      esac
      ;;
  esac

  if [ "$actual" = "$expected" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "expected '$expected', got '$actual'"
  fi
}

assert_neq() {
  local actual="$1"
  local expected="$2"
  local msg="${3:-expected inequality}"

  if [ "$actual" != "$expected" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "expected not '$expected', but got it"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-expected to contain substring}"

  case "$haystack" in
    *"$needle"*) __test_pass "$msg" ;;
    *)           __test_fail "$msg" "expected to find '$needle' in '$haystack'" ;;
  esac
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-expected not to contain substring}"

  case "$haystack" in
    *"$needle"*) __test_fail "$msg" "did not expect to find '$needle'" ;;
    *)           __test_pass "$msg" ;;
  esac
}

assert_match() {
  local string="$1"
  local pattern="$2"
  local msg="${3:-expected to match regex}"

  if [[ "$string" =~ $pattern ]]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "expected '$string' to match pattern '$pattern'"
  fi
}

assert_exit_code() {
  local expected="$1"
  local msg="${2:-expected exit code $expected}"

  if [ "$__EXIT_CODE" -eq "$expected" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "expected exit code $expected, got $__EXIT_CODE"
  fi
}

assert_dir_exists() {
  local dir="$1"
  local msg="${2:-expected directory to exist: $dir}"

  if [ -d "$dir" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "directory does not exist: $dir"
  fi
}

assert_dir_not_exists() {
  local dir="$1"
  local msg="${2:-expected directory not to exist: $dir}"

  if [ ! -d "$dir" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "directory exists but shouldn't: $dir"
  fi
}

assert_file_exists() {
  local file="$1"
  local msg="${2:-expected file to exist: $file}"

  if [ -f "$file" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "file does not exist: $file"
  fi
}

assert_file_not_exists() {
  local file="$1"
  local msg="${2:-expected file not to exist: $file}"

  if [ ! -f "$file" ]; then
    __test_pass "$msg"
  else
    __test_fail "$msg" "file exists but shouldn't: $file"
  fi
}

# ── Test Lifecycle ────────────────────────────────────────────────────

describe() {
  __CURRENT_GROUP="$1"
  printf '\n# %s\n' "$__CURRENT_GROUP"
}

it() {
  local description="$1"
  local test_func="$2"

  # Call setup if defined
  if declare -F setup > /dev/null 2>&1; then
    setup
  fi

  # Run the test
  $test_func

  # Call teardown if defined
  if declare -F teardown > /dev/null 2>&1; then
    teardown
  fi
}

# ── Summary ───────────────────────────────────────────────────────────

print_summary() {
  printf '\n1..%d\n' "$__TEST_COUNT"
  printf '# tests %d\n' "$__TEST_COUNT"
  printf '# pass  %d\n' "$__TEST_PASSED"
  printf '# fail  %d\n' "$__TEST_FAILED"

  if [ "$__TEST_FAILED" -gt 0 ]; then
    return 1
  fi
  return 0
}
