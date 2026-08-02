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

if [[ ! -f .env ]]; then
  echo "Required root .env file was not found." >&2
  exit 1
fi

for service_directory in "${schema_service_directories[@]}"; do
  echo "Applying schema for ${service_directory}"
  (
    cd "${service_directory}"
    bun --env-file ../../.env run db:push
  )
done

echo "Applying migrations for server/admin-service"
(
  cd server/admin-service
  bun --env-file ../../.env run db:migrate
)
