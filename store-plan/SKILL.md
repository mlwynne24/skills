---
name: store-plan
description: Trigger **EVERY TIME** a plan is created or updated. A plan could come from a 1) a user message implied that you should brainstorm/plan, 2) you are in plan mode and you are about to finalise the plan, 3) the conversation context implies that you are planning/brainstorming an implementation. It saves the current version of the plan to `<project-root>/docs/plans/` for in-repo reference and historical tracking.
---

## Instructions

- Save the latest version of the plan to `docs/plans/YYYYMMDD/<plan_name>`
- Give the plan an appropriate name, e.g. for a plan that implements adding a password to the login flow and the current date is 02/02/2026, the plan should be saved to `docs/plans/20260202/add_password_to_login_flow.md`.

## Guardrails

- Always save as a .md file.
