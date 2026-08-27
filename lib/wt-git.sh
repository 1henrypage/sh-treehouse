#!/bin/sh

# ── Internal Helpers ──────────────────────────────────────────────────

# Check that we are inside a git repository
__wt_ensure_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1 || {
    __wt_err "not inside a git repository"
    return 1
  }
}

# Get the repository name from the remote URL or directory basename
__wt_repo_name() {
  local url
  url="$(git remote get-url origin 2>/dev/null)"
  if [ -n "$url" ]; then
    local name="${url##*/}"
    printf '%s\n' "${name%.git}"
    return
  fi
  # Fallback: basename of main repo root
  printf '%s\n' "$(basename "$(__wt_main_root)")"
}

# Get the absolute path to the main repository root
# Works from both the main worktree and linked worktrees
__wt_main_root() {
  local commondir
  commondir="$(git rev-parse --git-common-dir 2>/dev/null)"
  case "$commondir" in
    /*)
      # Absolute path — we're in a linked worktree
      printf '%s\n' "$(dirname "$commondir")"
      ;;
    *)
      # Relative path (.git) — we're in the main worktree
      printf '%s\n' "$(git rev-parse --show-toplevel)"
      ;;
  esac
}

# Convert a branch name to its worktree directory path
# Slashes in branch names are replaced with -- (e.g. feature/login -> feature--login)
__wt_branch_to_path() {
  local branch="$1"
  local repo_name safe_branch
  repo_name="$(__wt_repo_name)"
  safe_branch="$(printf '%s' "$branch" | sed 's|/|--|g')"
  printf '%s/%s/%s\n' "$WT_DIR" "$repo_name" "$safe_branch"
}

# Given a branch name, find the worktree path
# Tries the computed conventional path first, then scans git worktree list
__wt_resolve_worktree_path() {
  local branch="$1"
  # Strategy 1: check the conventional path
  local expected
  expected="$(__wt_branch_to_path "$branch")"
  if [ -d "$expected" ]; then
    printf '%s\n' "$expected"
    return
  fi
  # Strategy 2: scan porcelain output for matching branch
  local tmpfile wt_path="" cur_branch="" found=""
  tmpfile="$(mktemp)"
  git worktree list --porcelain 2>/dev/null > "$tmpfile"
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) wt_path="${line#worktree }" ;;
      "branch "*)   cur_branch="${line#branch refs/heads/}" ;;
      "")
        if [ "$cur_branch" = "$branch" ] && [ -n "$wt_path" ]; then
          found="$wt_path"
        fi
        wt_path=""; cur_branch=""
        ;;
    esac
  done < "$tmpfile"
  # Handle final entry (porcelain doesn't always end with blank line)
  if [ -z "$found" ] && [ "$cur_branch" = "$branch" ] && [ -n "$wt_path" ]; then
    found="$wt_path"
  fi
  rm -f "$tmpfile"
  printf '%s\n' "${found:-}"
}

# Check if a worktree path has uncommitted changes
__wt_is_dirty() {
  local wt_path="$1"
  [ -n "$(git -C "$wt_path" status --porcelain 2>/dev/null)" ]
}

# Signal a cd to the shell wrapper, or print a hint when running standalone
__wt_do_cd() {
  local target="$1"
  if [ -n "${__WT_EVAL_MODE:-}" ]; then
    printf '__wt_cd:%s\n' "$target"
  else
    printf 'Run: cd %s\n' "$target"
  fi
}
