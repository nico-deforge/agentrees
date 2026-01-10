#!/bin/bash
# status.sh
# Shows the status of all agent worktrees
#
# Usage: ./status.sh <project> [base_branch]
# Example: ./status.sh api
# Example: ./status.sh api master

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
  echo "  $0 api         # Show status"
  echo "  $0 api master  # Compare against master"
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

echo "=== Git Worktrees Status ==="
echo "Repository: $REPO_NAME"
echo "Base branch: $BASE_BRANCH"
echo ""

cd "$REPO_ROOT"

# Fetch to get accurate ahead/behind counts
git fetch origin "$BASE_BRANCH" 2>/dev/null

# Find all agent worktrees
WORKTREES=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | grep "${REPO_NAME}-worktree-" || true)

if [ -z "$WORKTREES" ]; then
  echo "No agent worktrees found."
  echo ""
  echo "Create worktrees with: mise run wt:setup $PROJECT"
  exit 0
fi

for worktree in $WORKTREES; do
  worktree_name=$(basename "$worktree")

  cd "$worktree"

  # Get current branch
  branch=$(git rev-parse --abbrev-ref HEAD)

  # Get ahead/behind counts
  ahead=$(git rev-list --count "origin/$BASE_BRANCH..HEAD" 2>/dev/null || echo "?")
  behind=$(git rev-list --count "HEAD..origin/$BASE_BRANCH" 2>/dev/null || echo "?")

  # Get status summary
  modified=$(git diff --name-only | wc -l | tr -d ' ')
  staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
  untracked=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

  # Format status
  status_parts=()
  [ "$ahead" != "0" ] && [ "$ahead" != "?" ] && status_parts+=("${ahead} ahead")
  [ "$behind" != "0" ] && [ "$behind" != "?" ] && status_parts+=("${behind} behind")
  [ "$modified" != "0" ] && status_parts+=("${modified} modified")
  [ "$staged" != "0" ] && status_parts+=("${staged} staged")
  [ "$untracked" != "0" ] && status_parts+=("${untracked} untracked")

  if [ ${#status_parts[@]} -eq 0 ]; then
    status_str="clean"
  else
    status_str=$(IFS=', '; echo "${status_parts[*]}")
  fi

  # Get last commit info
  last_commit=$(git log -1 --format="%h %s" 2>/dev/null | cut -c1-60)

  echo "=== $worktree_name ==="
  echo "  Path:   $worktree"
  echo "  Branch: $branch"
  echo "  Status: $status_str"
  echo "  Last:   $last_commit"
  echo ""
done

# Return to original directory
cd "$REPO_ROOT"
