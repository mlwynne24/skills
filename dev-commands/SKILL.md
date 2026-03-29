---
name: dev-commands
description: This skill should be used when the user asks you to run "development commands", "start services", "run migrations", "database commands", or discusses local development tasks. Guides Claude to consult the Makefile for standardized development commands. This skill should be loaded before running `docker compose *` commands directly.
---

# Development Commands

When the user asks about development commands, how to start services, run migrations, or perform common development tasks, **always consult the Makefile first** at `/home/ubuntu/repos/aisi-knowledge-hub-chat-integration/Makefile`. Commands must be run from the repo root.
