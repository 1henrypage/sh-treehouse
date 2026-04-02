#!/usr/bin/env bash

# Tests for wt ls

describe "wt ls"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── Basic Functionality ───────────────────────────────────────────────

test_ls_outside_repo_shows_error() {
  cd /tmp
  __capture wt ls
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "shows error outside repository" test_ls_outside_repo_shows_error

test_ls_shows_main_worktree() {
  cd "$TEST_REPO"
  __capture wt ls
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "main" "lists main branch"
  assert_contains "$__STDOUT" "$TEST_REPO" "shows main repo path"
}

it "lists main worktree" test_ls_shows_main_worktree

test_ls_shows_added_worktree() {
  cd "$TEST_REPO"
  __fixture_create_branch "test-ls"
  wt add test-ls >/dev/null 2>&1
  __capture wt ls
  assert_contains "$__STDOUT" "test-ls" "lists added worktree"
  local expected="$WT_DIR/origin/test-ls"
  assert_contains "$__STDOUT" "$expected" "shows worktree path"
}

it "lists added worktrees" test_ls_shows_added_worktree

test_ls_shows_multiple_worktrees() {
  cd "$TEST_REPO"
  __fixture_create_branch "wt1"
  __fixture_create_branch "wt2"
  wt add wt1 >/dev/null 2>&1
  wt add wt2 >/dev/null 2>&1
  __capture wt ls
  assert_contains "$__STDOUT" "wt1" "lists first worktree"
  assert_contains "$__STDOUT" "wt2" "lists second worktree"
  assert_contains "$__STDOUT" "main" "lists main worktree"
}

it "lists multiple worktrees" test_ls_shows_multiple_worktrees

# ── Status Indicators ─────────────────────────────────────────────────

test_ls_shows_clean_indicator() {
  cd "$TEST_REPO"
  __capture wt ls
  assert_contains "$__STDOUT" "ok" "shows clean indicator (ok)"
}

it "shows clean indicator for clean worktree" test_ls_shows_clean_indicator

test_ls_shows_dirty_indicator() {
  cd "$TEST_REPO"
  __fixture_create_branch "dirty-wt"
  wt add dirty-wt >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/dirty-wt"
  __fixture_make_dirty "$wt_path"
  __capture wt ls
  # The dirty indicator is a * (asterisk)
  assert_match "$__STDOUT" "dirty-wt.*\*" "shows dirty indicator (*) for dirty worktree"
}

it "shows dirty indicator for dirty worktree" test_ls_shows_dirty_indicator

# ── Lock Indicator ────────────────────────────────────────────────────

test_ls_shows_locked_indicator() {
  cd "$TEST_REPO"
  __fixture_create_branch "locked-wt"
  wt add locked-wt >/dev/null 2>&1
  wt lock locked-wt >/dev/null 2>&1
  __capture wt ls
  assert_contains "$__STDOUT" "[locked]" "shows locked indicator"
}

it "shows locked indicator" test_ls_shows_locked_indicator

# ── Prunable Indicator ────────────────────────────────────────────────

test_ls_shows_prunable_indicator() {
  cd "$TEST_REPO"
  __fixture_create_branch "prunable-wt"
  wt add prunable-wt >/dev/null 2>&1
  local wt_path="$WT_DIR/origin/prunable-wt"
  # wt add cd's into the new worktree; return to main repo before deleting it
  cd "$TEST_REPO"
  # Simulate a missing worktree directory (e.g. deleted outside of git)
  rm -rf "$wt_path"
  __capture wt ls
  assert_match "$__STDOUT" "prunable-wt.*prunable" "shows prunable indicator for missing worktree"
}

it "shows prunable indicator for missing worktree directory" test_ls_shows_prunable_indicator
