---
name: submit-pr
description: Commit, push, raise PR. Trigger whenever the user mentions or implies that they want to raise a PR.
---

# Submit PR Workflow

Run the full commit-push-PR-review cycle.

## Steps

1. **Lint**: Run linting on changed files. Fix any issues.
2. **Test**: Search for and run any tests in the repo. If any test fails, fix the issue before proceeding. Do not commit with failing tests.
3. **Commit**: Stage changed files (specific files, not `git add -A`). Write a concise commit message using `$ARGUMENTS` if provided, otherwise infer from the diff.
4. **Push**: `git push -u origin <branch>`.
5. **Create PR**: Use `gh pr create --base development` with a summary body. If a PR already exists for this branch, skip creation.
6. **Done**: Report the PR URL.

## Important
- Never force-push or amend commits.
- Always lint before committing.
