# sh-treehouse

<p align="center"><img src="assets/banner.png" width="600" alt="treehouse banner"></p>

A shell plugin that makes git worktrees easy to use. Supports bash and zsh. Stop stashing — start using worktrees.

## Installation

### Zsh — Antigen

```sh
antigen bundle 1henrypage/sh-treehouse --branch=main
```

### Zsh — Manual

Clone the repo and source it in your `.zshrc`:

```sh
source /path/to/sh-treehouse/sh-treehouse.plugin.zsh
```

> **Note:** The source line must come **before** `compinit` for tab completion to work.

### Bash

Add to your `.bashrc`:

```sh
export PATH="/path/to/sh-treehouse/bin:$PATH"
eval "$(wt init bash)"
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `WT_DIR` | `~/.treehouse` | Base directory where worktrees are stored |
| `NO_COLOR` | unset | Set to any value to disable colored output |

Set in your rc file before sourcing the plugin:

```sh
export WT_DIR="$HOME/.treehouse"
```

## How It Works

Worktrees are created under `$WT_DIR/<repo-name>/<branch>`. The repo name is derived from the `origin` remote URL.

Branch names with slashes are flattened using `--` as a separator:

| Branch | Directory |
|---|---|
| `main` | `~/.treehouse/myrepo/main` |
| `feature/login` | `~/.treehouse/myrepo/feature--login` |
| `fix/auth/token` | `~/.treehouse/myrepo/fix--auth--token` |

## Commands

### Lifecycle

| Command | Description |
|---|---|
| `wt add <branch>` | Create and checkout a worktree for a branch |
| `wt rm [-f] [-y] <branch>` | Remove a worktree (prompts to delete branch; `-y` skips prompt) |
| `wt ls` | List all worktrees with status |
| `wt checkout <branch>` | Change directory to a worktree |
| `wt base` | Change directory back to the main repo |
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

## Examples

### Basic Usage

```sh
# Create a worktree for a hotfix (automatically checks out to it)
wt add hotfix/payment-bug

# List your worktrees
wt ls

# Jump to another worktree
wt checkout other-branch

# Go back to main repo
wt base

# Run tests in a worktree without leaving your current directory
wt run hotfix/payment-bug "make test"

# Check status of all worktrees at once
wt status

# Remove when done (will ask about deleting the branch too)
wt rm hotfix/payment-bug

# Remove without prompting for branch deletion
wt rm -y hotfix/payment-bug
```

### Multi-Agent Workflow

Use worktrees to isolate work from multiple AI agents or parallel tasks:

```sh
# Agent 1: Create worktree and make changes
wt add agent-feature-a
wt run agent-feature-a "make changes && git commit -am 'Add feature A'"

# Agent 2: Create another worktree
wt add agent-feature-b
wt run agent-feature-b "make changes && git commit -am 'Add feature B'"
```

## Tab Completion

Full zsh completion is included (zsh only). Press `<TAB>` after any subcommand:

- `wt <TAB>` — shows all subcommands
- `wt add <TAB>` — shows available branches (excludes already checked-out)
- `wt checkout <TAB>` — shows existing worktree branches
- `wt lock <TAB>` — shows only unlocked worktrees
- `wt unlock <TAB>` — shows only locked worktrees

## License

MIT
