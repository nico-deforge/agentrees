#!/bin/bash
# rebase.sh
# Rebases all agent worktrees on the base branch
#
# Usage: ./rebase.sh <project> [base_branch]
# Example: ./rebase.sh api
# Example: ./rebase.sh api master

set -e

DEV_DIR="$HOME/Documents/0-DEV"

# Detect default branch (master or main)
detect_default_branch() {
  local repo_path="$1"
  cd "$repo_path"
  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5 || echo "main"
  fi
}

PROJECT=${1:-}
BASE_BRANCH=${2:-}

if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project> [base_branch]"
  echo ""
  echo "Examples:"
  echo "  $0 api         # Rebase on auto-detected default branch"
  echo "  $0 api master  # Rebase on master"
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

# Auto-detect base branch if not specified
if [ -z "$BASE_BRANCH" ]; then
  BASE_BRANCH=$(detect_default_branch "$REPO_ROOT")
fi

REPO_NAME=$(basename "$REPO_ROOT")

echo "=== Git Worktrees Rebase ==="
echo "Repository: $REPO_NAME"
echo "Base branch: $BASE_BRANCH"
echo ""

cd "$REPO_ROOT"

# Fetch latest changes
echo "Fetching latest changes..."
git fetch origin "$BASE_BRANCH"
echo ""

# Find all agent worktrees
WORKTREES=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | grep "${REPO_NAME}-worktree-" || true)

if [ -z "$WORKTREES" ]; then
  echo "No agent worktrees found."
  exit 0
fi

FAILED=()

for worktree in $WORKTREES; do
  worktree_name=$(basename "$worktree")
  echo "=== Rebasing $worktree_name ==="

  cd "$worktree"

  # Check for uncommitted changes
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "  WARNING: Uncommitted changes detected, skipping rebase"
    FAILED+=("$worktree_name (uncommitted changes)")
    continue
  fi

  # Perform rebase
  if git rebase "origin/$BASE_BRANCH"; then
    echo "  Rebased successfully"
  else
    echo "  CONFLICT: Rebase failed, aborting..."
    git rebase --abort
    FAILED+=("$worktree_name (conflicts)")
  fi

  echo ""
done

# Return to original directory
cd "$REPO_ROOT"

echo "=== Rebase Complete ==="

if [ ${#FAILED[@]} -gt 0 ]; then
  echo ""
  echo "Failed worktrees:"
  for f in "${FAILED[@]}"; do
    echo "  - $f"
  done
  exit 1
fi
