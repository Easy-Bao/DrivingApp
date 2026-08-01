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

for service_directory in "${bun_service_directories[@]}"; do
  if [[ -f "${service_directory}/tsconfig.json" ]]; then
    echo "Type checking ${service_directory}"
    (
      cd "${service_directory}"
      bunx tsc --noEmit
    )
  else
    echo "Skipping ${service_directory}; no type-check configuration found."
  fi
done
