#!/usr/bin/env bash

# Tests for wt run

describe "wt run"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Argument Validation ───────────────────────────────────────────────

test_run_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt run
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt run <branch> <command...>" "shows usage"
}

it "shows error with no arguments" test_run_no_args_shows_error

test_run_branch_only_shows_error() {
  cd "$TEST_REPO"
  __fixture_create_branch "run-no-cmd"
  wt add run-no-cmd >/dev/null 2>&1
  __capture wt run run-no-cmd
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt run" "shows usage when no command given"
}

it "shows error with branch but no command" test_run_branch_only_shows_error

test_run_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt run nonexistent pwd
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "shows error for nonexistent branch" test_run_nonexistent_branch_shows_error

test_run_outside_repo_shows_error() {
  cd /tmp
  __capture wt run test-branch pwd
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside repository" test_run_outside_repo_shows_error

# ── Running Commands ──────────────────────────────────────────────────

test_run_executes_command_in_worktree() {
  cd "$TEST_REPO"
  __fixture_create_branch "run-exec"
  wt add run-exec >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/run-exec"
  __capture wt run run-exec pwd
  assert_exit_code 0 "returns 0"
  assert_eq "$__STDOUT" "$wt_path" "command runs in worktree directory"
}

it "executes command in worktree directory" test_run_executes_command_in_worktree

test_run_does_not_change_calling_shell_pwd() {
  cd "$TEST_REPO"
  local orig_pwd="$PWD"
  __fixture_create_branch "run-no-cd"
  wt add run-no-cd >/dev/null 2>&1
  cd "$orig_pwd"
  wt run run-no-cd pwd >/dev/null 2>&1
  assert_eq "$PWD" "$orig_pwd" "does not change calling shell PWD"
}

it "does not change calling shell directory" test_run_does_not_change_calling_shell_pwd

test_run_passes_exit_code_through() {
  cd "$TEST_REPO"
  __fixture_create_branch "run-exitcode"
  wt add run-exitcode >/dev/null 2>&1
  __capture wt run run-exitcode "exit 42"
  assert_exit_code 42 "passes through command exit code"
}

it "passes exit code through" test_run_passes_exit_code_through

test_run_with_multiple_args() {
  cd "$TEST_REPO"
  __fixture_create_branch "run-multi"
  wt add run-multi >/dev/null 2>&1
  __capture wt run run-multi echo "hello world"
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "hello world" "handles multi-argument commands"
}

it "handles multi-argument commands" test_run_with_multiple_args

# ── Command Output ────────────────────────────────────────────────────

test_run_captures_stdout() {
  cd "$TEST_REPO"
  __fixture_create_branch "run-stdout"
  wt add run-stdout >/dev/null 2>&1
  __capture wt run run-stdout echo "test output"
  assert_contains "$__STDOUT" "test output" "captures command stdout"
}

it "captures command stdout" test_run_captures_stdout

test_run_with_git_command() {
  cd "$TEST_REPO"
  __fixture_create_branch "run-git"
  wt add run-git >/dev/null 2>&1
  __capture wt run run-git git branch --show-current
  assert_contains "$__STDOUT" "run-git" "runs git commands in worktree context"
}

it "runs git commands in worktree" test_run_with_git_command
