#!/usr/bin/env bash

set -Eeuo pipefail

readonly script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly repository_root="$(cd "${script_directory}/.." && pwd)"
readonly readiness_timeout_seconds="${READINESS_TIMEOUT_SECONDS:-30}"
readonly local_database_url="$(awk -F= '$1 == "DATABASE_URL" { print substr($0, index($0, "=") + 1); exit }' "${repository_root}/.env")"

service_pids=()
service_names=()

cleanup() {
  local pid

  trap - EXIT INT TERM
  for pid in "${service_pids[@]}"; do
    kill "${pid}" 2>/dev/null || true
  done
  for pid in "${service_pids[@]}"; do
    wait "${pid}" 2>/dev/null || true
  done
}

handle_signal() {
  local exit_code="$1"
  exit "${exit_code}"
}

require_command() {
  local command_name="$1"
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command '${command_name}' was not found." >&2
    exit 1
  fi
}

assert_valid_timeout() {
  if [[ ! "${readiness_timeout_seconds}" =~ ^[1-9][0-9]*$ ]]; then
    echo "READINESS_TIMEOUT_SECONDS must be a positive integer." >&2
    exit 1
  fi
}

assert_port_available() {
  local port="$1"
  if (echo > "/dev/tcp/127.0.0.1/${port}") >/dev/null 2>&1; then
    echo "Port ${port} is already in use. Stop the existing process before running 'just start-all'." >&2
    exit 1
  fi
}

start_service() {
  local service_name="$1"
  local service_directory="$2"
  shift 2

  echo "Starting ${service_name}..."
  (
    cd "${repository_root}/${service_directory}"
    exec "$@"
  ) &
  service_pids+=("$!")
  service_names+=("${service_name}")
}

assert_services_running() {
  local index
  local exit_code

  for index in "${!service_pids[@]}"; do
    if ! kill -0 "${service_pids[index]}" 2>/dev/null; then
      exit_code=0
      wait "${service_pids[index]}" || exit_code="$?"
      echo "${service_names[index]} exited before startup completed (status ${exit_code})." >&2
      return 1
    fi
  done
}

wait_for_http_service() {
  local service_name="$1"
  local url="$2"
  local deadline=$((SECONDS + readiness_timeout_seconds))

  until curl --fail --silent --show-error --max-time 2 "${url}" >/dev/null 2>&1; do
    assert_services_running
    if (( SECONDS >= deadline )); then
      echo "${service_name} did not become ready at ${url} within ${readiness_timeout_seconds}s." >&2
      return 1
    fi
    sleep 1
  done

  echo "${service_name} is ready at ${url}."
}

wait_for_gateway_auth_proxy() {
  local url='http://127.0.0.1:8080/auth/passenger/login'
  local deadline=$((SECONDS + readiness_timeout_seconds))
  local status_code

  while true; do
    status_code="$(
      curl --silent --output /dev/null --write-out '%{http_code}' \
        --max-time 2 \
        --request POST \
        --header 'Content-Type: application/json' \
        --data '{}' \
        "${url}" || true
    )"
    if [[ "${status_code}" == '400' ]]; then
      echo "Gateway can reach the authentication service."
      return 0
    fi

    assert_services_running
    if (( SECONDS >= deadline )); then
      echo "Gateway authentication proxy was not ready within ${readiness_timeout_seconds}s (last HTTP status: ${status_code:-none})." >&2
      return 1
    fi
    sleep 1
  done
}

trap cleanup EXIT
trap 'handle_signal 130' INT
trap 'handle_signal 143' TERM

require_command bun
require_command curl
require_command go
assert_valid_timeout

if [[ -z "${local_database_url}" ]]; then
  echo "DATABASE_URL is required in the root .env for local services." >&2
  exit 1
fi

for port in {8080..8089}; do
  assert_port_available "${port}"
done

start_service api-gateway server/api-gateway bun run dev
start_service auth-service server/auth-service \
  env DATABASE_URL="${local_database_url}" \
  PASSENGER_DB_URL="${local_database_url}" \
  DRIVER_DB_URL="${local_database_url}" \
  bun run dev
start_service passenger-service server/passenger-service env DATABASE_URL="${local_database_url}" bun run dev
start_service driver-service server/driver-service env DATABASE_URL="${local_database_url}" bun run dev
start_service trip-service server/trip-service env DATABASE_URL="${local_database_url}" bun run dev
start_service bidding-service server/bidding-service env DATABASE_URL="${local_database_url}" bun run dev
start_service telemetry-service server/telemetry-service bun run dev
start_service chat-service server/chat-service env DATABASE_URL="${local_database_url}" bun run dev
start_service fare-service server/fare-service env DATABASE_URL="${local_database_url}" bun run dev
start_service location-service server/location-service \
  env REDIS_URL=redis://127.0.0.1:6379 \
  RABBITMQ_URL=amqp://guest:guest@127.0.0.1:5672/ \
  go run ./cmd/main.go

wait_for_http_service auth-service http://127.0.0.1:8088/
wait_for_http_service api-gateway http://127.0.0.1:8080/
wait_for_gateway_auth_proxy

echo "All local services started. Press Ctrl-C to stop application processes."

set +e
wait -n "${service_pids[@]}"
service_exit_code="$?"
set -e

if (( service_exit_code == 0 )); then
  service_exit_code=1
fi
echo "A local service exited unexpectedly (status ${service_exit_code}); stopping the remaining services." >&2
exit "${service_exit_code}"
