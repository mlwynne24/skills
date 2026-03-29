---
name: create-db-migration
description: Trigger after every change to database models and whenever a new database migration is required.
---

# Development Commands

When a the database schema has been updated, a new migration **MUST** be created and applied to the database. This is done via auto-generate functionality in sqlmodel The Makefile provides targets to manage this process:

1) First, ensure that you have made any planned changes to the SQLModel models in `src/api/src/api/db/models.py` (or any new models you are adding).
2) Export the database environment variables: `export POSTGRES_USER=postgres POSTGRES_PASSWORD=postgres POSTGRES_DB=knowledge_hub POSTGRES_HOST=localhost POSTGRES_PORT=5432`
3) Run `make db-up` command to run the database in a Docker container (if not already running).
4) You must then run `make db-create-migration` — Create new migration (prompts for message).
5) Enter a descriptive, short underscore-separated message (e.g. `add_user_table`).
6) A migrations file will be created. Review the generated migration file and make any necessary adjustments (although these are not generally needed).
7) **Important**: Alembic autogenerate only detects changes reflected in SQLModel models. For manual SQL changes (e.g. tsvector generated columns, GIN indexes, custom constraints), you must add `op.execute(...)` statements to the migration's `upgrade()` and `downgrade()` functions yourself.
8) Once the migration file is ready, run `make db-run-migrations` to apply the migration to the database.