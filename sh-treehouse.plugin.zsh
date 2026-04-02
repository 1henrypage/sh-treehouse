# sh-treehouse zsh plugin
# Loaded automatically by Antigen/zinit/zplug, or source manually in .zshrc

# Add bin/ to PATH (resolves relative to this file's location)
export PATH="${0:A:h}/bin:$PATH"

# Load shell integration: defines wt() wrapper + adds completions to fpath
eval "$(wt init zsh)"
