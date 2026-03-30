#!/bin/bash
# Launch a Claude Code session in a new tmux window to implement a plan.
# Template variables (substituted by the skill):
#   {{SESSION}}      - current tmux session name
#   {{WINDOW_NAME}}  - name for the new window
#   {{WORK_DIR}}     - directory to run in (worktree or project dir)
#   {{PROMPT}}       - the Claude Code prompt

SESSION="{{SESSION}}"
WINDOW_NAME="{{WINDOW_NAME}}"
WORK_DIR="{{WORK_DIR}}"
PROMPT="{{PROMPT}}"

tmux new-window -t "$SESSION" -n "$WINDOW_NAME" -c "$WORK_DIR"
tmux send-keys -t "$SESSION:$WINDOW_NAME" "claude '${PROMPT}'" Enter

echo "New tmux window '$WINDOW_NAME' created in session '$SESSION'."
echo "Switch to it with: tmux select-window -t $SESSION:$WINDOW_NAME"
