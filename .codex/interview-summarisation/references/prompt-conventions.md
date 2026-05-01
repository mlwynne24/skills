# Prompt conventions — interview-summarisation

Conventions for the system/user split, value/confidence semantics, and project-context placement used by the scaffolded `prompt.py`.#

## System vs user split

- **System prompt:** role, project context, schema-shape rules, confidence semantics. Fixed across all transcripts in a project.
- **User prompt:** the transcript text only, lightly framed (`"Below is the interview transcript:\n\n{transcript}"`).

Don't put per-transcript content in the system prompt. Don't put project-wide rules in the user prompt.

## Project context

Project context lives in `project_context.md` at the scaffold root, hand-edited by the consultant. `run.py` reads it and `prompt.py:build_messages()` substitutes it into the system prompt at the `${PROJECT_CONTEXT}` placeholder.

This is the file you point users at when they say "the model doesn't know enough about our engagement". Iterating on it is faster than re-running calibration.

## No JSON schema in messages, no few-shot

- The schema is sent via `response_format`, generated from `response_model.model_json_schema()`. **Don't paste a JSON schema into the system prompt** — it duplicates information and confuses the model.
- **No few-shot examples in v1.** `Field(description=...)` plus the value/confidence rules below carry the load. Few-shot is deferred to v2.

## Value / confidence semantics

Each question field is wrapped in `Answer { value: str | None, confidence: float | None }`. The system prompt teaches three states explicitly:

| State | `value` | `confidence` | When |
|---|---|---|---|
| Stated | non-null answer | high (≥0.8) | The interviewee said it directly |
| Inferred | non-null answer | mid (0.3–0.7) | The transcript supports the answer indirectly |
| Not in transcript | `null` | `null` | Question never came up |

**Critical:** `null` value means "not addressed at all", **not** "addressed but I'm uncertain". Low confidence is what expresses uncertainty when an answer exists. Drill this distinction into the system prompt — it's the one thing reviewers consistently get wrong.

The `confidence` field is `float | None` with `ge=0`, `le=1`. Tell the model to use the full granularity of `[0, 1]` and not anchor on round numbers.

## Metadata fields

Metadata fields (`interviewee_name`, `role`, `date_of_interview`, etc.) are flat `str | None` — no `Answer` wrapper, no confidence. If a metadata field can't be extracted from the transcript, leave it `null` and the consultant fills it in manually in the xlsx.

`date_of_interview` is `str | None` (ISO `YYYY-MM-DD` if available). v1 doesn't enforce date typing — see plan §9 (deferred to v2). Stricter typing burns validation retries when the model produces near-but-not-ISO strings.

## What changes during calibration

During the calibration loop (`calibration-loop.md`), only `prompt.py` is edited — never `schema.py`. If the schema needs to change, exit calibration and return to Phase 3.6 of the workflow.

## Anti-patterns to avoid

- Telling the model "be a domain expert in X" as flowery preamble — it doesn't help. Project context covers this.
- Listing the field names in the prompt body — they're already in the schema.
- Pasting the interview guide into the system prompt — too long, and the model already sees the schema. The guide is for **you** (the skill) when proposing the schema, not for the model at runtime.
