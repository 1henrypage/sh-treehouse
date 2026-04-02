#!/usr/bin/env bash

# Tests for wt reset

describe "wt reset"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Argument Validation ───────────────────────────────────────────────

test_reset_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt reset
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt reset" "shows usage"
}

it "shows error with no arguments" test_reset_no_args_shows_error

test_reset_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt reset nonexistent
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "shows error for nonexistent branch" test_reset_nonexistent_branch_shows_error

test_reset_outside_repo_shows_error() {
  cd /tmp
  __capture wt reset test-branch
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside repository" test_reset_outside_repo_shows_error

# ── Core Behavior ─────────────────────────────────────────────────────

test_reset_to_default_branch() {
  cd "$TEST_REPO"
  __fixture_create_branch "reset-test"
  __fixture_create_worktree "reset-test"

  # Make a commit in the worktree
  __fixture_commit_in_worktree "reset-test" "new-file.txt" "Add new file"

  # Reset to default branch (main)
  wt reset reset-test >/dev/null 2>&1

  # Check that worktree HEAD matches main
  local wt_path="$WT_DIR/origin/reset-test"
  local wt_head main_head
  wt_head=$(git -C "$wt_path" rev-parse HEAD)
  main_head=$(git -C "$TEST_REPO" rev-parse main)

  assert_eq "$wt_head" "$main_head" "resets worktree to main"
}

it "resets worktree to default branch" test_reset_to_default_branch

test_reset_removes_untracked_files() {
  cd "$TEST_REPO"
  wt add reset-clean >/dev/null 2>&1

  local wt_path="$WT_DIR/origin/reset-clean"

  # Add untracked file
  printf 'untracked\n' > "$wt_path/untracked.txt"

  # Reset should remove it with git clean (needs -f because worktree is dirty)
  wt reset -f reset-clean >/dev/null 2>&1

  assert_file_not_exists "$wt_path/untracked.txt" "removes untracked files"
}

it "removes untracked files with git clean" test_reset_removes_untracked_files

test_reset_refuses_when_dirty() {
  cd "$TEST_REPO"
  __fixture_create_branch "reset-dirty"
  __fixture_create_worktree "reset-dirty"

  local wt_path="$WT_DIR/origin/reset-dirty"
  __fixture_make_dirty "$wt_path"

  __capture wt reset reset-dirty
  assert_exit_code 1 "returns 1 when dirty"
  assert_contains "$__STDERR" "uncommitted changes" "shows error about uncommitted changes"
}

it "refuses when worktree is dirty" test_reset_refuses_when_dirty

test_reset_force_flag_resets_dirty() {
  cd "$TEST_REPO"
  __fixture_create_branch "reset-force"
  __fixture_create_worktree "reset-force"

  local wt_path="$WT_DIR/origin/reset-force"
  __fixture_make_dirty "$wt_path"

  __capture wt reset -f reset-force
  assert_exit_code 0 "returns 0 with -f flag"
}

it "force flag resets dirty worktree" test_reset_force_flag_resets_dirty

test_reset_force_flag_long() {
  cd "$TEST_REPO"
  __fixture_create_branch "reset-force-long"
  __fixture_create_worktree "reset-force-long"

  local wt_path="$WT_DIR/origin/reset-force-long"
  __fixture_make_dirty "$wt_path"

  __capture wt reset --force reset-force-long
  assert_exit_code 0 "returns 0 with --force flag"
}

it "accepts --force flag" test_reset_force_flag_long

test_reset_to_custom_ref() {
  cd "$TEST_REPO"
  __fixture_create_branch "reset-custom"
  __fixture_create_worktree "reset-custom"

  # Make commits
  __fixture_commit_in_worktree "reset-custom" "file1.txt" "First commit"
  __fixture_commit_in_worktree "reset-custom" "file2.txt" "Second commit"

  # Get the first commit hash
  local wt_path="$WT_DIR/origin/reset-custom"
  local first_commit
  first_commit=$(git -C "$wt_path" rev-parse HEAD~1)

  # Reset to first commit
  wt reset reset-custom "$first_commit" >/dev/null 2>&1

  # Check that HEAD is at first commit
  local current_head
  current_head=$(git -C "$wt_path" rev-parse HEAD)
  assert_eq "$current_head" "$first_commit" "resets to specified ref"
}

it "resets to custom ref" test_reset_to_custom_ref

test_reset_shows_success_message() {
  cd "$TEST_REPO"
  __fixture_create_branch "reset-success"
  __fixture_create_worktree "reset-success"

  __capture wt reset reset-success
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "reset" "shows success message"
  assert_contains "$__STDOUT" "reset-success" "includes branch name"
  assert_contains "$__STDOUT" "main" "includes ref name"
}

it "shows success message" test_reset_shows_success_message
