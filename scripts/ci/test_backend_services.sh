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

run_service_tests() {
  local service_directory="$1"

  cd "${repository_root}/${service_directory}"
  if [[ "${service_directory}" == "server/auth-service" ]]; then
    local shared_test_database_url
    shared_test_database_url="$(awk -F= '$1 == "DATABASE_URL" { value = substr($0, index($0, "=") + 1); gsub(/"/, "", value); print value; exit }' .env.test)"
    DATABASE_URL="${shared_test_database_url}" \
    PASSENGER_DB_URL="${shared_test_database_url}" \
    DRIVER_DB_URL="${shared_test_database_url}" \
    bun run test
  else
    bun run test
  fi
}

for service_directory in "${bun_service_directories[@]}"; do
  echo "Testing ${service_directory}"
  run_service_tests "${service_directory}"
done
