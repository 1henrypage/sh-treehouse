#!/usr/bin/env bash

# Tests for wt add

describe "wt add"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Argument Validation ───────────────────────────────────────────────

test_add_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt add
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt add <branch>" "shows usage"
}

it "shows error with no arguments" test_add_no_args_shows_error

test_add_outside_repo_shows_error() {
  cd /tmp
  __capture wt add test-branch
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside git repository" test_add_outside_repo_shows_error

# ── Creating Worktrees ────────────────────────────────────────────────

test_add_creates_worktree_simple() {
  cd "$TEST_REPO"
  wt add test-branch >/dev/null 2>&1
  local expected="$WT_DIR/origin/test-branch"
  assert_dir_exists "$expected" "creates worktree directory"
}

it "creates worktree for new branch" test_add_creates_worktree_simple

test_add_auto_checkouts_to_worktree() {
  cd "$TEST_REPO"
  wt add test-auto-checkout >/dev/null 2>&1
  local expected="$WT_DIR/origin/test-auto-checkout"
  assert_eq "$PWD" "$expected" "automatically checks out to new worktree"
}

it "automatically checks out to new worktree" test_add_auto_checkouts_to_worktree

test_add_creates_worktree_for_existing_local_branch() {
  cd "$TEST_REPO"
  __fixture_create_branch "existing-local"
  __capture wt add existing-local
  assert_exit_code 0 "returns 0"
  local expected="$WT_DIR/origin/existing-local"
  assert_dir_exists "$expected" "creates worktree directory"
}

it "creates worktree for existing local branch" test_add_creates_worktree_for_existing_local_branch

test_add_creates_worktree_for_remote_only_branch() {
  cd "$TEST_REPO"
  __fixture_create_remote_branch "remote-only"
  git fetch origin >/dev/null 2>&1
  __capture wt add remote-only
  assert_exit_code 0 "returns 0"
  local expected="$WT_DIR/origin/remote-only"
  assert_dir_exists "$expected" "creates worktree directory"
  # Check that it's tracking the remote
  cd "$expected"
  local upstream
  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
  assert_contains "$upstream" "origin/remote-only" "sets up remote tracking"
}

it "creates worktree for remote-only branch" test_add_creates_worktree_for_remote_only_branch

test_add_with_slash_branch() {
  cd "$TEST_REPO"
  __capture wt add feature/slash-test
  assert_exit_code 0 "returns 0"
  local expected="$WT_DIR/origin/feature--slash-test"
  assert_dir_exists "$expected" "converts slashes to -- in directory"
}

it "handles branch with slashes" test_add_with_slash_branch

test_add_already_exists_shows_error() {
  cd "$TEST_REPO"
  wt add test-branch >/dev/null 2>&1
  cd "$TEST_REPO"
  __capture wt add test-branch
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "worktree already exists" "shows error"
}

it "shows error if worktree already exists" test_add_already_exists_shows_error

# ── Directory Structure ───────────────────────────────────────────────

test_add_creates_nested_directories() {
  cd "$TEST_REPO"
  # Remove WT_DIR to test mkdir -p
  rm -rf "$WT_DIR"
  __capture wt add test-nested
  assert_exit_code 0 "returns 0"
  assert_dir_exists "$WT_DIR" "creates WT_DIR"
  assert_dir_exists "$WT_DIR/origin" "creates repo subdirectory"
}

it "creates nested directory structure" test_add_creates_nested_directories

# ── Worktree Content ──────────────────────────────────────────────────

test_add_worktree_has_git_dir() {
  cd "$TEST_REPO"
  wt add test-content >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/test-content"
  # In linked worktrees, .git is a file pointing to main repo
  assert_file_exists "$wt_path/.git" "worktree has .git file"
}

it "worktree has proper git structure" test_add_worktree_has_git_dir
