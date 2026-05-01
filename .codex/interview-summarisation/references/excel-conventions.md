# Excel conventions — interview-summarisation

How `excel_writer.py` lays out the output xlsx, appends to existing files, handles schema drift, and renders errors. The xlsx is the **source of truth** — consultants annotate it manually. Treat it accordingly.

## Layout — themed

```
Row 1:  [A1+B1: brand banner "<project> — Interview Grid"]  [merged theme headers above question groups]
Row 2:  [        ] [Filename] [metadata cols...] [Q1 ans][Q1 conf] [Q2 ans][Q2 conf] ...
Row 3+: data rows
```

- Row 1: brand banner from the template (Arial 16, theme-color fill on A1+B1, narrow col A as spacer). Title in B1. From column C onwards, merged theme-header cells span the question columns belonging to each theme.
- Row 2: column header row. `Filename` in B2, metadata fields, then for each question: an answer column followed by a slim confidence column. Headers are humanised (`interviewee_name` → `Interviewee Name`); schema/data keys remain snake_case.
- Row 3+: one row per processed transcript.

## Layout — no themes

Same as above but row 1 is just the brand banner (no merged theme cells from C onwards). Row 2 is the column header row.

## Sheet name

The active sheet is named `Interviews` (set on every save, idempotent). The errors sidecar sheet is named `Errors`.

## Confidence column

- Number format: `0%` (renders `0.82` as `82%`)
- Conditional formatting: `ColorScaleRule` red → yellow → green over `0.0–1.0`
- Slim width (≈4 chars) — it's a glance column, not a read column

## Cell rendering rules

| Case | Rendering |
|---|---|
| `value=None`, `confidence=None` | Italic grey `(not in transcript)` in answer cell, blank in confidence cell |
| `value` populated, `confidence` populated | Plain text + percentage |
| Per-item batch error | `[error]` in every answer cell of that row, light-red fill; details in `Errors` sidecar sheet |

## Append flow

`run.py` calls `excel_writer.append_results(...)` which:

1. **Load existing xlsx** if `output_path` exists. If not, instantiate a fresh copy from `assets/template/grid_template.xlsx`.
2. **Reconstruct schema from header rows** — read row 1 (themes) and row 2 (column names).
3. **Compare to current `schema.py`:**
   - Identical → proceed.
   - Schema has *added* fields → auto-migrate (insert blank columns at the right position), log to stdout.
   - *Renames or removals* → exit code 2. The skill detects the non-zero exit and enters the migration loop (see `excel-conventions.md` §"Drift handling" below).
4. **Read filename column** → `processed_set` (clean rows) and `error_set` (rows containing `[error]`).
5. **Determine work:** `(new ∪ retry_errors) ∩ allowed_set`, where:
   - `new` = files in `CONFIG.inputs_dir` (the external `INPUTS_DIR`) not in `processed_set ∪ error_set`
   - `retry_errors` = `error_set` if `--retry-errors` (default true)
6. **Write rows.** A successful retry **overwrites the prior `[error]` row in place** rather than appending a duplicate.
7. **Save.** Same path. No backup file (the user has git for that).

## Drift handling

The xlsx is the source of truth because the consultant annotates it. So:

- If the xlsx has a column that `schema.py` doesn't have → migrate `schema.py` to add it (ask user for description, infer type as `str | None`).
- If `schema.py` has a column that the xlsx doesn't have → **add the column to the xlsx**, not remove it from `schema.py`. (This is the auto-migrate path above.)
- If the xlsx column name doesn't match `schema.py` (rename) → ask the user which name to keep, then update both.

Never silently drop a column from the xlsx. That destroys consultant work.

## Errors sidecar sheet

Sheet name: `Errors`. Columns: `Filename`, `Error code`, `Error message`, `Request ID`, `Timestamp`. One row per failed item. Cleared and rewritten on each run (it's a current-state view, not an audit log — full history lives in `logs/run-<ts>.log`).

## Branding constraints (do not change)

- Font: Arial throughout
- A1+B1 fill: theme color 3 (the Frontier accent)
- Col A width: ~3.7 (narrow spacer; never put data here)
- Col B: filename column from row 2 down
- Default font size: 10 in data rows, 16 in row 1 banner

These are baked into `grid_template.xlsx` and survive `load_workbook` → `save`. Don't recreate them in code; load and populate around them.
