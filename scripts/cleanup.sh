#!/bin/bash
# cleanup.sh
# Removes all agent worktrees and optionally their branches
#
# Usage: ./cleanup.sh <project> [--keep-branches]
# Example: ./cleanup.sh api
# Example: ./cleanup.sh api --keep-branches

set -e

DEV_DIR="$HOME/Documents/0-DEV"

# Get git username for branch prefix
get_git_username() {
  local name=$(git config user.name 2>/dev/null || echo "")
  if [ -z "$name" ]; then
    echo "dev"
    return
  fi
  echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

PROJECT=${1:-}
KEEP_BRANCHES=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --keep-branches)
      KEEP_BRANCHES=true
      ;;
  esac
done

if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project> [--keep-branches]"
  echo ""
  echo "Examples:"
  echo "  $0 api                 # Remove worktrees and branches"
  echo "  $0 api --keep-branches # Remove worktrees, keep branches"
  exit 1
fi

# Resolve project path
if [ -d "$PROJECT" ]; then
  REPO_ROOT=$(cd "$PROJECT" && git rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT")
elif [ -d "$DEV_DIR/$PROJECT" ]; then
  REPO_ROOT="$DEV_DIR/$PROJECT"
else
  echo "Error: Project '$PROJECT' not found in $DEV_DIR"
  exit 1
fi

REPO_NAME=$(basename "$REPO_ROOT")
GIT_USERNAME=$(get_git_username)
BRANCH_PREFIX="${GIT_USERNAME}/agent"

echo "=== Git Worktrees Cleanup ==="
echo "Repository: $REPO_NAME"
echo "Branch prefix: $BRANCH_PREFIX"
echo "Keep branches: $KEEP_BRANCHES"
echo ""

cd "$REPO_ROOT"

# Find and remove worktrees
WORKTREES=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | grep "${REPO_NAME}-worktree-" || true)

if [ -z "$WORKTREES" ]; then
  echo "No agent worktrees found."
else
  for worktree in $WORKTREES; do
    echo "Removing worktree: $worktree"
    git worktree remove -f "$worktree" 2>/dev/null || rm -rf "$worktree"
  done
fi

# Prune worktree references
git worktree prune

# Remove branches if not keeping them
if [ "$KEEP_BRANCHES" = false ]; then
  echo ""
  echo "Removing agent branches..."

  # Find all agent branches
  BRANCHES=$(git branch --list "${BRANCH_PREFIX}-*" | sed 's/^[* ]*//')

  if [ -z "$BRANCHES" ]; then
    echo "No agent branches found."
  else
    for branch in $BRANCHES; do
      echo "Deleting branch: $branch"
      git branch -D "$branch" 2>/dev/null || echo "  Could not delete $branch (may have unmerged changes)"
    done
  fi
fi

echo ""
echo "=== Cleanup Complete ==="
echo ""
git worktree list
