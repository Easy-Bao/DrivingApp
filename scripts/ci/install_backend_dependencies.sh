#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly bun_service_directories=(
  "server/admin-service"
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

for service_directory in "${bun_service_directories[@]}"; do
  echo "Installing dependencies in ${service_directory}"
  (
    cd "${service_directory}"
    bun install --frozen-lockfile
  )
done

(
  cd server/location-service
  go mod download
)
