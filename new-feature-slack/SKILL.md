---
name: new-feature-slack
description: Generate a Slack-ready feature announcement from recent git commits. Use when the user wants to craft a Slack post about a new feature.
---

# New Feature Slack Announcement

Generate a formatted Slack message announcing a new feature based on selected commits.

## Audience

The Slack message targets **non-technical users** (stakeholders, product managers, end-users). All titles and descriptions must focus on user-facing impact — what the user can now do, what got better, what problem is solved. Avoid mentioning code, commits, PRs, technical implementation details, library names, or internal architecture.

## Steps

1. **Fetch commits**: Run `git log --oneline -20` (or more if needed) to get recent commits.
2. **Ask which commits**: Use `AskUserQuestion` with `multiSelect: true`, listing each commit as an option ordered most-recent-first. Each option label should be the short hash + message, description can be empty.
3. **Ask verbosity**: Use `AskUserQuestion` with two options:
   - **Short** — 1-2 sentence summary
   - **Long** — detailed paragraph covering what changed and why it matters
4. **Analyse diffs**: For each selected commit, run `git show --stat <sha>` and read the diffs to understand what actually changed. Use this to inform an accurate, user-focused title and description.
5. **Generate the message**: Use the `_template.md` file as a template. Based on the selected commits and verbosity preference, write a Slack announcement in this exact format:

```
<suitable_emoji> Feature: **<Feature title>**

<suitable_emoji> Description: **<Feature description based on verbosity choice>**
```

   - Pick a single emoji that fits the feature theme for each line (e.g. rocket for launch, magnifying glass for search, etc.)
   - The feature title should be a concise, non-technical name describing the user benefit
   - The description must be written for non-technical readers: focus on what users can now do, what improved, or what problem is solved. Never mention code changes, technical implementation, library names, or internal architecture.

6. **Output**: Write the final message to `.ignore/feature-messages/<YYYY-MM-DD>-<slugified-title>.md` (create the directory if needed). Also print the message to the terminal.
