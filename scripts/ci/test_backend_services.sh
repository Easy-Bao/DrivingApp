#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly bun_service_directories=(
  "server/api-gateway"
  "server/auth-service"
  "server/bidding-service"
  "server/chat-service"
  "server/driver-service"
  "server/fare-service"
  "server/passenger-service"
  "server/telemetry-service"
  "server/trip-service"
)

cd "${repository_root}"

./scripts/database/apply_service_schemas.sh

for service_directory in "${bun_service_directories[@]}"; do
  echo "Testing ${service_directory}"
  (
    cd "${service_directory}"
    bun run test
  )
done
