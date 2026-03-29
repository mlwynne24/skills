---
name: where-are-we-at
description: "A skill to onboard new developers to the project and help them get up to speed on the current state of the codebase, architecture, and development practices."
---

# Where Are We At?

This skill walks a new developer through the current state of the project, including:
1. Prerequisites setup
2. Architecture overview
3. Common commands and development environment setup
4. Infrastructure management with the `platform-lib-cdk` library
5. CI/CD workflows for deploying infrastructure changes
6. Logging and monitoring setup
7. Documentation
8. Linear & backlog issues

## Checklist for Onboarding New Developers

Run through these instructions sequentially. Use the AskUserQuestion tool to get user input and confirm each step before moving to the next.

1. Check the `README.md` "Prerequisites" section and check whether the user has the necessary access and tools set up. You should:
    - Confirm the user's DSIT email (useful for later steps)
    - Confirm that they are running on an AISI research platform VM
    - Check the research platform GH repository and confirm that the user (their email) has an entry in:
        - https://github.com/AI-Safety-Institute/aisi-research-platform/blob/main/access_control/config/users.yaml
        - https://github.com/AI-Safety-Institute/aisi-research-platform/blob/main/access_control/config/teams/analysis.yaml
        - If they do not, instruct them to raise a PR to add themselves, following existing entries as examples
    - Check that they have Read access to the rag-postgresql-mcp-server private repo. If not, instruct them to request access from Anna Becker
    - If they are on an AISI research platform VM, they will have access to docker and docker compose.
    - Check that they have authenticated with GitHub CLI. If they haven't, instruct them to do so using `gh auth login`.
2. Provide a high-level architecture overview, walking through the directory structure and explaining the purpose of each component (common, api, ui, mcp, infra/cdk).
3. Introduce the development environment setup, including the docker compose configuration and how to run the development environment locally using the Make commands.
4. Explain the `infra/cdk` directory and how the `platform-lib-cdk` is used to manage infrastructure. Walk through the process of deploying infrastructure changes (GitHub workflow).
5. Walk through the CI/CD setup for the project, including each of the GH workflows with a focus on the `deploy-prod` workflow and how it deploys infrastructure changes to production.
6. Explain the logging and monitoring setup, including how to access logs (see `src/api/src/api/services/query_logger.py` and endpoints in `src/api/src/api/routes/chat.py`)
7. Point them to the documentation directories (`docs/docs`, `docs/plans`, `docs/reviews`, `docs/notes`) and explain the purpose of each.
8. Pull the current Linear issues and backlog items, and walk through them to give a sense of the current priorities and general backlog.

Finally, notify the user that to get help on any specific topic, they can ask you questions or use the `/sos` skill.

## Guardrails

- Always confirm each step with the user before proceeding to the next one
- Always give the user the option to add free text questions or comments at each step. Feel free to go off course to explain something to the user. But **ALWAYS** return to the sequential instructions after addressing their questions/comments.
- You should not assume you are an expert. Please explore relevant files and documentation extensively before each step to ensure you have a deep understanding of the topic you are explaining to the user. Use the SearchFiles and ReadFile tools extensively to build this understanding.