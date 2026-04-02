#!/usr/bin/env bash

# Tests for __wt_* helper functions

describe "Helper Functions"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── __wt_err ──────────────────────────────────────────────────────────

test_wt_err_prints_to_stderr() {
  __capture wt rm  # triggers __wt_err via "usage: wt rm"
  assert_contains "$__STDERR" "usage: wt rm" "prints error to stderr"
}

it "outputs error to stderr" test_wt_err_prints_to_stderr

# ── __wt_ensure_git_repo ──────────────────────────────────────────────

test_ensure_git_repo_succeeds_in_repo() {
  cd "$TEST_REPO"
  __capture wt ls
  assert_exit_code 0 "returns 0 inside git repo"
}

it "succeeds inside git repository" test_ensure_git_repo_succeeds_in_repo

test_ensure_git_repo_fails_outside_repo() {
  cd /tmp
  __capture wt ls
  assert_exit_code 1 "returns 1 outside git repo"
  assert_contains "$__STDERR" "not inside a git repository" "prints error message"
}

it "fails outside git repository" test_ensure_git_repo_fails_outside_repo

# ── __wt_repo_name (via wt add output) ───────────────────────────────

test_repo_name_from_origin_url() {
  cd "$TEST_REPO"
  # The repo is cloned from a bare repo named origin.git, so repo name = "origin"
  __capture wt add test-repo-name-branch
  assert_contains "$__STDOUT" "$WT_DIR/origin/" "uses origin as repo name"
}

it "extracts repo name from origin URL" test_repo_name_from_origin_url

# ── __wt_main_root (via wt base) ─────────────────────────────────────

test_main_root_from_main_worktree() {
  cd "$TEST_REPO"
  wt base >/dev/null 2>&1
  assert_eq "$PWD" "$TEST_REPO" "base returns to main repo from main worktree"
}

it "returns main root from main worktree" test_main_root_from_main_worktree

test_main_root_from_linked_worktree() {
  cd "$TEST_REPO"
  __fixture_create_branch "test-branch"
  __fixture_create_worktree "test-branch"
  local wt_path="$WT_DIR/origin/test-branch"
  cd "$wt_path"
  wt base >/dev/null 2>&1
  assert_eq "$PWD" "$TEST_REPO" "base returns to main repo from linked worktree"
}

it "returns main root from linked worktree" test_main_root_from_linked_worktree

# ── __wt_branch_to_path (via wt add) ─────────────────────────────────

test_branch_to_path_simple() {
  cd "$TEST_REPO"
  wt add simple-path-test >/dev/null 2>&1
  local expected="$WT_DIR/origin/simple-path-test"
  assert_dir_exists "$expected" "converts simple branch to path"
}

it "converts simple branch to path" test_branch_to_path_simple

test_branch_to_path_with_slashes() {
  cd "$TEST_REPO"
  wt add feature/path-slash >/dev/null 2>&1
  local expected="$WT_DIR/origin/feature--path-slash"
  assert_dir_exists "$expected" "converts slashes to -- in path"
}

it "converts slashes to -- in path" test_branch_to_path_with_slashes

# ── __wt_resolve_worktree_path (via wt checkout) ─────────────────────

test_resolve_worktree_finds_existing() {
  cd "$TEST_REPO"
  __fixture_create_branch "test-resolve"
  __fixture_create_worktree "test-resolve"
  local expected="$WT_DIR/origin/test-resolve"
  # checkout uses resolve internally
  wt checkout test-resolve >/dev/null 2>&1
  assert_eq "$PWD" "$expected" "resolves existing worktree path"
}

it "resolves existing worktree path" test_resolve_worktree_finds_existing

test_resolve_worktree_returns_error_for_nonexistent() {
  cd "$TEST_REPO"
  __capture wt checkout nonexistent
  assert_exit_code 1 "returns 1 for nonexistent"
  assert_contains "$__STDERR" "no worktree found" "error for nonexistent worktree"
}

it "returns error for nonexistent worktree" test_resolve_worktree_returns_error_for_nonexistent

test_resolve_worktree_with_slashes() {
  cd "$TEST_REPO"
  __fixture_create_branch "feature/slash"
  __fixture_create_worktree "feature/slash"
  local expected="$WT_DIR/origin/feature--slash"
  wt checkout feature/slash >/dev/null 2>&1
  assert_eq "$PWD" "$expected" "resolves slash branch correctly"
}

it "resolves worktree with slash branch" test_resolve_worktree_with_slashes

# ── __wt_is_dirty (via wt integrate) ─────────────────────────────────

test_is_dirty_returns_false_for_clean() {
  cd "$TEST_REPO"
  # A clean worktree should allow integrate (which checks dirtiness)
  __fixture_create_branch "clean-check"
  __fixture_create_worktree "clean-check"
  __fixture_commit_in_worktree "clean-check" "feature.txt" "Add feature"
  __capture wt integrate clean-check
  assert_exit_code 0 "clean worktree allows integrate"
}

it "clean worktree is not dirty" test_is_dirty_returns_false_for_clean

test_is_dirty_returns_true_for_dirty() {
  cd "$TEST_REPO"
  __fixture_create_branch "dirty-check"
  __fixture_create_worktree "dirty-check"
  local wt_path="$WT_DIR/origin/dirty-check"
  __fixture_make_dirty "$wt_path"
  __capture wt integrate dirty-check
  assert_exit_code 1 "dirty worktree blocks integrate"
  assert_contains "$__STDERR" "uncommitted changes" "reports dirty state"
}

it "dirty worktree is detected" test_is_dirty_returns_true_for_dirty

# ── __wt_default_branch ───────────────────────────────────────────────

test_default_branch_returns_main() {
  cd "$TEST_REPO"
  # wt reset uses default branch detection
  __fixture_create_worktree "default-branch-test"
  __capture wt reset default-branch-test
  assert_exit_code 0 "resets to main (default branch)"
  assert_contains "$__STDOUT" "main" "output mentions 'main'"
}

it "returns main when it exists" test_default_branch_returns_main

test_default_branch_returns_master_when_no_main() {
  cd "$TEST_REPO"
  git branch -m main master >/dev/null 2>&1
  __fixture_create_worktree "master-default-test"
  __capture wt reset master-default-test
  assert_exit_code 0 "resets to master"
  assert_contains "$__STDOUT" "master" "output mentions 'master'"
  git branch -m master main >/dev/null 2>&1
}

it "returns master when main doesn't exist" test_default_branch_returns_master_when_no_main
