# Calibration loop

The optional Phase 4 of the workflow. Lets the consultant tune `prompt.py` against one "ideal" output before running the full batch. Recommended for first-time use of the skill on a new project.

## When to enter

Phase 3 just finished — `schema.py` and `prompt.py` are written and committed. Ask the user (one question, single back-and-forth):

> "Want to calibrate the prompt against one transcript before processing the full batch? Recommended on first use; skip if you've already used a similar prompt."

If skip → Phase 5. If enter → continue.

## Step 1 — Pick a calibration file

Ask the user to pick **one** transcript from the configured `INPUTS_DIR`. Tell them: "Pick something representative — not the easiest, not the hardest." List the available files for them to choose from.

## Step 2 — Get the ideal output

Ask the user for the "ideal" extracted grid for that transcript. Accept four formats (one question, list the options):

1. **Markdown lines** pasted into chat: `field_name: value` per line
2. **Free-form** description in chat: "I'd expect this to say X for top concerns, Y for risks..."
3. **Pointer to an existing xlsx row** the consultant has hand-edited
4. **Run first, inspect output**: run the chosen transcript through the current prompt, show the extracted row, then ask the user whether to accept it or tune the prompt.

For options 1–3, parse whichever format comes back into the same `InterviewGrid` shape (skipping confidence — the model produces that, the human ideal is just `value`s). Show your parsed version back as a markdown table so the user can correct if you mis-parsed.

For option 4, run:

```bash
uv run run.py --files <chosen-transcript>
```

with a generous shell timeout (≥ 5 minutes). Read the generated xlsx row and show the user the extracted values in chat. Then ask:

> "Accept this prompt and move to running the batch, or tell me what to change?"

If accepted, jump to "On accept". If the user asks for a prompt change, continue into the loop below, using the user's critique as the ideal.

## Step 3 — The loop

Initialize an iteration counter. Create `calibration/` directory in the scaffold. Append every iteration to `calibration/prompt_history.md` (timestamp, full prompt body, brief change description).

Each iteration:

1. Build the messages from current `prompt.py:build_messages()` against the calibration transcript text.
2. Call `client.structured(messages, InterviewGrid, model=CONFIG.model)`.
3. Display the model output as a markdown table — same column layout as the user saw in Phase 3.
4. Compare against the ideal yourself, and produce a one-line summary like:
   > "Output matches the ideal closely on 8/10 fields; differs in tone on `top_concerns` (model is more clinical) and missing `mitigation_actions`."
5. Ask the user:

   > "What's next?"
   > 1. Accept this prompt and move to running the full batch
   > 2. Tell me what to change
   > 3. Abort calibration

6. If (2): user describes the change in natural language. You edit `prompt.py` (system prompt only — never edit the schema mid-calibration). Append the new prompt body to `calibration/prompt_history.md`. Loop back to step 1.

## Soft cap

After 5 iterations, before running iteration 6, warn:

> "We've iterated 5 times. The prompt may be over-fitting to this single transcript. Consider accepting and running the batch — the wider sample will tell you more than another tweak here."

Continue if the user wants. Don't hard-stop.

## Schema changes mid-calibration

If the user asks for something that requires changing `schema.py` (new field, removed field, type change, theme regrouping), **exit calibration**. Tell them:

> "That's a schema change, not a prompt change. Exiting calibration so we can update `schema.py` first."

Return to Phase 3.6 of the main workflow. After re-generating `schema.py`, offer to re-enter calibration from Step 1.

## On accept

- `git commit prompt.py` (and `calibration/prompt_history.md` if it exists)
- Save the calibration transcript filename to `calibration/expected_example.md` (so a future run knows which file was the ground truth). If the user chose "run first, inspect output", record that the output was accepted by inspection rather than from a pre-supplied ideal row.
- Continue to Phase 5

## What `calibration/` looks like at the end

```
calibration/
├── expected_example.md       # which file + the user's ideal output
└── prompt_history.md         # every prompt version tried, in order, with notes
```

This directory is committed alongside `prompt.py` — useful for a future consultant picking up the project to see *why* the prompt looks the way it does.
