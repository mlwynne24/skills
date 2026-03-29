#!/bin/bash
# Spawns a tmux session with one window per issue, each running an interactive
# Claude Code session in plan mode within its own git worktree.

SESSION="kh-plans"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKTREE_DIR="$(dirname "$REPO_ROOT")/knowledge-hub-trees"

# Issue ID -> slug (for worktree dir and branch name)
declare -A SLUGS=(
  ["<issue-id>"]="<issue-slug>"
)

declare -A TITLES=(
  ["<issue-id>"]="<issue-title>"
)

ORDERED_KEYS=(
  "<issue-id-1>" "<issue-id-2>" "<issue-id-3>" "<issue-id-4>" "<issue-id-5>"
)

mkdir -p "$WORKTREE_DIR"

# Kill existing session if present
tmux kill-session -t "$SESSION" 2>/dev/null

FIRST=true
for ISSUE in "${ORDERED_KEYS[@]}"; do
  SLUG="${SLUGS[$ISSUE]}"
  TITLE="${TITLES[$ISSUE]}"
  BRANCH="plan/${SLUG}"
  WT_PATH="$WORKTREE_DIR/${SLUG}"

  # Create worktree (clean up stale ones first)
  if [ -d "$WT_PATH" ]; then
    git -C "$REPO_ROOT" worktree remove --force "$WT_PATH" 2>/dev/null
  fi
  git -C "$REPO_ROOT" worktree add -b "$BRANCH" "$WT_PATH" development 2>/dev/null || \
  git -C "$REPO_ROOT" worktree add "$WT_PATH" "$BRANCH" 2>/dev/null

  if [ "$FIRST" = true ]; then
    tmux new-session -d -s "$SESSION" -n "$ISSUE" -c "$WT_PATH"
    FIRST=false
  else
    tmux new-window -t "$SESSION" -n "$ISSUE" -c "$WT_PATH"
  fi

  # Pass prompt as positional arg for interactive session.
  # Do NOT use -p/--print (non-interactive), --prompt (invalid flag), or --resume no.
  PROMPT="You are working on Linear issue ${ISSUE}: ${TITLE}. First, fetch the full issue details using the Linear MCP tool (mcp__linear-server__get_issue) with id ${ISSUE}. Then explore the relevant codebase files and create a plan to implement this. Enter into a /grill-me session (see skill) with the user to plan the implementation, and wait for user approval before implementing."
  tmux send-keys -t "$SESSION:$ISSUE" "claude '${PROMPT}'" Enter
done

echo "tmux session '$SESSION' created with ${#ORDERED_KEYS[@]} windows."
echo "Attach with: tmux attach -t $SESSION"
