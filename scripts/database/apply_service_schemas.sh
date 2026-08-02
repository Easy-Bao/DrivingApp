#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly schema_service_directories=(
  "server/passenger-service"
  "server/driver-service"
  "server/trip-service"
  "server/bidding-service"
  "server/chat-service"
  "server/fare-service"
)

cd "${repository_root}"

if ! command -v openssl >/dev/null 2>&1; then
  echo "Required command 'openssl' was not found." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  echo "Required root .env file was not found." >&2
  exit 1
fi

local_database_url="$(awk -F= '$1 == "DATABASE_URL" { print substr($0, index($0, "=") + 1); exit }' .env)"
local_postgres_user="$(awk -F= '$1 == "POSTGRES_USER" { print substr($0, index($0, "=") + 1); exit }' .env)"
local_postgres_database="$(awk -F= '$1 == "POSTGRES_DB" { print substr($0, index($0, "=") + 1); exit }' .env)"
if [[ -z "${local_database_url}" ]]; then
  echo "DATABASE_URL is required in the root .env." >&2
  exit 1
fi
if [[ -z "${local_postgres_user}" || -z "${local_postgres_database}" ]]; then
  echo "POSTGRES_USER and POSTGRES_DB are required in the root .env." >&2
  exit 1
fi

local_admin_jwt_secret="${ADMIN_JWT_SECRET:-}"
if [[ -z "${local_admin_jwt_secret}" ]]; then
  local_admin_jwt_secret="$(openssl rand -hex 32)"
fi

echo "Ensuring admin_db exists"
ADMIN_JWT_SECRET="${local_admin_jwt_secret}" docker compose exec -T postgres-db \
  psql -v ON_ERROR_STOP=1 -U "${local_postgres_user}" -d "${local_postgres_database}" <<'SQL'
SELECT 'CREATE DATABASE admin_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'admin_db')\gexec
SQL

for service_directory in "${schema_service_directories[@]}"; do
  echo "Applying schema for ${service_directory}"
  (
    cd "${service_directory}"
    bun run --env-file ../../.env db:push
  )
done

echo "Applying migrations for server/admin-service"
(
  cd server/admin-service
  DATABASE_URL="${local_database_url%/*}/admin_db" bun run --env-file ../../.env db:migrate
)
