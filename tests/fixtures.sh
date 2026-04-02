#!/usr/bin/env bash

# Test Fixtures — Git repo setup and teardown

# ── Fixture State ─────────────────────────────────────────────────────
TEST_TMPDIR=""
TEST_REPO=""
TEST_BARE_REPO=""
TEST_ORIG_PWD="$PWD"
TEST_ORIG_WT_DIR="${WT_DIR:-}"

# ── Fixture Creation ──────────────────────────────────────────────────

# Create a fresh git repository with initial commit
__fixture_create_repo() {
  TEST_TMPDIR=$(mktemp -d)
  TEST_BARE_REPO="$TEST_TMPDIR/origin.git"
  TEST_REPO="$TEST_TMPDIR/repo"

  # Create bare repo (simulates origin)
  git init --bare "$TEST_BARE_REPO" >/dev/null 2>&1

  # Clone it
  git clone "$TEST_BARE_REPO" "$TEST_REPO" >/dev/null 2>&1
  cd "$TEST_REPO"

  # Make initial commit
  printf 'initial\n' > README.md
  git add README.md
  git commit -m "Initial commit" >/dev/null 2>&1
  git push origin main >/dev/null 2>&1

  # Set up WT_DIR in test tmpdir
  export WT_DIR="$TEST_TMPDIR/treehouse"
  mkdir -p "$WT_DIR"
}

# Create a local branch with a commit
__fixture_create_branch() {
  local branch="$1"
  local safe_name
  safe_name="$(printf '%s' "$branch" | tr '/' '-')"
  git checkout -b "$branch" >/dev/null 2>&1
  printf 'content-%s\n' "$branch" > "file-${safe_name}.txt"
  git add "file-${safe_name}.txt"
  git commit -m "Add $branch" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
}

# Create a remote-only branch (push to bare repo, delete locally)
__fixture_create_remote_branch() {
  local branch="$1"
  git checkout -b "$branch" >/dev/null 2>&1
  printf 'remote-%s\n' "$branch" > "remote-${branch}.txt"
  git add "remote-${branch}.txt"
  git commit -m "Add remote $branch" >/dev/null 2>&1
  git push origin "$branch" >/dev/null 2>&1
  git checkout main >/dev/null 2>&1
  git branch -D "$branch" >/dev/null 2>&1
}

# Create a worktree using wt add
__fixture_create_worktree() {
  local branch="$1"
  wt add "$branch" >/dev/null 2>&1
}

# Make a worktree dirty (add uncommitted file)
__fixture_make_dirty() {
  local wt_path="$1"
  printf 'uncommitted\n' > "$wt_path/dirty.txt"
}

# Create a commit in a worktree
__fixture_commit_in_worktree() {
  local branch="$1"
  local filename="$2"
  local message="$3"
  local wt_path
  # Compute path using the same logic as __wt_branch_to_path
  local safe_branch
  safe_branch="$(printf '%s' "$branch" | sed 's|/|--|g')"
  wt_path="$WT_DIR/origin/$safe_branch"

  printf 'content-%s\n' "$filename" > "$wt_path/$filename"
  git -C "$wt_path" add "$filename"
  git -C "$wt_path" commit -m "$message" >/dev/null 2>&1
}

# ── Fixture Teardown ──────────────────────────────────────────────────

__fixture_teardown() {
  # Return to original directory
  cd "$TEST_ORIG_PWD"

  # Restore original WT_DIR
  if [ -n "$TEST_ORIG_WT_DIR" ]; then
    export WT_DIR="$TEST_ORIG_WT_DIR"
  else
    unset WT_DIR
  fi

  # Clean up temp directory
  if [ -n "$TEST_TMPDIR" ] && [ -d "$TEST_TMPDIR" ]; then
    rm -rf "$TEST_TMPDIR"
  fi

  TEST_TMPDIR=""
  TEST_REPO=""
  TEST_BARE_REPO=""
}
