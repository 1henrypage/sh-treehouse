#!/usr/bin/env bash

# Tests for wt diff

describe "wt diff"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Argument Validation ───────────────────────────────────────────────

test_diff_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt diff
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt diff" "shows usage"
}

it "shows error with no arguments" test_diff_no_args_shows_error

test_diff_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt diff nonexistent
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "shows error for nonexistent branch" test_diff_nonexistent_branch_shows_error

test_diff_outside_repo_shows_error() {
  cd /tmp
  __capture wt diff test-branch
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside repository" test_diff_outside_repo_shows_error

# ── Core Behavior ─────────────────────────────────────────────────────

test_diff_shows_changes() {
  cd "$TEST_REPO"
  __fixture_create_branch "diff-test"
  __fixture_create_worktree "diff-test"

  # Make a commit in worktree
  __fixture_commit_in_worktree "diff-test" "new-file.txt" "Add new file"

  __capture wt diff diff-test
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "new-file.txt" "shows changed file in diff"
}

it "shows diff output for changes" test_diff_shows_changes

test_diff_no_output_when_no_changes() {
  cd "$TEST_REPO"
  wt add diff-no-changes >/dev/null 2>&1

  __capture wt diff diff-no-changes
  assert_exit_code 0 "returns 0"
  assert_eq "$__STDOUT" "" "shows no output when no changes"
}

it "shows no output when branch has no changes" test_diff_no_output_when_no_changes

test_diff_shows_multiple_commits() {
  cd "$TEST_REPO"
  __fixture_create_branch "diff-multi"
  __fixture_create_worktree "diff-multi"

  # Make multiple commits
  __fixture_commit_in_worktree "diff-multi" "file1.txt" "First commit"
  __fixture_commit_in_worktree "diff-multi" "file2.txt" "Second commit"

  __capture wt diff diff-multi
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "file1.txt" "shows first file"
  assert_contains "$__STDOUT" "file2.txt" "shows second file"
}

it "shows all changes across multiple commits" test_diff_shows_multiple_commits

test_diff_uses_triple_dot_syntax() {
  cd "$TEST_REPO"
  __fixture_create_branch "diff-triple-dot"
  __fixture_create_worktree "diff-triple-dot"

  # Make a commit in main
  cd "$TEST_REPO"
  printf 'main-change\n' > main-file.txt
  git add main-file.txt
  git commit -m "Main change" >/dev/null 2>&1

  # Make a commit in worktree
  __fixture_commit_in_worktree "diff-triple-dot" "worktree-file.txt" "Worktree change"

  # Diff should only show worktree changes (three-dot syntax)
  __capture wt diff diff-triple-dot
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "worktree-file.txt" "shows worktree changes"
  assert_not_contains "$__STDOUT" "main-file.txt" "does not show main changes"
}

it "uses three-dot syntax to show branch-specific changes" test_diff_uses_triple_dot_syntax
