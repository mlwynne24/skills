# Test scenarios — interview-summarisation

Three manual scenarios for v1. Automated evals are deferred to v2 (plan §9). Run each scenario end-to-end before declaring a change to the skill ready.

## Scenario 1 — Tiny project, no themes

**Setup:**
- 2 transcript files in `INPUTS_DIR` (an external folder, e.g. `~/tmp/scenario1/`): `interview_01.docx`, `interview_02.txt`
- No interview guide; user describes the grid directly: "Three questions: top concerns, current controls, suggested improvements"
- No themes
- No calibration

**Walks through:** Phase 0 (create new) → Phase 1 (discovery) → Phase 2 (bootstrap) → Phase 3 (schema/prompt from description, no guide) → skip Phase 4 → Phase 5 (run) → skip Phase 6.

**Expected output:** the xlsx at `CONFIG.output_path` (set during scaffold; not necessarily under the repo) with row 1 brand banner, row 2 humanised column headers (`Filename`, 3 question pairs), 2 data rows. No theme merge cells. Active sheet named `Interviews`.

**What to verify:**
- Both transcripts processed
- `confidence` column shows percentages with red→green color scale
- xlsx opens cleanly in Excel (no warnings about repaired content)
- `~/.frontier/projects.json` contains the new project under `interview-summarisation` key

## Scenario 2 — Themed project, .docx interview guide, 3 transcripts

**Setup:**
- Interview guide in `.docx` covering ~8 questions across 3 themes (e.g. "Risk landscape", "Customer journey", "Tooling")
- 3 transcripts: mixed `.docx`, `.pdf`, `.vtt`
- User opts into themes, opts into LLM-extracted metadata (interviewee name + role + date)
- Skip calibration

**Walks through:** Phase 0 → 1 → 2 → 3 (guide-driven schema proposal, table iteration — try 1–2 critique cycles before approving) → skip Phase 4 → Phase 5 → skip Phase 6.

**Expected output:**
- Row 1: brand banner spans A1+B1, then merged theme cells from C1 onwards (one merge per theme)
- Row 2: humanised headers — `Filename`, metadata cols, then question/confidence pairs grouped by theme
- 3 data rows with metadata populated (extracted from transcripts) and themed answers

**What to verify:**
- Theme merge cells align correctly with their question groups
- `.vtt` timestamps don't pollute answers (the model ignores them as expected)
- Append flow works: drop one extra file into `INPUTS_DIR` and re-run; confirm it appends a 4th row without re-processing the original 3

## Scenario 3 — Calibration loop with one bad-then-good iteration

**Setup:**
- Themed project (any small one — can re-use Scenario 2's setup)
- User opts INTO calibration
- User picks transcript 1 as the calibration file
- User provides ideal output as markdown lines

**Walks through:** Phases 0–3 → Phase 4 with at least 2 iterations:
1. First iteration: model output drifts from ideal (e.g. too verbose). User says "more concise, one sentence per answer max."
2. Skill edits `prompt.py`, second iteration runs, model output closer to ideal. User accepts.

→ Phase 5 → skip Phase 6.

**What to verify:**
- `calibration/prompt_history.md` exists with both prompt versions and timestamps
- `calibration/expected_example.md` records the chosen file + ideal output
- Schema is unchanged (calibration only edits `prompt.py`)
- Soft-cap warning does NOT fire (only 2 iterations; cap is at 5)
- Re-running Phase 5 uses the calibrated prompt

## Cross-cutting checks (run on any scenario)

- **Failure handling:** drop a deliberately-corrupt `.docx` into `INPUTS_DIR` mid-run. Confirm: error row shows `[error]` cells with light-red fill; `Errors` sheet has filename + error_code + request_id; end-of-run summary lists the failure; subsequent successful retry overwrites the `[error]` row.
- **Schema drift:** edit the xlsx directly to rename one column. Re-run. Confirm the skill enters the migration loop, asks which name to keep, and updates both files coherently.
- **Stale registry path:** delete the scaffold directory but leave the entry in `projects.json`. Run skill again — confirm Phase 0 detects the missing path and offers to remove from registry / fetch from GitHub.

## What's NOT in scope for v1 testing

- Concurrency / load (don't push past 20 transcripts in v1 testing — that's v2 territory)
- Long transcripts that overflow context (out of scope; the skill fails clearly with "split manually")
- OCR for image-only PDFs
- Multilingual transcripts (English only for v1)
