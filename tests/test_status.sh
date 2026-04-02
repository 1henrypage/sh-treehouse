#!/usr/bin/env bash

# Tests for wt status

describe "wt status"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Basic Functionality ───────────────────────────────────────────────

test_status_outside_repo_shows_error() {
  cd /tmp
  __capture wt status
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside repository" test_status_outside_repo_shows_error

test_status_shows_main_worktree() {
  cd "$TEST_REPO"
  __capture wt status
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "main" "shows main branch"
  assert_contains "$__STDOUT" "$TEST_REPO" "shows main repo path"
}

it "shows main worktree" test_status_shows_main_worktree

test_status_shows_clean_worktree() {
  cd "$TEST_REPO"
  __capture wt status
  assert_contains "$__STDOUT" "clean" "shows 'clean' for clean worktree"
}

it "shows clean status for clean worktree" test_status_shows_clean_worktree

test_status_shows_dirty_worktree() {
  cd "$TEST_REPO"
  __fixture_create_branch "dirty-status"
  wt add dirty-status >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/dirty-status"
  __fixture_make_dirty "$wt_path"
  __capture wt status
  assert_contains "$__STDOUT" "dirty-status" "shows branch name"
  assert_contains "$__STDOUT" "dirty.txt" "shows uncommitted file"
  assert_match "$__STDOUT" "dirty-status.*dirty\.txt" "dirty worktree shows file changes not 'clean'"
}

it "shows changes for dirty worktree" test_status_shows_dirty_worktree

test_status_shows_multiple_worktrees() {
  cd "$TEST_REPO"
  __fixture_create_branch "status1"
  __fixture_create_branch "status2"
  wt add status1 >/dev/null 2>&1
  wt add status2 >/dev/null 2>&1
  __capture wt status
  assert_contains "$__STDOUT" "status1" "shows first worktree"
  assert_contains "$__STDOUT" "status2" "shows second worktree"
  assert_contains "$__STDOUT" "main" "shows main worktree"
}

it "shows all worktrees" test_status_shows_multiple_worktrees

# ── File-level Changes ────────────────────────────────────────────────

test_status_shows_file_details() {
  cd "$TEST_REPO"
  __fixture_create_branch "detailed"
  wt add detailed >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/detailed"
  printf 'new file\n' > "$wt_path/newfile.txt"
  __capture wt status
  # git status --short shows ?? for untracked files
  assert_match "$__STDOUT" "\?\?.*newfile.txt" "shows untracked file with ?? prefix"
}

it "shows file-level details" test_status_shows_file_details
