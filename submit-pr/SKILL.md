---
name: submit-pr
description: Commit, push, raise PR to development, then monitor and address bot review comments. Trigger whenever the user mentions or implies that they want to raise a PR.
---

# Submit PR Workflow

Run the full commit-push-PR-review cycle.

## Steps

1. **Lint**: Run `uv run ruff check` and `uv run ruff format` on changed files. Fix any issues.
2. **Test**: Search for and run any tests in the repo. If any test fails, fix the issue before proceeding. Do not commit with failing tests.
3. **Commit**: Stage changed files (specific files, not `git add -A`). Write a concise commit message using `$ARGUMENTS` if provided, otherwise infer from the diff.
4. **Push**: `git push -u origin <branch>`.
5. **Create PR**: Use `gh pr create --base development` with a summary body. If a PR already exists for this branch, skip creation.
6. **Monitor review loop**:
   a. Wait ~70s for CI and bot review to complete (`gh pr checks`, poll until done).
   b. Fetch review comments via GitHub MCP (`pull_request_read` with `get_review_comments`) and general comments (`get_comments`).
   c. If there are unresolved review comments, make a plan to address each comment and present to the user.
   d. After user approval, implement the fixes for the review comments and leave comments where necessary.
   e. When you are finished the plan, lint again, commit the fixes (with a message referencing the original commit), and push.
7. **Done**: Report the PR URL, final status, and a brief summary of the review comments addressed.

## Important
- Never force-push or amend commits.
- Always lint before committing.
- If a review comment is purely informational (no code change needed), reply acknowledging it and move on.
