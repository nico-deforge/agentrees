# Agentrees

Git worktree manager for running parallel Claude Code agents on any project.

## Installation

Add to your global mise config (`~/.config/mise/config.toml`):

```toml
[task_config]
includes = ["~/Documents/0-DEV/agentrees/.mise.toml"]
```

## Usage

### Create worktrees

```bash
# Create 1 worktree (default)
mise run wt:setup api

# Create 3 worktrees
mise run wt:setup api 3

# Create 3 worktrees from specific branch
mise run wt:setup api 3 master
```

### Launch Claude agents

```bash
# Open Ghostty tabs for each worktree
mise run wt:launch api

# Use iTerm instead
mise run wt:launch api --terminal=iterm

# Open tabs without starting Claude
mise run wt:launch api --no-claude
```

### Check status

```bash
mise run wt:status api
```

### Rebase on latest

```bash
mise run wt:rebase api
```

### Cleanup

```bash
# Remove worktrees and branches
mise run wt:cleanup api

# Remove worktrees but keep branches
mise run wt:cleanup api --keep-branches
```

## How It Works

1. **setup** creates git worktrees in the parent directory (`api-worktree-1`, `api-worktree-2`, etc.)
2. Each worktree gets its own branch (`username/agent-1`, `username/agent-2`, etc.)
3. **launch** opens a terminal tab for each worktree
4. Run Claude in each tab to work on parallel tasks

## Supported Terminals

- Ghostty (default)
- iTerm
- Terminal.app

## Projects

Works with any git project in `~/Documents/0-DEV/`:
- api
- hb
- daca
- aura
- nosila
- etc.
