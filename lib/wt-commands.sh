#!/bin/sh

# ── Subcommands ───────────────────────────────────────────────────────

__wt_cmd_add() {
  local branch="${1:-}"
  [ -z "$branch" ] && { __wt_err "usage: wt add <branch>"; return 1; }
  __wt_ensure_git_repo || return 1

  local target
  target="$(__wt_branch_to_path "$branch")"

  if [ -d "$target" ]; then
    __wt_err "worktree already exists at $target"
    return 1
  fi

  mkdir -p "$(dirname "$target")"

  if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
    # Local branch exists
    git worktree add "$target" "$branch"
  else
    # Check for a remote tracking branch
    local remote_ref
    remote_ref="$(git for-each-ref --format='%(refname:short)' "refs/remotes/*/$branch" 2>/dev/null | head -1)"
    if [ -n "$remote_ref" ]; then
      git worktree add --track -b "$branch" "$target" "$remote_ref"
    else
      # Brand new branch off HEAD
      git worktree add -b "$branch" "$target"
    fi
  fi

  local rc=$?
  if [ "$rc" -eq 0 ]; then
    __wt_success "created worktree for '$branch' at $target"
    __wt_do_cd "$target"
  fi
  return $rc
}

__wt_cmd_rm() {
  local force=0 yes=0 branch=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force) force=1; shift ;;
      -y|--yes)   yes=1;   shift ;;
      *) branch="$1"; shift ;;
    esac
  done

  [ -z "$branch" ] && { __wt_err "usage: wt rm [-f|--force] <branch>"; return 1; }
  __wt_ensure_git_repo || return 1

  local wt_path
  wt_path="$(__wt_resolve_worktree_path "$branch")"
  [ -z "$wt_path" ] && { __wt_err "no worktree found for branch '$branch'"; return 1; }

  if [ "$force" = 1 ]; then
    git worktree remove --force "$wt_path" || return 1
  else
    git worktree remove "$wt_path" || return 1
  fi
  __wt_success "removed worktree at $wt_path"

  # Offer to delete the branch
  local reply
  if [ "$yes" = 1 ]; then
    reply="y"
  else
    printf "Also delete branch '%s'? [y/N] " "$branch" >&2
    read -r reply </dev/tty
  fi
  case "$reply" in
    [yY])
      if [ "$force" = 1 ]; then
        git branch -D "$branch" 2>/dev/null
      else
        git branch -d "$branch" 2>/dev/null
      fi
      if [ $? -eq 0 ]; then
        __wt_success "deleted branch '$branch'"
      else
        __wt_err "could not delete branch '$branch' (not fully merged? use -f)"
      fi
      ;;
  esac
}

__wt_print_ls_entry() {
  local wt_path="$1" head="$2" branch="$3" locked="$4" prunable="$5"
  local status_icon lock_icon=""
  if [ "$prunable" = 1 ]; then
    status_icon="${__WT_RED}prunable${__WT_RESET}"
  elif __wt_is_dirty "$wt_path"; then
    status_icon="${__WT_RED}*${__WT_RESET}"
  else
    status_icon="${__WT_GREEN}ok${__WT_RESET}"
  fi
  if [ "$locked" = 1 ]; then
    lock_icon="  ${__WT_YELLOW}[locked]${__WT_RESET}"
  fi
  printf '  %s%s%s  %s%s%s  %s  %s%s\n' \
    "$__WT_BOLD$__WT_CYAN" "${branch:-(detached)}" "$__WT_RESET" \
    "$__WT_YELLOW" "$head" "$__WT_RESET" \
    "$wt_path" "$status_icon" "$lock_icon"
}

__wt_cmd_ls() {
  __wt_ensure_git_repo || return 1

  local wt_path="" head="" branch="" locked=0 prunable=0 has_entries=0
  local tmpfile
  tmpfile="$(mktemp)"
  git worktree list --porcelain 2>/dev/null > "$tmpfile"

  while IFS= read -r line; do
    case "$line" in
      "worktree "*) wt_path="${line#worktree }" ;;
      "HEAD "*)
        head="${line#HEAD }"
        head="$(printf '%.7s' "$head")"
        ;;
      "branch "*) branch="${line#branch refs/heads/}" ;;
      locked*)    locked=1 ;;
      prunable*)  prunable=1 ;;
      "")
        if [ -n "$wt_path" ]; then
          has_entries=1
          __wt_print_ls_entry "$wt_path" "$head" "$branch" "$locked" "$prunable"
        fi
        wt_path=""; head=""; branch=""; locked=0; prunable=0
        ;;
    esac
  done < "$tmpfile"

  # Handle final entry (porcelain doesn't end with blank line)
  if [ -n "$wt_path" ]; then
    has_entries=1
    __wt_print_ls_entry "$wt_path" "$head" "$branch" "$locked" "$prunable"
  fi
  rm -f "$tmpfile"

  if [ "$has_entries" -eq 0 ]; then
    __wt_info "no worktrees found"
  fi
}

__wt_cmd_checkout() {
  local branch="${1:-}"
  [ -z "$branch" ] && { __wt_err "usage: wt checkout <branch>"; return 1; }
  __wt_ensure_git_repo || return 1

  local wt_path
  wt_path="$(__wt_resolve_worktree_path "$branch")"
  [ -z "$wt_path" ] && { __wt_err "no worktree found for branch '$branch'"; return 1; }

  __wt_do_cd "$wt_path"
}

__wt_cmd_base() {
  __wt_ensure_git_repo || return 1
  local mainroot
  mainroot="$(__wt_main_root)"
  __wt_do_cd "$mainroot"
}

__wt_cmd_prune() {
  __wt_ensure_git_repo || return 1
  git worktree prune -v
}

__wt_print_status_entry() {
  local wt_path="$1" branch="$2"
  printf '\n%s%s%s  (%s)\n' "$__WT_BOLD$__WT_CYAN" "$branch" "$__WT_RESET" "$wt_path"
  local st
  st="$(git -C "$wt_path" status --short 2>/dev/null)"
  if [ -z "$st" ]; then
    printf '  %sclean%s\n' "$__WT_GREEN" "$__WT_RESET"
  else
    printf '%s\n' "$st" | while IFS= read -r sline; do
      printf '  %s\n' "$sline"
    done
  fi
}

__wt_cmd_status() {
  __wt_ensure_git_repo || return 1

  local wt_path="" branch="" has_entries=0
  local tmpfile
  tmpfile="$(mktemp)"
  git worktree list --porcelain 2>/dev/null > "$tmpfile"

  while IFS= read -r line; do
    case "$line" in
      "worktree "*) wt_path="${line#worktree }" ;;
      "branch "*)   branch="${line#branch refs/heads/}" ;;
      "")
        if [ -n "$wt_path" ] && [ -n "$branch" ]; then
          has_entries=1
          __wt_print_status_entry "$wt_path" "$branch"
        fi
        wt_path=""; branch=""
        ;;
    esac
  done < "$tmpfile"

  # Handle final entry
  if [ -n "$wt_path" ] && [ -n "$branch" ]; then
    has_entries=1
    __wt_print_status_entry "$wt_path" "$branch"
  fi
  rm -f "$tmpfile"

  if [ "$has_entries" -eq 0 ]; then
    __wt_info "no worktrees found"
  fi
}

__wt_cmd_lock() {
  local branch="${1:-}"
  [ -z "$branch" ] && { __wt_err "usage: wt lock <branch>"; return 1; }
  __wt_ensure_git_repo || return 1

  local wt_path
  wt_path="$(__wt_resolve_worktree_path "$branch")"
  [ -z "$wt_path" ] && { __wt_err "no worktree found for branch '$branch'"; return 1; }

  git worktree lock "$wt_path" && __wt_success "locked worktree for '$branch'"
}

__wt_cmd_unlock() {
  local branch="${1:-}"
  [ -z "$branch" ] && { __wt_err "usage: wt unlock <branch>"; return 1; }
  __wt_ensure_git_repo || return 1

  local wt_path
  wt_path="$(__wt_resolve_worktree_path "$branch")"
  [ -z "$wt_path" ] && { __wt_err "no worktree found for branch '$branch'"; return 1; }

  git worktree unlock "$wt_path" && __wt_success "unlocked worktree for '$branch'"
}

__wt_cmd_run() {
  local branch="${1:-}"
  [ -z "$branch" ] && { __wt_err "usage: wt run <branch> <command...>"; return 1; }
  shift
  [ $# -eq 0 ] && { __wt_err "usage: wt run <branch> <command...>"; return 1; }
  __wt_ensure_git_repo || return 1

  local wt_path
  wt_path="$(__wt_resolve_worktree_path "$branch")"
  [ -z "$wt_path" ] && { __wt_err "no worktree found for branch '$branch'"; return 1; }

  # Run in a subshell so we don't change the current directory
  (cd "$wt_path" && eval "$@")
}

__wt_cmd_help() {
  printf '%swt%s - git worktree manager\n\n' "$__WT_BOLD" "$__WT_RESET"
  printf 'Usage: wt <command> [args]\n\n'
  printf 'Commands:\n'
  printf '  add <branch>          Create and checkout a worktree for a branch\n'
  printf '  rm [-f] <branch>      Remove a worktree (optionally delete branch)\n'
  printf '  ls                    List worktrees with status\n'
  printf '  checkout <branch>     Change to a worktree directory\n'
  printf '  base                  Change to the main repo directory\n'
  printf '  prune                 Clean up stale worktree references\n'
  printf '  status                Show git status across all worktrees\n'
  printf '  lock <branch>         Lock a worktree\n'
  printf '  unlock <branch>       Unlock a worktree\n'
  printf '  run <branch> <cmd>    Run a command in a worktree\n'
  printf '  init <shell>          Output shell integration code (eval this in your rc file)\n'
  printf '  help                  Show this help\n'
  printf '\n'
  printf 'Shell integration:\n'
  printf '  eval "$(wt init zsh)"   # Add to .zshrc\n'
  printf '  eval "$(wt init bash)"  # Add to .bashrc\n'
  printf '\n'
  printf 'Config:\n'
  printf '  WT_DIR                Worktree base directory (default: ~/.treehouse)\n'
}
