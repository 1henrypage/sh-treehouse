#!/bin/sh

# ── Shell Init Templates ───────────────────────────────────────────────
# wt init <shell> — outputs shell integration code to eval in rc files

__wt_cmd_init() {
  local shell="${1:-}"
  case "$shell" in
    zsh)  __wt_init_zsh ;;
    bash) __wt_init_bash ;;
    "")   __wt_err "usage: wt init <shell>"; __wt_err "supported shells: zsh, bash"; return 1 ;;
    *)    __wt_err "unsupported shell: $shell"; __wt_err "supported shells: zsh, bash"; return 1 ;;
  esac
}

__wt_init_zsh() {
  # Resolve the completions directory relative to the bin/ directory
  local completions_dir
  completions_dir="$(cd "$WT_SCRIPT_DIR/../completions" 2>/dev/null && pwd)"

  if [ -n "$completions_dir" ]; then
    printf 'fpath=(%s $fpath)\n' "'${completions_dir}'"
  fi

  # The wt() function captures stdout looking for __wt_cd: directives.
  # Stderr (errors) flows through directly without capture.
  cat <<'EOF'
wt() {
  local _wt_line _wt_out _wt_cd="" _wt_ec _wt_color=""
  [ -t 1 ] && _wt_color=1
  _wt_out="$(__WT_EVAL_MODE=1 __WT_COLOR=$_wt_color command wt "$@")"
  _wt_ec=$?
  while IFS= read -r _wt_line; do
    case "$_wt_line" in
      __wt_cd:*) _wt_cd="${_wt_line#__wt_cd:}" ;;
      *) printf '%s\n' "$_wt_line" ;;
    esac
  done <<< "$_wt_out"
  [ -n "$_wt_cd" ] && cd "$_wt_cd"
  return $_wt_ec
}
compdef _wt wt
EOF
}

__wt_init_bash() {
  cat <<'EOF'
wt() {
  local _wt_line _wt_out _wt_cd="" _wt_ec _wt_color=""
  [ -t 1 ] && _wt_color=1
  _wt_out="$(__WT_EVAL_MODE=1 __WT_COLOR=$_wt_color command wt "$@")"
  _wt_ec=$?
  while IFS= read -r _wt_line; do
    case "$_wt_line" in
      __wt_cd:*) _wt_cd="${_wt_line#__wt_cd:}" ;;
      *) printf '%s\n' "$_wt_line" ;;
    esac
  done <<< "$_wt_out"
  [ -n "$_wt_cd" ] && cd "$_wt_cd"
  return $_wt_ec
}
EOF
}
