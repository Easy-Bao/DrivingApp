#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly readiness_timeout_seconds="${READINESS_TIMEOUT_SECONDS:-30}"
service_pids=()

cleanup() {
  trap - EXIT INT TERM
  for pid in "${service_pids[@]}"; do kill "${pid}" 2>/dev/null || true; done
  for pid in "${service_pids[@]}"; do wait "${pid}" 2>/dev/null || true; done
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

cd "${repository_root}"
./scripts/database/migrate.sh

(cd server && go run ./cmd/core-api) & service_pids+=("$!")
(cd server && go run ./cmd/realtime-service) & service_pids+=("$!")

wait_for_http_service "http://127.0.0.1:${CORE_API_PORT:-8080}/health"
echo "core-api and realtime-service are ready. Press Ctrl-C to stop them."
wait -n "${service_pids[@]}"
