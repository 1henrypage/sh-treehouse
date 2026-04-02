#!/bin/sh

# ── Color Constants ───────────────────────────────────────────────────
# Respect NO_COLOR convention (https://no-color.org) and non-terminal output
if [ -n "${NO_COLOR:-}" ] || [ ! -t 1 ]; then
  __WT_RED=""
  __WT_GREEN=""
  __WT_YELLOW=""
  __WT_CYAN=""
  __WT_BOLD=""
  __WT_RESET=""
else
  __WT_RED=$(printf '\033[31m')
  __WT_GREEN=$(printf '\033[32m')
  __WT_YELLOW=$(printf '\033[33m')
  __WT_CYAN=$(printf '\033[36m')
  __WT_BOLD=$(printf '\033[1m')
  __WT_RESET=$(printf '\033[0m')
fi

# ── Output Helpers ────────────────────────────────────────────────────
__wt_err()     { printf '%serror:%s %s\n' "$__WT_RED" "$__WT_RESET" "$1" >&2; }
__wt_info()    { printf '%s%s%s\n' "$__WT_CYAN" "$1" "$__WT_RESET"; }
__wt_success() { printf '%s%s%s\n' "$__WT_GREEN" "$1" "$__WT_RESET"; }
