---
name: new-feature
description: Trigger when the user asks to develop a new feature or make changes to the codebase. 
---

This skill takes the user from idea to solid plan. It covers, initial issue creation, and then `grill-me` sessions for one or more issues in a single tmux session with multiple windows using the `batch-plan-linear-issues` skill.

1. Use AskUserQuestion to get a detailed description of the feature. Explore relevant files and documentation to build a good understanding of the feature requirements.
2. When you have sufficient information, create a detailed linear issue. Assign the issue to the user (unless specified otherwise), mark as status To do, and add appropriate labels (e.g. feature request, bug, etc.). If you are unsure about any aspect of the issue, use AskUserQuestion to clarify with the user before creating the issue.
3. Once created, ask the user if they would like to start working on the issue now.
    - If they say yes:
        1. Notify them that the next flow will only get them to a solid plan: Once the agent has finished planning, they should start a fresh context window and instruct the agent to execute the plan and when done, submit-pr.
        2. Ask the user if they would like to tackle any other issues during this plan session.
        3. Once confirmed, start the next flow using `/batch-plan-linear-issues` with this current issue and any other issues specified in the previous step.
    - If they say no, notify the user that when they are ready they can start working on the issue by using the command `/batch-plan-linear-issues` with this issue and any other issues they would like to work on.