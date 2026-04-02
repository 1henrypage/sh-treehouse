#!/usr/bin/env bash

# Tests for wt checkout and wt base
# Note: cd-capable commands are called directly (not via __capture)
# since cd must affect the real shell's PWD via the eval'd wt() wrapper

describe "wt checkout and wt base"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── wt checkout ──────────────────────────────────────────────────────

test_checkout_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt checkout
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt checkout <branch>" "shows usage"
}

it "checkout: shows error with no arguments" test_checkout_no_args_shows_error

test_checkout_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt checkout nonexistent
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "checkout: shows error for nonexistent branch" test_checkout_nonexistent_branch_shows_error

test_checkout_changes_directory() {
  cd "$TEST_REPO"
  __fixture_create_branch "test-checkout"
  git worktree add "$WT_DIR/origin/test-checkout" test-checkout >/dev/null 2>&1
  wt checkout test-checkout >/dev/null 2>&1
  local expected="$WT_DIR/origin/test-checkout"
  assert_eq "$PWD" "$expected" "changes to worktree directory"
}

it "checkout: changes to worktree directory" test_checkout_changes_directory

test_checkout_works_with_slash_branch() {
  cd "$TEST_REPO"
  __fixture_create_branch "feature/checkout-slash"
  git worktree add "$WT_DIR/origin/feature--checkout-slash" feature/checkout-slash >/dev/null 2>&1
  wt checkout feature/checkout-slash >/dev/null 2>&1
  local expected="$WT_DIR/origin/feature--checkout-slash"
  assert_eq "$PWD" "$expected" "changes to slash branch worktree"
}

it "checkout: works with slash branch" test_checkout_works_with_slash_branch

# ── wt base ───────────────────────────────────────────────────────────

test_base_changes_to_main_root() {
  cd "$TEST_REPO"
  __fixture_create_branch "test-base"
  wt add test-base >/dev/null 2>&1
  # wt add auto-checkouts, so we're already in the worktree
  wt base >/dev/null 2>&1
  assert_eq "$PWD" "$TEST_REPO" "returns to main repo"
}

it "base: changes to main repository" test_base_changes_to_main_root

test_base_works_from_linked_worktree() {
  cd "$TEST_REPO"
  __fixture_create_branch "test-base-linked"
  wt add test-base-linked >/dev/null 2>&1
  # wt add already changed to the worktree
  wt base >/dev/null 2>&1
  assert_eq "$PWD" "$TEST_REPO" "returns to main repo from linked worktree"
}

it "base: works from linked worktree" test_base_works_from_linked_worktree

test_base_outside_repo_shows_error() {
  cd /tmp
  __capture wt base
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "not inside a git repository" "shows error"
}

it "base: shows error outside repository" test_base_outside_repo_shows_error

# ── Round-trip ────────────────────────────────────────────────────────

test_checkout_then_base_returns_to_main() {
  cd "$TEST_REPO"
  local orig_pwd="$PWD"
  __fixture_create_branch "roundtrip-1"
  __fixture_create_branch "roundtrip-2"
  git worktree add "$WT_DIR/origin/roundtrip-1" roundtrip-1 >/dev/null 2>&1
  git worktree add "$WT_DIR/origin/roundtrip-2" roundtrip-2 >/dev/null 2>&1
  wt checkout roundtrip-1 >/dev/null 2>&1
  wt checkout roundtrip-2 >/dev/null 2>&1
  wt base >/dev/null 2>&1
  assert_eq "$PWD" "$orig_pwd" "round-trip checkout+base returns to original"
}

it "round-trip: checkout then base returns to main" test_checkout_then_base_returns_to_main
