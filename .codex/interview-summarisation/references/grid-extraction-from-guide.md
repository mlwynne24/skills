# Grid extraction from interview guide

The flow that turns an interview guide (any format) into a candidate `InterviewGrid` Pydantic schema. Used by Phase 3 of the skill workflow.

## Inputs

The user has pointed you at one of:

- An interview guide file (`.docx`, `.pdf`, `.md`, `.txt`)
- A free-text description of the grid structure pasted into chat
- An existing `.xlsx` grid

If the user has provided an existing grid, present the existing grid to the user following the presentation guidance below and ask the user if they want your help iterating on the grid or if they want to proceed with the existing grid. If they want help iterating, enter the iteration loop outlined below, following all steps. If they want to proceed with the existing grid, skip to writing `schema.py`.

In all cases you produce the same artifact: a candidate `GridProposal` for the user to critique.

## Sample-and-confirm metadata

Before extracting questions, decide how metadata fields (interviewee name, role, date, etc.) will be populated. Peek at 2–3 transcript files in the user's `INPUTS_DIR`. Look for:

- Metadata in the **filename** (e.g. `2026-04-12_jane-doe_cfo.docx`)
- Metadata in a **transcript header** (e.g. "Date: ...", "Interviewer: ...")
- Speaker labels that imply names

Then ask the user (one question at a time):

> "I see metadata patterns like `<observed pattern>` in the transcript filenames. How would you like metadata populated?"
>
> 1. Don't include metadata fields in the grid (consultants fill in manually post-run)
> 2. Include them in the schema for the model to extract from transcript headers (Recommended)
> 3. Include them but I'll provide them per-interview manually

If (2), generate metadata fields as flat `str | None` with `Field(description="...")` that hints at where to look (e.g. `description="The interviewee's full name. Look in the filename or transcript header."`).

## Generating the proposal

Read the guide directly via the Read tool and produce the initial grid proposal. Hold the proposal in conversation state as a conceptual `GridProposal` with:

- `metadata_columns` — each: `name` (snake_case), `pydantic_type` (`str | None`), `description`, `theme = None`
- `question_columns` — each: `name` (snake_case), `pydantic_type` (`Answer`), `description`, `theme` (or `None` if no themes)
- `themes` — list of theme names (empty if user opted out)

Don't write `GridProposal` / `ColumnSpec` Pydantic classes anywhere. They're a thinking aid, not committed code. The committed artefact is `schema.py`, written once the user approves.

## Presenting the proposal

Render the proposal as a **markdown table** in chat. Hide the `Answer` wrapper — the user sees flat columns:

```
| Column | Type | Description | Theme |
|---|---|---|---|
| Interviewee Name | text | The interviewee's full name | (metadata) |
| Top Concerns | answer | What does the interviewee see as the biggest risk? | Risk landscape |
| ...
```

Don't show the user `Answer { value, confidence }` — they don't need to know about the wrapper. Just say "answer" type and explain confidence comes through automatically. Do not use snake case for presenting the proposal. Everything should be human-readable prose.

## Iteration loop

After showing the table, ask the user (free-form):

> "Anything you want to change? Reword, add, remove, regroup themes — just let me know."

Loop:

1. User responds in natural language
2. You edit the proposal in-place (it lives in conversation state, not a file)
3. Re-render the markdown table
4. Repeat until the user explicitly approves

When the user approves, write the actual `schema.py` (now with `Answer` wrappers around question fields, flat `str | None` for metadata, `Field(description=...)` from the proposal).

## Theme metadata

If the user opted into themes, store the `field_name → theme_name` mapping as a module-level dict in `schema.py`:

```python
THEMES: dict[str, str] = {
    "top_concerns": "Risk landscape",
    "current_controls": "Risk landscape",
    "onboarding_experience": "Customer journey",
    ...
}
```

`excel_writer.py` reads `THEMES` to build the merged theme header cells in row 1. Metadata fields are not in `THEMES` (they sit between filename and the first themed question group).
