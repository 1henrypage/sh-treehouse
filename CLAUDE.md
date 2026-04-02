# sh-treehouse — Project Context

## What This Is

A POSIX sh plugin (`sh-treehouse`) that wraps `git worktree` into a concise `wt <subcommand>` interface. Supports both bash and zsh. Loaded via Antigen/zinit (zsh) or manually via PATH + eval (bash). Worktrees are stored in `$WT_DIR/<repo-name>/<branch>` (default `~/.treehouse`).

## File Structure

```
bin/wt                     # POSIX sh dispatcher — entry point, routes to subcommands
lib/wt-output.sh           # Color constants and output helpers (__wt_err, __wt_info, __wt_success)
lib/wt-git.sh              # Git helper functions (__wt_repo_name, __wt_resolve_worktree_path, etc.)
lib/wt-commands.sh         # All __wt_cmd_* subcommand implementations
lib/wt-init.sh             # Shell integration templates (wt init zsh|bash)
completions/_wt            # Zsh completion function (discovered via fpath)
sh-treehouse.plugin.zsh    # Zsh plugin loader (adds bin/ to PATH, evals wt init zsh)
README.md                  # User documentation
CLAUDE.md                  # This file
LICENSE                    # MIT
tests/                     # Bash test suite (run via: bash tests/run_all.sh)
```

## Coding Conventions

- **Language:** POSIX sh in `bin/` and `lib/`; zsh-specific code only in `sh-treehouse.plugin.zsh` and `completions/_wt`
- **Internal functions:** Prefixed `__wt_` (double underscore) to avoid namespace pollution
- **Subcommand functions:** Named `__wt_cmd_<name>` in `lib/wt-commands.sh`
- **Output:** Use `printf` with raw ANSI escapes for colored output; respects `NO_COLOR` and non-tty detection
- **Errors:** Go to stderr via `>&2`, always return non-zero
- **Temp files:** Used for porcelain parsing (no process substitution in POSIX sh): `mktemp`, read, then `rm -f`
- **Porcelain parsing:** `git worktree list --porcelain` doesn't end with a trailing blank line — always handle the final entry after the loop

## The `__wt_cd:` Protocol

Because `bin/wt` runs as a subprocess (not a sourced function), it cannot `cd` the parent shell. The `wt init <shell>` command emits a shell wrapper function `wt()` that:

1. Sets `__WT_EVAL_MODE=1` and captures all stdout from `command wt "$@"`
2. Scans output lines for those prefixed with `__wt_cd:`
3. Strips those lines from displayed output and calls `cd` on the path
4. Returns the exit code from the subprocess

Commands that change directory (`wt add`, `wt checkout`, `wt base`) emit `__wt_cd:/path` to stdout. The `__WT_EVAL_MODE` variable signals to `bin/wt` that it is running through this wrapper.

## Key Gotchas

- `wt checkout`, `wt add`, and `wt base` change shell directory via the `__wt_cd:` protocol above — not by being sourced
- `wt add` automatically checks out to the newly created worktree
- `wt run` uses a **subshell** `(cd ... && eval ...)` deliberately to NOT change the directory
- Branch slashes become `--` in directory names: `feature/login` -> `feature--login` (via `sed 's|/|--|g'`)
- The plugin never needs to reverse-map directory names to branches — it uses `git worktree list --porcelain` which has real branch names
- `fpath` setup in the plugin loader must happen before `compinit` — Antigen handles this, but manual zsh users need to be aware

## How to Test

Run the full test suite:

```sh
bash tests/run_all.sh
```

Manual smoke test (zsh):

```zsh
source ./sh-treehouse.plugin.zsh
wt help
wt add test-branch
wt ls
wt checkout test-branch
wt base
wt status
wt run test-branch git log -3
wt lock test-branch
wt unlock test-branch
wt rm test-branch
```

Manual smoke test (bash):

```bash
export PATH="$(pwd)/bin:$PATH"
eval "$(wt init bash)"
wt help
wt add test-branch
wt ls
wt checkout test-branch
wt base
wt rm test-branch
```

Error cases to verify:
- `wt ls` outside a git repo — should print "not inside a git repository"
- `wt checkout nonexistent` — should print "no worktree found"
- `wt add` with no args — should print usage
- `wt integrate` with uncommitted changes — should refuse
- `wt reset` with dirty worktree — should refuse unless `-f` flag used

## Configuration

- `WT_DIR` env var controls base directory (default `~/.treehouse`)
- `NO_COLOR` env var disables colored output when set
