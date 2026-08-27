# sh-treehouse

<p align="center"><img src="assets/banner.png" width="600" alt="treehouse banner"></p>

[![Tests](https://github.com/1henrypage/sh-treehouse/actions/workflows/test.yml/badge.svg)](https://github.com/1henrypage/sh-treehouse/actions/workflows/test.yml)

`wt` wraps `git worktree` in a shorter command set. It keeps every worktree for a
repository under one directory, moves your shell into them, and reports the state
of all of them at once. Works in zsh and bash.

`git worktree` handles the mechanics but leaves you to invent a path for each
checkout and to `cd` there yourself. `wt` decides the path and moves the shell.

## Requirements

- git 2.17 or later. `wt rm` relies on `git worktree remove`, added in that release.
- git 2.36 or later for the `[locked]` and `prunable` indicators in `wt ls`. Older
  git omits those fields from `git worktree list --porcelain`, so those worktrees
  just show `ok`.
- zsh or bash.

## Installation

### Zsh - Antigen

```sh
antigen bundle 1henrypage/sh-treehouse --branch=main
```

### Zsh - zinit / zplug

```sh
zinit light 1henrypage/sh-treehouse
```

or

```sh
zplug "1henrypage/sh-treehouse"
```

### Zsh - manual

Clone the repo and source the plugin file in your `.zshrc`, before `compinit`:

```sh
source /path/to/sh-treehouse/sh-treehouse.plugin.zsh
autoload -Uz compinit && compinit
```

Sourcing first puts the completions directory on `fpath` in time for `compinit`
to find it. It also means the plugin's own `compdef _wt wt` line runs before
`compdef` exists, so you'll see one harmless `compdef: command not found` when the
shell starts. Completion still works: `completions/_wt` starts with `#compdef wt`,
so `compinit` registers it directly when it autoloads the file.

### Bash

Add to your `.bashrc`:

```sh
export PATH="/path/to/sh-treehouse/bin:$PATH"
eval "$(wt init bash)"
```

Bash gets the `wt` shell function that handles `cd` for `add`, `checkout`, and
`base`. There's no bash completion; `completions/_wt` is zsh-only.

## Quick start

```sh
wt add hotfix/payment-bug
```

Creates a worktree for the branch and moves you into it.

```sh
wt add other-branch
wt ls
```

Lists every worktree for the repo, with its status.

```sh
wt run hotfix/payment-bug 'npm test'
```

Runs a command inside a worktree without moving you there.

```sh
wt checkout other-branch
wt base
```

Moves between worktrees, and back to the main repo.

```sh
wt rm -y hotfix/payment-bug
```

Removes the worktree and deletes the branch. `-y` skips the confirmation and
always deletes - use it once you're sure.

## Commands

### Lifecycle

| Command | Description |
|---|---|
| `wt add <branch>` | Create a worktree for a branch and move into it |
| `wt rm [-f] [-y] <branch>` | Remove a worktree; `-y` also deletes the branch |
| `wt ls` | List all worktrees with their status |
| `wt checkout <branch>` | Move into an existing worktree |
| `wt base` | Move back to the main repo |
| `wt prune` | Clean up stale worktree references |
| `wt status` | Show git status across all worktrees |
| `wt lock <branch>` | Lock a worktree to prevent removal |
| `wt unlock <branch>` | Unlock a locked worktree |
| `wt run <branch> <cmd>` | Run a command inside a worktree |

### Setup

| Command | Description |
|---|---|
| `wt init <shell>` | Print shell integration code for eval (zsh or bash) |
| `wt help` | Show help |

**`wt add`** resolves the branch in three steps: an existing local branch is
checked out as-is, a remote-only branch becomes a local branch tracking it, and
anything else becomes a new branch off `HEAD`. It doesn't fetch first, so a branch
that only exists on the remote and hasn't been fetched yet won't be found.

**`wt ls`** shows a status for each worktree: `ok` for clean, `*` for uncommitted
changes, `prunable` for a worktree whose directory is gone, and `[locked]`
alongside any of those for a locked worktree.

**`wt rm`** prompts before deleting the branch, and reads that prompt from
`/dev/tty` rather than stdin, so piping `y` into it does nothing. It also only
accepts a single `y` or `Y`. `-y` answers yes without a prompt, which means it
deletes the branch - the scriptable path, but a destructive one, so use it
deliberately.

**`wt run`** passes your command to `eval`, not `exec`, so it's re-parsed by the
shell. Quote it as one argument if it has spaces or shell operators:
`wt run my-branch 'npm test && npm run build'`.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `WT_DIR` | `~/.treehouse` | Base directory where worktrees are stored |
| `NO_COLOR` | unset | Set to any value to disable coloured output |

`wt` reads `WT_DIR` fresh on every invocation, so you can set it in your rc file,
export it for a single shell session, or override it per command:

```sh
WT_DIR=/tmp/worktrees wt add experiment
```

## How it works

Worktrees live under `$WT_DIR/<repo-name>/<branch>`. The repo name comes from the
`origin` remote's URL; if there's no `origin`, it falls back to the basename of
the main repo's root directory.

Branch names with slashes are flattened with `--`:

| Branch | Directory |
|---|---|
| `main` | `~/.treehouse/myrepo/main` |
| `feature/login` | `~/.treehouse/myrepo/feature--login` |
| `fix/auth/token` | `~/.treehouse/myrepo/fix--auth--token` |

`wt checkout`, `wt add`, and `wt base` move your shell by emitting a marker that
the `wt()` shell function, installed by `wt init`, catches and turns into a `cd`.
If you run `wt` directly without that function on your `PATH` - for example by
calling `command wt`, or by skipping `wt init` entirely - these commands print
`Run: cd <path>` instead of moving you there.

## Tab completion

Zsh gets completion for every subcommand, including `wt init <TAB>` (offers `zsh`
and `bash`) and `wt rm -<TAB>` (offers `-f`/`--force` and `-y`/`--yes`). Press
`<TAB>` after any subcommand:

- `wt <TAB>` - every subcommand
- `wt add <TAB>` - branches available to add, excluding ones already checked out
- `wt checkout <TAB>` - branches with an existing worktree
- `wt lock <TAB>` - worktrees that aren't locked
- `wt unlock <TAB>` - worktrees that are locked

Bash has no completion; `completions/_wt` is zsh-only.

## Testing

```sh
bash tests/run_all.sh
```

Runs the full test suite and prints TAP output. CI runs the same command on
Ubuntu and macOS for every pull request.

## License

MIT
