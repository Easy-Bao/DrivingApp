#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly readiness_timeout_seconds="${READINESS_TIMEOUT_SECONDS:-30}"
service_pids=()
service_build_directory=""

cleanup() {
  trap - EXIT INT TERM
  for pid in "${service_pids[@]}"; do kill "${pid}" 2>/dev/null || true; done
  for pid in "${service_pids[@]}"; do wait "${pid}" 2>/dev/null || true; done
  if [[ -n "${service_build_directory}" ]]; then
    rm -f "${service_build_directory}/core-api" \
      "${service_build_directory}/realtime-service" \
      "${service_build_directory}/api-gateway"
    rmdir "${service_build_directory}" 2>/dev/null || true
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "Required command '$1' was not found." >&2; exit 1; }
}

wait_for_http_service() {
  local url="$1"
  local deadline=$((SECONDS + readiness_timeout_seconds))
  until curl --fail --silent --show-error --max-time 2 "${url}" >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      echo "Service did not become ready at ${url}." >&2
      return 1
    fi
    sleep 1
  done
}

trap cleanup EXIT INT TERM
require_command go
require_command curl
require_command openssl
require_command mktemp

if [[ ! -f "${repository_root}/.env" ]]; then
  echo "Create .env with DATABASE_URL before starting the backend." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1091
source "${repository_root}/.env"
set +a

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required in .env." >&2
  exit 1
fi

for variable in GATEWAY_PORT CORE_API_URL REALTIME_SERVICE_URL REDIS_URL JWT_SECRET MAPBOX_ACCESS_TOKEN; do
  if [[ -z "${!variable:-}" ]]; then
    echo "${variable} is required in .env." >&2
    exit 1
  fi
done

cd "${repository_root}"
./scripts/database/migrate.sh

service_build_directory="$(mktemp -d /tmp/driveapp-services.XXXXXX)"
go_cache_directory="${GOCACHE:-/tmp/easyride-go-cache}"

(cd server && GOCACHE="${go_cache_directory}" go build -o "${service_build_directory}/core-api" ./cmd/core-api)
(cd server && GOCACHE="${go_cache_directory}" go build -o "${service_build_directory}/realtime-service" ./cmd/realtime-service)
(cd server && GOCACHE="${go_cache_directory}" go build -o "${service_build_directory}/api-gateway" ./api-gateway)

"${service_build_directory}/core-api" & service_pids+=("$!")
"${service_build_directory}/realtime-service" & service_pids+=("$!")
"${service_build_directory}/api-gateway" & service_pids+=("$!")

wait_for_http_service "http://127.0.0.1:${GATEWAY_PORT:-8000}/health"
echo "api-gateway is ready; core-api and realtime-service are private upstreams. Press Ctrl-C to stop them."
wait -n "${service_pids[@]}"
