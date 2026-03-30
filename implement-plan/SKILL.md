---
name: implement-plan
description: Implement a saved plan on a new worktree and raise a PR. Trigger when the user wants to execute/implement a plan, or says "/implement-plan".
argument-hint: <plan-path> [branch-name] [--worktree] [--pane | --window] [--submit-pr]
---

# Implement Plan

Execute a saved plan, optionally on a new git worktree, in a new tmux pane/window, and submit a PR when done.

## Usage

```
/implement-plan docs/plans/20260324/user-login-flow.md feature/user-login --worktree --window --submit-pr
```

## Argument Parsing

Parse `$ARGUMENTS` into the following:

| Arg | Required | Description |
|-----|----------|-------------|
| `plan-path` | Yes | Path to the plan file (first positional arg) |
| `branch-name` | No | Git branch name (second positional arg). Defaults to current branch. |
| `--worktree` | No | Create a new git worktree at `../<project-dirname>-trees/<branch-name>` |
| `--pane` | No | Run implementation in a new tmux pane. Mutually exclusive with `--window`. |
| `--window` | No | Run implementation in a new tmux window. Mutually exclusive with `--pane`. |
| `--submit-pr` | No | Run the `/submit-pr` skill after implementation is complete. |

## Validation

Before doing anything, validate:

1. `plan-path` is provided and the file exists. If not, stop and tell the user.
2. `--pane` and `--window` are NOT both set. If they are, stop and tell the user: "Only one of `--pane` or `--window` can be set."
3. If `--worktree` is set, `branch-name` must also be provided. If not, stop and tell the user.
4. If `--pane` or `--window` is set, confirm we are inside a tmux session (`$TMUX` is set). If not, warn the user and fall back to current session.

## Execution

### Step 1: Determine execution environment

- If **neither** `--pane` nor `--window` is set → execute steps 2-7 directly in the current session.
- If `--pane` or `--window` is set → set up the worktree first (step 2), then generate and execute the appropriate tmux script to spawn a new Claude Code session. **Then stop** — the spawned session handles steps 3-7.

### Step 2: Set up branch and worktree

- If `branch-name` is provided and `--worktree` is set:
  - Determine worktree path: `../<project-dirname>-trees/<branch-name>`
  - Create dir: `mkdir -p ../<project-dirname>-trees`
  - If worktree already exists at that path, remove it: `git worktree remove --force <path>`
  - Add worktree: `git worktree add -b <branch-name> <path>` (fall back to `git worktree add <path> <branch-name>` if branch exists)
  - Set working directory to the worktree path
- If `branch-name` is provided but `--worktree` is NOT set:
  - `git checkout -b <branch-name>` (or `git checkout <branch-name>` if it exists)
- If no `branch-name` → stay on current branch in current directory.

### Step 3: Read the plan

Read the plan file at `plan-path`. Understand the full scope before touching any code.

### Step 4: Explore relevant files

Thoroughly explore all files referenced in or relevant to the plan. Build a complete mental model of the codebase areas you will modify.

### Step 5: Clarify with the user

Use the AskUserQuestion tool to ask the user any questions needed to resolve ambiguities. Always provide your recommendation alongside each question. Skip this step if the plan is unambiguous.

### Step 6: Implement

Implement the plan. Make regular commits as you go (per user's coding guidelines). Keep scripts under 200 lines where possible.

### Step 7: Submit PR (conditional)

If `--submit-pr` is set, run the `/submit-pr` skill to lint, test, commit, push, and create a PR.

## Spawning a tmux session

When `--pane` or `--window` is set, use the template scripts in `scripts/` to spawn a new Claude Code session. The approach:

1. **Read** the appropriate template (`scripts/tmux-new-pane.sh` or `scripts/tmux-new-window.sh`).
2. **Substitute** the template variables (see below).
3. **Write** the rendered script to a temp file (e.g. `/tmp/implement-plan-<branch>.sh`).
4. **Run** `chmod +x <script> && bash <script>`.
5. **Report** to the user where the session is running, then stop.

### Template variables

| Variable | Value |
|----------|-------|
| `{{SESSION}}` | Current tmux session name (from `tmux display-message -p '#S'`) |
| `{{WINDOW_NAME}}` | `implement-<branch-name>` (or `implement-plan` if no branch) |
| `{{WORK_DIR}}` | Absolute path to working directory (worktree path or project dir) |
| `{{PROMPT}}` | The Claude Code prompt (see below) |

### Constructing the prompt

Build a prompt string for the spawned Claude Code session. It must instruct the new session to carry out steps 3-7 autonomously. Example:

```
Implement the plan at <absolute-plan-path>. Read the plan, explore all relevant files, then implement it fully. Make regular commits as you go. <if --submit-pr> When done, run /submit-pr to lint, test, commit, push, and create a PR.</if>
```

Use single quotes around the prompt when passing to `tmux send-keys` (matching the proven pattern: `tmux send-keys "claude '${PROMPT}'" Enter`). Escape any single quotes within the prompt.
