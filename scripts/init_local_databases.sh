#!/usr/bin/env bash

set -Eeuo pipefail

readonly script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repository_root="$(cd "${script_directory}/.." && pwd)"
readonly schema_file="${script_directory}/sql/local_auth_schema.sql"

cd "${repository_root}"

if ! command -v docker >/dev/null 2>&1; then
  echo "Required command 'docker' was not found." >&2
  exit 1
fi

if ! docker compose ps --status running --services | grep -qx 'postgres-db'; then
  echo "PostgreSQL is not running. Run 'just infra-up' first." >&2
  exit 1
fi

if ! docker compose exec -T postgres-db \
  sh -c 'pg_isready --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"' \
  >/dev/null; then
  echo "PostgreSQL is running but is not ready to accept connections." >&2
  exit 1
fi

echo "Initializing local service databases and authentication tables..."
docker compose exec -T postgres-db \
  sh -c 'psql --set ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"' \
  < "${schema_file}"
echo "Local database schema is ready."
