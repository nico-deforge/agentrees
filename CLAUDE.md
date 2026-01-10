# Agentrees

Git worktree manager for running parallel Claude Code agents on any project.

## Project Overview

This repo contains bash scripts and mise tasks to create, manage, and launch git worktrees for parallel Claude agent development.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | Create N worktrees for a project |
| `scripts/cleanup.sh` | Remove worktrees and branches |
| `scripts/rebase.sh` | Rebase all worktrees on base branch |
| `scripts/status.sh` | Show worktree status |
| `scripts/launch.sh` | Open terminals with Claude |

## Key Design Decisions

- Scripts accept project name or path as first argument
- Projects are resolved from `$AGENTREES_DEV_DIR` if set
- Default: 1 worktree (not 5 like the API version)
- Base branch is auto-detected (main or master)
- Minimal init: only runs `mise trust`, no dependency sync
- Ghostty is the default terminal

## When Modifying

- Keep scripts POSIX-compatible where possible
- Test with multiple projects
- Ensure absolute paths work when run from any directory
