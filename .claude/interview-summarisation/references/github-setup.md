# GitHub setup — interview-summarisation projects

Phase 6 of the workflow. Walk a first-time user through creating a GitHub repo for the scaffolded project and pushing the initial commit. Skip for users who manage their own remotes — ask first.

## Prerequisites

- `gh` CLI installed
- `gh auth login` already run (the user did this for the foundry-client doc fetch in Phase 2; if they skipped that, prompt them now)

## Walkthrough

### Step 1 — Confirm

Ask the user (one question):

> "Push this project to GitHub? I'll create a private repo under `Frontier-Economics` and push the current branch. Skip if you'd rather wire it up manually."

Options: yes / no / skip but tell me the commands. If "skip but tell me", print the commands below as a block and end Phase 6.

### Step 2 — Repo name

Default to the scaffold directory name (e.g. `barclays-interview-summarisation`). Ask:

> "Repo name? Default: `<scaffold-dirname>`. Press enter to accept."

### Step 3 — Visibility

Default **private**. Ask only if the user has indicated otherwise during the conversation; this skill assumes private-by-default for consulting work.

### Step 4 — Run

```bash
gh repo create Frontier-Economics/<repo-name> --private --source=. --remote=origin --push
```

This single command creates the repo, sets `origin`, and pushes the current branch. Run it from inside the scaffold directory.

If `gh repo create` fails with `repository already exists`, ask the user:

> "A repo at `Frontier-Economics/<repo-name>` already exists. Push to it as a fresh history (force, dangerous if it has commits) or pick a different name?"

Default to "different name" — never force-push to a pre-existing repo without explicit confirmation.

### Step 5 — Register

Update `~/.frontier/projects.json` for this project, setting `github_remote` to the SSH URL (`git@github.com:Frontier-Economics/<repo-name>.git`). The next time the user runs the skill and picks this project, the GitHub menu option will show "synced" rather than "not pushed".

### Step 6 — Confirm

Print the repo URL (`https://github.com/Frontier-Economics/<repo-name>`) so the user can click through.

## What gets pushed

The scaffold has a `.gitignore` that excludes:

- `.env` (secrets — never push)
- `.venv/` (uv-managed virtualenv)
- `.foundry-usage-guide.md` (transient, fetched per-clone)
- `logs/`
- `outputs/` (safety net for users who point `output_path` inside the scaffold; default is outside the repo entirely)

The initial push includes: source files, `pyproject.toml`, `uv.lock`, `_template_grid.xlsx` (the brand seed), `project_context.md`, `calibration/` if present.

**Transcripts and the output grid are NOT in the repo** — both live at the paths stored in `config.py` (`inputs_dir`, `output_path`), outside the scaffold. So nothing sensitive ships with the push by default. The two paths themselves *are* committed (Python defaults), so they leak one machine's filesystem layout — flag this to the user if that matters; otherwise a consultant cloning this repo on another machine will edit the `inputs_dir` and `output_path` defaults (or set the matching env vars) to point at their local copies.

## Subsequent pushes

The skill also handles ongoing sync. From the existing-project sub-menu (Phase 0 sub-menu option 4), running "Push to / sync with GitHub" should:

1. `git status` — show what's pending
2. `git add .`
3. `git commit -m "<concise message based on changes>"`
4. `git push`

Ask the user before committing if the changes look unusual (large diffs, unfamiliar files).

## What if they don't have `gh`?

Print the manual commands and stop:

```bash
# Create the repo on GitHub manually first, then:
git remote add origin git@github.com:Frontier-Economics/<repo-name>.git
git branch -M main
git push -u origin main
```
