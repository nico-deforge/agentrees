#!/bin/bash
# launch.sh
# Opens each agent worktree in a new terminal tab and optionally runs claude
#
# Usage: ./launch.sh <project> [--no-claude] [--terminal=ghostty|iterm|terminal]
# Example: ./launch.sh api
# Example: ./launch.sh api --no-claude
# Example: ./launch.sh api --terminal=iterm

set -e

DEV_DIR="${AGENTREES_DEV_DIR:-}"
LAUNCH_CLAUDE=true
TERMINAL="ghostty"

PROJECT=""

# Parse arguments
for arg in "$@"; do
  case $arg in
    --no-claude)
      LAUNCH_CLAUDE=false
      ;;
    --terminal=*)
      TERMINAL="${arg#*=}"
      ;;
    -*)
      # Unknown option
      ;;
    *)
      if [ -z "$PROJECT" ]; then
        PROJECT="$arg"
      fi
      ;;
  esac
done

if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project> [--no-claude] [--terminal=ghostty|iterm|terminal]"
  echo ""
  echo "Examples:"
  echo "  $0 api                    # Launch Ghostty tabs with Claude"
  echo "  $0 api --no-claude        # Launch tabs without starting Claude"
  echo "  $0 api --terminal=iterm   # Use iTerm instead"
  exit 1
fi

# Resolve project path
if [ -d "$PROJECT" ]; then
  REPO_ROOT=$(cd "$PROJECT" && git rev-parse --show-toplevel 2>/dev/null || echo "$PROJECT")
elif [ -n "$DEV_DIR" ] && [ -d "$DEV_DIR/$PROJECT" ]; then
  REPO_ROOT="$DEV_DIR/$PROJECT"
else
  echo "Error: Project '$PROJECT' not found"
  [ -z "$DEV_DIR" ] && echo "Hint: Set AGENTREES_DEV_DIR or provide a path"
  exit 1
fi

REPO_NAME=$(basename "$REPO_ROOT")

echo "=== Launch Claude Agents ==="
echo "Repository: $REPO_NAME"
echo "Terminal: $TERMINAL"
echo "Launch Claude: $LAUNCH_CLAUDE"
echo ""

cd "$REPO_ROOT"

# Find all agent worktrees
WORKTREES=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | grep "${REPO_NAME}-worktree-" || true)

if [ -z "$WORKTREES" ]; then
  echo "No agent worktrees found."
  echo ""
  echo "Create worktrees first with: mise run wt:setup $PROJECT"
  exit 1
fi

launch_ghostty() {
  local worktree="$1"
  local worktree_name=$(basename "$worktree")

  # Open a new tab in Ghostty (not a new window)
  open -a Ghostty "$worktree"

  if [ "$LAUNCH_CLAUDE" = true ]; then
    sleep 0.3
    osascript << EOF
tell application "System Events"
  tell process "Ghostty"
    keystroke "claude"
    keystroke return
  end tell
end tell
EOF
  fi

  echo "  Opened: $worktree_name"
}

launch_iterm() {
  local worktree="$1"
  local worktree_name=$(basename "$worktree")

  if [ "$LAUNCH_CLAUDE" = true ]; then
    osascript << EOF
tell application "iTerm"
  create window with default profile
  tell current session of current window
    write text "cd '$worktree' && claude"
  end tell
end tell
EOF
  else
    osascript << EOF
tell application "iTerm"
  create window with default profile
  tell current session of current window
    write text "cd '$worktree'"
  end tell
end tell
EOF
  fi

  echo "  Opened: $worktree_name"
}

launch_terminal() {
  local worktree="$1"
  local worktree_name=$(basename "$worktree")

  if [ "$LAUNCH_CLAUDE" = true ]; then
    osascript << EOF
tell application "Terminal"
  do script "cd '$worktree' && claude"
end tell
EOF
  else
    osascript << EOF
tell application "Terminal"
  do script "cd '$worktree'"
end tell
EOF
  fi

  echo "  Opened: $worktree_name"
}

# Launch each worktree
for worktree in $WORKTREES; do
  case $TERMINAL in
    ghostty)
      launch_ghostty "$worktree"
      ;;
    iterm)
      launch_iterm "$worktree"
      ;;
    terminal)
      launch_terminal "$worktree"
      ;;
    *)
      echo "Unknown terminal: $TERMINAL"
      echo "Supported: ghostty, iterm, terminal"
      exit 1
      ;;
  esac

  # Small delay to avoid overwhelming the terminal
  sleep 0.5
done

echo ""
echo "=== Launched ${TERMINAL} tabs for all worktrees ==="
echo ""
if [ "$LAUNCH_CLAUDE" = false ]; then
  echo "Run 'claude' in each tab to start the agents"
fi
echo "Tip: Use 'mise run wt:status $PROJECT' to check progress"
