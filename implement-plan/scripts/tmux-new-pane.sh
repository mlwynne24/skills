#!/bin/bash
# Launch a Claude Code session in a new tmux pane to implement a plan.
# Template variables (substituted by the skill):
#   {{WORK_DIR}}  - directory to run in (worktree or project dir)
#   {{PROMPT}}    - the Claude Code prompt

WORK_DIR="{{WORK_DIR}}"
PROMPT="{{PROMPT}}"

tmux split-window -h -c "$WORK_DIR"
tmux send-keys "claude '${PROMPT}'" Enter

echo "New tmux pane created. The implementation is running in the adjacent pane."
