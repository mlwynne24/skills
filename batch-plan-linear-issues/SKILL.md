---
name: batch-plan-linear-issues
description: Generates and runs a bash script that creates a tmux session with one window per Linear issue, each in its own git worktree with an interactive Claude Code session in plan mode. Use when the user wants to plan/implement multiple Linear issues in parallel.
---

# Batch Plan Linear Issues

Creates a tmux session where each window is an isolated Claude Code session planning a single Linear issue.

## What it does

1. Takes a list of Linear issue IDs (e.g. `AIFWU-109 AIFWU-108 AIFWU-95`)
2. Generates `scripts/plan-issues.sh` which:
   - Creates a git worktree per issue (branching from `development`)
   - Opens a tmux session with one named window per issue
   - Starts an interactive `claude` session in each, pre-prompted to fetch the issue from Linear, explore the codebase, and enter into a `grill-me` session (see skill) with the user to plan the implementation.
3. Runs the script and tells the user how to attach

## Usage

User provides issue IDs either as arguments or in their message. Generate the script with the correct issue IDs and titles (fetch from Linear if needed), then run it. Prompt the user that they need to be in Bash (not tmux already) to run it.

### Script template

Reference implementation: `./plan-issues.sh`

Key structure:
- `SESSION="kh-plans"` (or user-specified)
- Worktrees created at `../knowledge-hub-trees/<suitable-issue-slug>`
- Branches named `plan/<suitable-issue-slug>`
- Each Claude session is prompted to: fetch issue details via Linear MCP, explore relevant code, enter into a `grill-me` session (see skill) with the user to plan the implementation, and wait for user approval before implementing

### Gotchas

- Do NOT use `claude -p` or `claude --print` — that runs non-interactive print mode and exits. We need interactive sessions the user can attach to and converse with.
- Do NOT use `--resume no` with `-p` — it errors.
- Do NOT use `--prompt` — it is not a valid flag.
- Pass the initial prompt as a **positional argument**: `claude "prompt text"`. This starts an interactive session with the prompt pre-filled.

### After running

Tell the user:
```
tmux attach -t kh-plans
```
Use `Ctrl-b n` / `Ctrl-b p` to switch between issue windows.
