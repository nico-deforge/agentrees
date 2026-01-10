#!/bin/bash
# setup.sh
# Creates N git worktrees for parallel Claude Code agents
#
# Usage: ./setup.sh <project> [number_of_worktrees] [base_branch]
# Example: ./setup.sh api
# Example: ./setup.sh api 3
# Example: ./setup.sh api 3 master
#
# Branch prefix is auto-generated from git user.name (e.g., "nd" -> "nd/agent")

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

# Detect default branch (master or main)
detect_default_branch() {
  local repo_path="$1"
  cd "$repo_path"
  if git show-ref --verify --quiet refs/heads/main; then
    echo "main"
  elif git show-ref --verify --quiet refs/heads/master; then
    echo "master"
  else
    # Fallback: check remote
    git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5 || echo "main"
  fi
}

# Arguments
PROJECT=${1:-}
NUM_WORKTREES=${2:-1}
BASE_BRANCH=${3:-}

if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project> [number_of_worktrees] [base_branch]"
  echo ""
  echo "Examples:"
  echo "  $0 api           # Create 1 worktree for api project"
  echo "  $0 api 3         # Create 3 worktrees"
  echo "  $0 api 3 master  # Create 3 worktrees from master"
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
PARENT_DIR=$(dirname "$REPO_ROOT")
GIT_USERNAME=$(get_git_username)
BRANCH_PREFIX="${GIT_USERNAME}/agent"

echo "=== Git Worktrees Setup ==="
echo "Repository: $REPO_NAME"
echo "Base branch: $BASE_BRANCH"
echo "Number of worktrees: $NUM_WORKTREES"
echo "Branch prefix: $BRANCH_PREFIX"
echo ""

cd "$REPO_ROOT"

# Fetch latest changes
echo "Fetching latest changes..."
git fetch origin "$BASE_BRANCH" 2>/dev/null || git fetch origin

for i in $(seq 1 "$NUM_WORKTREES"); do
  WORKTREE_PATH="$PARENT_DIR/${REPO_NAME}-worktree-$i"
  BRANCH_NAME="${BRANCH_PREFIX}-$i"

  # Check if worktree already exists
  if [ -d "$WORKTREE_PATH" ]; then
    echo "[$i/$NUM_WORKTREES] Worktree already exists: $WORKTREE_PATH (skipping)"
    continue
  fi

  # Check if branch already exists
  if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo "[$i/$NUM_WORKTREES] Branch $BRANCH_NAME exists, creating worktree..."
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
  else
    echo "[$i/$NUM_WORKTREES] Creating branch $BRANCH_NAME and worktree..."
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$BASE_BRANCH"
  fi

  # Initialize the worktree environment (minimal: mise trust only)
  echo "  Initializing environment..."
  (
    cd "$WORKTREE_PATH"

    # Trust mise config if .mise.toml exists
    if [ -f ".mise.toml" ] || [ -f "mise.toml" ]; then
      echo "    - mise trust"
      mise trust --quiet 2>/dev/null || mise trust
    fi
  )
  echo "  Done!"
done

echo ""
echo "=== Setup Complete ==="
echo ""
git worktree list
echo ""
echo "Next steps:"
echo "  - cd $PARENT_DIR/${REPO_NAME}-worktree-1 && claude"
echo "  - Or run: mise run wt:launch $PROJECT"
