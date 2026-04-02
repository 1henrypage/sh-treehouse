#!/usr/bin/env bash

# Tests for wt rm

describe "wt rm"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Argument Validation ───────────────────────────────────────────────

test_rm_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt rm
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt rm" "shows usage"
}

it "shows error with no arguments" test_rm_no_args_shows_error

test_rm_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt rm nonexistent
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "shows error for nonexistent branch" test_rm_nonexistent_branch_shows_error

test_rm_outside_repo_shows_error() {
  cd /tmp
  __capture wt rm test-branch
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside repository" test_rm_outside_repo_shows_error

# ── Removing Worktrees ────────────────────────────────────────────────

test_rm_removes_worktree_directory() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-test"
  wt add rm-test >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/rm-test"
  cd "$TEST_REPO"
  # Answer 'n' to branch deletion prompt
  printf 'n\n' | wt rm rm-test >/dev/null 2>&1
  assert_dir_not_exists "$wt_path" "removes worktree directory"
}

it "removes worktree directory" test_rm_removes_worktree_directory

test_rm_with_no_keeps_branch() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-keep-branch-2"
  wt add rm-keep-branch-2 >/dev/null 2>&1
  cd "$TEST_REPO"
  # Redirect from /dev/null so prompt gets no input (acts as 'n')
  wt rm rm-keep-branch-2 < /dev/null >/dev/null 2>&1 || true
  # Check that branch still exists (wasn't deleted)
  git show-ref --verify --quiet refs/heads/rm-keep-branch-2 2>/dev/null
  local rc=$?
  assert_eq "$rc" "0" "branch not deleted when user doesn't answer"
}

it "keeps branch when prompt gets no input" test_rm_with_no_keeps_branch

test_rm_with_no_preserves_branch() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-keep-branch"
  wt add rm-keep-branch >/dev/null 2>&1
  cd "$TEST_REPO"
  # Answer 'n' to branch deletion prompt
  printf 'n\n' | wt rm rm-keep-branch >/dev/null 2>&1
  # Check that branch still exists
  git show-ref --verify --quiet refs/heads/rm-keep-branch 2>/dev/null
  local rc=$?
  assert_eq "$rc" "0" "preserves branch when user answers 'n'"
}

it "preserves branch when user answers n" test_rm_with_no_preserves_branch

# ── Force Flag ────────────────────────────────────────────────────────

test_rm_force_flag_short() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-force-short"
  wt add rm-force-short >/dev/null 2>&1
  cd "$TEST_REPO"
  printf 'y\n' | wt rm -f rm-force-short >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/rm-force-short"
  assert_dir_not_exists "$wt_path" "removes worktree with -f flag"
}

it "accepts -f flag" test_rm_force_flag_short

test_rm_force_flag_long() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-force-long"
  wt add rm-force-long >/dev/null 2>&1
  cd "$TEST_REPO"
  printf 'y\n' | wt rm --force rm-force-long >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/rm-force-long"
  assert_dir_not_exists "$wt_path" "removes worktree with --force flag"
}

it "accepts --force flag" test_rm_force_flag_long

test_rm_force_removes_dirty_worktree() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-force-dirty"
  wt add rm-force-dirty >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/rm-force-dirty"
  printf 'uncommitted\n' > "$wt_path/dirty-file.txt"
  cd "$TEST_REPO"
  wt rm -f rm-force-dirty < /dev/null >/dev/null 2>&1 || true
  assert_dir_not_exists "$wt_path" "force removes dirty worktree"
}

it "force flag removes dirty worktree" test_rm_force_removes_dirty_worktree

# ── Success Messages ──────────────────────────────────────────────────

test_rm_shows_success_message() {
  cd "$TEST_REPO"
  __fixture_create_branch "rm-success"
  wt add rm-success >/dev/null 2>&1
  cd "$TEST_REPO"
  local output
  output=$(printf 'n\n' | wt rm rm-success 2>&1)
  local stripped
  stripped="$(__strip_ansi "$output")"
  assert_contains "$stripped" "removed worktree" "shows success message"
}

it "shows success message" test_rm_shows_success_message
