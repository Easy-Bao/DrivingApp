# Database bootstrap

Ent owns PostgreSQL schema creation and migration through `server/cmd/migrate`.
This directory intentionally contains no raw bootstrap SQL; it remains as the
Compose/database boundary for deployments that mount an initialization path.
