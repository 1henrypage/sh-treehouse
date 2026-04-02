#!/usr/bin/env bash

# Tests for wt dispatcher and help

describe "Dispatcher"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── No Arguments ──────────────────────────────────────────────────────

test_no_args_shows_help() {
  cd "$TEST_REPO"
  __capture wt
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "wt - git worktree manager" "shows help header"
  assert_contains "$__STDOUT" "Usage:" "shows usage"
}

it "shows help with no arguments" test_no_args_shows_help

# ── Help Command ──────────────────────────────────────────────────────

test_help_command() {
  cd "$TEST_REPO"
  __capture wt help
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "wt - git worktree manager" "shows help"
}

it "shows help with 'help' command" test_help_command

test_help_flag_short() {
  cd "$TEST_REPO"
  __capture wt -h
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "Usage:" "shows help"
}

it "shows help with -h flag" test_help_flag_short

test_help_flag_long() {
  cd "$TEST_REPO"
  __capture wt --help
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "Usage:" "shows help"
}

it "shows help with --help flag" test_help_flag_long

# ── Unknown Command ───────────────────────────────────────────────────

test_unknown_command_shows_error() {
  cd "$TEST_REPO"
  __capture wt unknowncommand
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "unknown command: unknowncommand" "shows error"
  assert_contains "$__STDOUT" "Usage:" "shows help after error"
}

it "shows error for unknown command" test_unknown_command_shows_error

# ── Valid Commands Route Correctly ────────────────────────────────────

test_routes_add_command() {
  cd "$TEST_REPO"
  __capture wt add
  assert_contains "$__STDERR" "usage: wt add" "routes to add command"
}

it "routes 'add' command" test_routes_add_command

test_routes_rm_command() {
  cd "$TEST_REPO"
  __capture wt rm
  assert_contains "$__STDERR" "usage: wt rm" "routes to rm command"
}

it "routes 'rm' command" test_routes_rm_command

test_routes_ls_command() {
  cd "$TEST_REPO"
  __capture wt ls
  assert_exit_code 0 "routes to ls command"
}

it "routes 'ls' command" test_routes_ls_command

test_routes_checkout_command() {
  cd "$TEST_REPO"
  __capture wt checkout
  assert_contains "$__STDERR" "usage: wt checkout" "routes to checkout command"
}

it "routes 'checkout' command" test_routes_checkout_command

test_routes_base_command() {
  cd "$TEST_REPO"
  wt base >/dev/null 2>&1
  local rc=$?
  assert_eq "$rc" "0" "routes to base command"
}

it "routes 'base' command" test_routes_base_command

test_routes_status_command() {
  cd "$TEST_REPO"
  __capture wt status
  assert_exit_code 0 "routes to status command"
}

it "routes 'status' command" test_routes_status_command

test_routes_lock_command() {
  cd "$TEST_REPO"
  __capture wt lock
  assert_contains "$__STDERR" "usage: wt lock" "routes to lock command"
}

it "routes 'lock' command" test_routes_lock_command

test_routes_unlock_command() {
  cd "$TEST_REPO"
  __capture wt unlock
  assert_contains "$__STDERR" "usage: wt unlock" "routes to unlock command"
}

it "routes 'unlock' command" test_routes_unlock_command

test_routes_run_command() {
  cd "$TEST_REPO"
  __capture wt run
  assert_contains "$__STDERR" "usage: wt run" "routes to run command"
}

it "routes 'run' command" test_routes_run_command
