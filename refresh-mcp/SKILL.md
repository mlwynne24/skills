---
name: refresh-mcp
description: Trigger this skill every time the `rag-postgresql-mcp-server` repository is updated. It ensures that this repository is updated to the latest commit.
---

You must run from the repository root (as this uses `make` commands that rely on the Makefile in the root).

1. **Update the uv lock file** to pull the latest commit from the MCP repository:
   ```bash
   uv lock --upgrade-package rag-mcp
   ```

2. **Rebuild the MCP and API containers** without cache to ensure fresh install:
   ```bash
   make init-env
	eval "$(aws configure export-credentials --format env)" && \
	export GITHUB_TOKEN=$(gh auth token) && \
   docker compose build --no-cache api mcp
   ```

3. **Restart all services** with proper credentials:
   ```bash
   make dev-down && make dev-up
   ```

## Guardrails

- You **MUST** use the exact commands above (especially rebuild commands) to ensure that the environment has the necessary variables to build the container.
