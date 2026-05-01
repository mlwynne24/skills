---
name: interview-summarisation
description: Walk a Frontier consultant through end-to-end interview-grid extraction — pick or create a project, scaffold a Python repo, propose a Pydantic schema from an interview guide, optionally calibrate the prompt, batch-process transcripts via azure-foundry-client, and write a Frontier-branded xlsx grid.
disable-model-invocation: true
---

# Interview summarisation

This skill encodes the interview summarisation workflow at Frontier. It uses Azure AI Foundry to extract structured information from interview transcripts.

## Tone & Pacing rules (read first)

This skill's audience is consultants who may not be deeply technical. Your role is to allow the consultant to focus on the decisions, while you execute the technical tasks behind the scenes. Rules:

- **Ask discovery and confirmation questions ONE AT A TIME.** Users need space to think between decisions. Do not batch multiple questions into one turn — each question is its own back-and-forth.
- Do not include technical details about your process in messages to the user.
- Be bright & helpful in your interactions with the user.

## Reference docs (load when relevant)

Read these only when you reach the relevant phase — don't pre-load all of them straight away:

- `references/grid-extraction-from-guide.md` — Phase 3
- `references/prompt-conventions.md` — Phase 3
- `references/calibration-loop.md` — Phase 5
- `references/excel-conventions.md` — Phase 6
- `references/github-setup.md` — Phase 7
- `references/test-scenarios.md` — only for skill QA

## Gotchas

- **Long Foundry calls:** interview extraction calls take minutes, especially over a multi-file batch. Set a generous shell timeout when invoking `uv run run.py` (the Bash tool's default may kill long batches mid-run). The client is asynchronous; do not split a multi-file batch into one-at-a-time runs just because the first shell timeout was too low.

## Phase 0 — Project selection (always first)

Read `~/.frontier/projects.json`. If the file is missing, create it. If `interview-summarisation` key is missing, treat as empty list. If JSON is malformed, back up to `projects.json.bak.<timestamp>` and start fresh.

Render menu:

```
Select interview-summarisation project:
  1. <slug>  (last touched <relative time>, model=<model>)
  ...
  N. [Create new project]
  N+1. [Fetch existing project from GitHub]
```

Empty registry → only show the last two options.

If user picks an **existing** project: stat the directory. If it doesn't exist, offer to remove the registry entry or fetch from GitHub. Otherwise scan for hints (new files in the registry's `inputs_dir` not yet in the output xlsx, drift between xlsx and `schema.py`) and show a sub-menu:

```
What do you want to do for <slug>?
  1. Add new interviews to the grid                     [N new files detected]
  2. Migrate schema (xlsx columns differ from schema.py)  [drift detected]
  3. Recalibrate the prompt
  4. Push to / sync with GitHub
```

Hide options without applicable hints. Each option jumps to the appropriate phase below.

If user picks **fetch from GitHub**: ask for the repo URL or `<org>/<repo>` short form (default org `Frontier-Economics`); `git clone` to `~/repos/`; `uv sync`; ask the user for the inputs and output paths on this machine and update `config.py`'s `inputs_dir` and `output_path` defaults accordingly; copy `.env.example` → `.env`; register in `projects.json` (with the supplied `inputs_dir` and `output_path`); jump to the existing-project sub-menu.

If user picks **create new**: continue to Phase 1.

## Phase 1 — Discovery (one question at a time)

Ask each question in its own turn:

1. Project name (used for slug + repo dir).
2. Parent directory — explain to the user that this is where the necessary artifacts for completing the task will be created (default `~/repos/`).
3. Inputs location — **absolute path to the folder where transcripts live**. The skill reads from this folder directly on each run; files are NOT copied into the repo. If the user gives a single file, ask for the parent directory instead.
4. Output xlsx path — **absolute path** to where the output grid should be written. Default suggestion: `<inputs_dir.parent>/<slug>.xlsx`. The output xlsx is the consultant-annotated source of truth and is **not** committed to git, so place it wherever the consultant wants (typically the engagement folder, near the transcripts).
5. Project context — free prose, folder directory with project information, uploaded proposal file, etc. (Tell them this becomes part of the system prompt; rich context = better extraction.)
6. Grid structure source: (a) interview guide file, (b) describe directly in chat, (c) existing grid.
7. Themes? (a) extract from the guide, (b) list them now, (c) no themes.

## Phase 2 — Bootstrap

1. Confirm scaffold location: `<parent_dir>/<project-slug>-interview-summarisation`. Show the user; ask before creating.
2. Copy `assets/template/*` into the new repo, substituting `{{PROJECT_NAME}}`, `{{PROJECT_SLUG}}`, `{{CREATED_AT}}`, `{{INPUTS_DIR}}` (Phase 1 step 3), and `{{OUTPUT_PATH}}` (Phase 1 step 4) placeholders.
   - Rename `*.template` files to drop the suffix.
   - Copy `assets/template/grid_template.xlsx` to the scaffold root as `_template_grid.xlsx` (used by `run.py` to seed the output xlsx).
   - Copy `.env.example` → `.env`.
   - Make empty `logs/`
   - Make a starter `project_context.md` containing information from the Phase 1 step 5 prose. This will be used in the prompt to the Azure AI Foundry and will give the model context helpful for extracting appropriate information from the transcript. Therefore, this prose should not be full verbatim text. Instead, you should extract only what is useful and format it for injection to the system prompt.
   - Do **not** create `inputs/` or `outputs/` — both transcripts and the grid live outside the repo at the paths stored in `config.py`.
3. `cd` into the scaffold; run `uv sync`.
4. Fetch the cross-skill usage guide:
   ```bash
   gh api repos/Frontier-Economics/azure-foundry-client/contents/docs/llm-usage-guide.md \
     -H "Accept: application/vnd.github.raw" > .foundry-usage-guide.md
   ```
   If `gh auth login` hasn't been run, prompt the user to run it now.
5. **Read `.foundry-usage-guide.md`** before writing any code that imports `frontier_foundry`.
6. Verify the scaffold before committing:
   - Confirm `CONFIG.inputs_dir` exists and points at the transcript folder supplied in Phase 1.
   - List supported files discovered in `CONFIG.inputs_dir`; if none are found, fix `config.py` or ask the user for the correct folder.
   - Confirm `CONFIG.output_path.parent` exists (or is creatable); the directory will be auto-created on first run, but flag now if the path is obviously wrong (e.g. typo'd drive letter).
7. `git init` + initial commit `"scaffold"`.
8. Append a record to `~/.frontier/projects.json` under the `interview-summarisation` key:
   `{slug, path, inputs_dir, output_path, model, created_at, github_remote: null}`. Initialise `model` to `"gpt-5-mini"` (the scaffolded default); Phase 4 may overwrite it. The `inputs_dir` and `output_path` fields let Phase 0 detect new transcripts and read the grid without parsing `config.py`.

## Phase 3 — Generate project-specific code

Open `references/grid-extraction-from-guide.md` and `references/prompt-conventions.md` and follow them.

Outline:

1. Read the interview guide via the harness Read tool (any format).
2. Sample-and-confirm metadata: peek at 2–3 input files, present the user with the three metadata options.
3. If the user does not have an existing grid, propose a `GridProposal` directly from your reading of the guide.
4. Render the proposal as a markdown table (hide the `Answer` wrapper).
5. Iterate free-form until the user approves.
6. Write `schema.py` (with `Answer` wrappers around question fields, `str | None` metadata, rich `Field(description=...)`, plus module-level `METADATA_COLUMNS`, `QUESTION_COLUMNS: list[tuple[name, theme | None]]`, and `INTERVIEW_GRID_TITLE`).
7. Write `prompt.py` (system + user split per `prompt-conventions.md`; `${PROJECT_CONTEXT}` placeholder).
8. Run `uv run python -m compileall schema.py prompt.py run.py` to catch syntax errors in the generated code, then show the user the rendered system prompt; iterate free-form until they approve.
9. `git commit -m "schema and prompt"`.

## Phase 4 — Model selection

This is the **first live foundry call** in the workflow — use it to confirm wiring (auth, base URL, project_id) is correct before calibration or batch.

1. Inline-call `client.available_models()` to fetch the deployments the server exposes for this project. Use a one-shot `uv run python -c "..."` from the scaffold dir; do **not** create a committed helper script. Example:

   ```bash
   uv run python -c "
   import asyncio
   from frontier_foundry import FoundryClient
   from config import CONFIG

   async def main():
       async with FoundryClient(project_id=CONFIG.project_id, config=CONFIG.foundry_client) as client:
           models = await client.available_models()
       for d in models.deployments:
           print(d.name)

   asyncio.run(main())
   "
   ```

2. If the call fails, this is where you debug auth / `gh auth login` / base URL — don't proceed until it succeeds.
3. Render the deployment names as a numbered list and ask the user (one question, per the pacing rule) which to use. Default to `gpt-5-mini` if it's in the list. Mention §4 of `.foundry-usage-guide.md`: reasoning-class models (incl. `gpt-5-mini`) reject `temperature` — the scaffold deliberately omits it. If the user picks a non-reasoning model and the user indicates that they want temperature/top_p control, that's a follow-up config edit, not part of this step.
4. Edit `config.py` — set `model: str = "<chosen>"`.
5. Update the project's record in `~/.frontier/projects.json`: set `model` to the chosen value.
6. `git commit config.py -m "select model"` (only if the model changed from the scaffolded default).

## Phase 5 — Optional calibration

Ask the user (one question): want to calibrate the prompt against one transcript first? Recommended on first use.

If yes, follow `references/calibration-loop.md` end to end. Calibration uses `CONFIG.model` (set in Phase 4). If schema needs to change mid-calibration, exit and return to Phase 3.6.

## Phase 6 — Run

Follow `references/excel-conventions.md` for output rendering rules.

1. If multiple inputs, offer a single-file dry run first (the user can decline).
2. From the scaffold dir, run `uv run run.py` (NOT `uv run python run.py`). Use a generous shell timeout: at least 5 minutes for a single-file dry run, and at least 15 minutes or roughly 5 minutes per transcript for multi-file batches, whichever is larger.
3. tqdm progress is shown by `client.batch(progress=True)`.
4. `run.py` prints an end-of-run summary; read it.
5. **Reruns auto-resume.** `run.py` reads the existing xlsx and skips any filename whose row is already populated. By default `--retry-errors` is on, so `[error]` rows are reprocessed and overwritten in place. If a shell timeout occurs, you can simply rerun `uv run run.py` — clean rows are skipped, only new files and prior errors are sent back to Foundry. To force a full re-extract, delete the xlsx (or specific rows) before rerunning.
6. If the run exited with code 2, drift was detected — enter the schema-vs-xlsx migration loop (see `excel-conventions.md` §"Drift handling").
7. If failures are present, offer: (a) retry only those (just rerun `uv run run.py` — defaults handle it), (b) debug one (rerun with `--files <name>`), (c) accept partial output (rerun with `--no-retry-errors`).
8. **Open the xlsx for the user.** Use `CONFIG.output_path` — the file may live anywhere on disk, not necessarily inside the scaffold. On Windows: `start "<output_path>"`. On macOS: `open "<output_path>"`. On Linux: `xdg-open "<output_path>"`. The skill does this — `run.py` does not.

## Phase 7 — Optional GitHub push

Ask the user (one question) if they want to push. If yes, follow `references/github-setup.md`. Update `github_remote` in `projects.json` on success.

## Behavioral conventions (durable)

- **Never abort the batch** on per-item failure. Failures land as `BatchItem.error`; the xlsx renders `[error]` rows; full diagnostics in the `Errors` sidecar sheet + `logs/`.
- **The xlsx is the source of truth** when it disagrees with `schema.py`. Migrate `schema.py` to the xlsx, never the reverse.
- **`uv` only** — `uv run`, `uv add`, `uv sync`. Never `uv run python ...` or `uv pip ...`.
- **No `temperature` for `gpt-5-mini`.** Don't set it. The `.foundry-usage-guide.md` covers why.
