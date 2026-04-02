#!/usr/bin/env bash

# Tests for wt lock and wt unlock

describe "wt lock and wt unlock"

setup() {
  __fixture_create_repo
}

teardown() {
  __fixture_teardown
}

# ── wt lock ───────────────────────────────────────────────────────────

test_lock_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt lock
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt lock <branch>" "shows usage"
}

it "lock: shows error with no arguments" test_lock_no_args_shows_error

test_lock_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt lock nonexistent
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "lock: shows error for nonexistent branch" test_lock_nonexistent_branch_shows_error

test_lock_succeeds() {
  cd "$TEST_REPO"
  __fixture_create_branch "lock-test"
  wt add lock-test >/dev/null 2>&1
  __capture wt lock lock-test
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "locked worktree for 'lock-test'" "shows success"
}

it "lock: successfully locks worktree" test_lock_succeeds

test_lock_already_locked_shows_error() {
  cd "$TEST_REPO"
  __fixture_create_branch "already-locked"
  wt add already-locked >/dev/null 2>&1
  wt lock already-locked >/dev/null 2>&1
  __capture wt lock already-locked
  assert_neq "$__EXIT_CODE" "0" "returns non-zero when already locked"
}

it "lock: shows error if already locked" test_lock_already_locked_shows_error

# ── wt unlock ─────────────────────────────────────────────────────────

test_unlock_no_args_shows_error() {
  cd "$TEST_REPO"
  __capture wt unlock
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "usage: wt unlock <branch>" "shows usage"
}

it "unlock: shows error with no arguments" test_unlock_no_args_shows_error

test_unlock_nonexistent_branch_shows_error() {
  cd "$TEST_REPO"
  __capture wt unlock nonexistent
  assert_exit_code 1 "returns 1"
  assert_contains "$__STDERR" "no worktree found for branch 'nonexistent'" "shows error"
}

it "unlock: shows error for nonexistent branch" test_unlock_nonexistent_branch_shows_error

test_unlock_succeeds() {
  cd "$TEST_REPO"
  __fixture_create_branch "unlock-test"
  wt add unlock-test >/dev/null 2>&1
  wt lock unlock-test >/dev/null 2>&1
  __capture wt unlock unlock-test
  assert_exit_code 0 "returns 0"
  assert_contains "$__STDOUT" "unlocked worktree for 'unlock-test'" "shows success"
}

it "unlock: successfully unlocks worktree" test_unlock_succeeds

test_unlock_not_locked_shows_error() {
  cd "$TEST_REPO"
  __fixture_create_branch "not-locked"
  wt add not-locked >/dev/null 2>&1
  __capture wt unlock not-locked
  assert_neq "$__EXIT_CODE" "0" "returns non-zero when not locked"
}

it "unlock: shows error if not locked" test_unlock_not_locked_shows_error

# ── Round-trip ────────────────────────────────────────────────────────

test_lock_unlock_roundtrip() {
  cd "$TEST_REPO"
  __fixture_create_branch "roundtrip-lock"
  wt add roundtrip-lock >/dev/null 2>&1
  wt lock roundtrip-lock >/dev/null 2>&1
  wt unlock roundtrip-lock >/dev/null 2>&1
  # Should be able to lock again after unlocking
  __capture wt lock roundtrip-lock
  assert_exit_code 0 "can lock again after unlock"
}

it "round-trip: lock then unlock works" test_lock_unlock_roundtrip
