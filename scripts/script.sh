#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ENV_FILE="$REPOSITORY_ROOT/.env"
readonly DEFAULT_WAIT_TIMEOUT_SECONDS=120
MOBILE_SERVICES=(
  postgres-db
  redis
  rabbitmq
  core-api
  realtime-service
  api-gateway
)
readonly MOBILE_SERVICES

command_name=""
build_images=1
wait_timeout_seconds="$DEFAULT_WAIT_TIMEOUT_SECONDS"

usage() {
  cat <<'USAGE'
Usage:
  ./scripts/script.sh --start [--no-build]
  ./scripts/script.sh --stop
  ./scripts/script.sh --restart [--no-build]
  ./scripts/script.sh --status
  ./scripts/script.sh --logs

Commands:
  --start       Build and start the mobile services.
  --stop        Stop the mobile services without deleting volumes.
  --restart     Stop, rebuild, and start the mobile services.
  --status      Show the state of the mobile service containers.
  --logs        Follow the mobile service logs.
  --no-build    Reuse existing images for --start or --restart.
  --help        Show this help.

This launcher is Docker-only. Native Go, PostgreSQL, Redis, and RabbitMQ
processes are intentionally not supported so the team uses one environment.
USAGE
}

die() {
  printf '[driveapp] error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '[driveapp] %s\n' "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

compose() {
  (
    cd -- "$REPOSITORY_ROOT"
    docker compose "$@"
  )
}

dotenv_value() {
  local key="$1"

  awk -F= -v requested_key="$key" '
    $1 == requested_key {
      value = substr($0, index($0, "=") + 1)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$ENV_FILE"
}

require_environment() {
  [[ -f "$ENV_FILE" ]] || die "Missing $ENV_FILE. Copy the team environment template first."

  local required_key
  local required_keys=(
    POSTGRES_USER
    POSTGRES_PASSWORD
    POSTGRES_DB
    JWT_SECRET
    GATEWAY_PORT
  )

  for required_key in "${required_keys[@]}"; do
    if ! awk -F= -v requested_key="$required_key" '
      $1 == requested_key && length($0) > length(requested_key) + 1 { found = 1 }
      END { exit(found ? 0 : 1) }
    ' "$ENV_FILE"; then
      die "Missing or empty $required_key in $ENV_FILE"
    fi
  done

  local configured_gateway_port
  configured_gateway_port="$(dotenv_value GATEWAY_PORT)"
  [[ "$configured_gateway_port" =~ ^[0-9]+$ ]] || die "GATEWAY_PORT must be numeric in $ENV_FILE"
  gateway_port="$configured_gateway_port"
}

validate_compose_file() {
  compose config --quiet || die "Docker Compose configuration is invalid. Check $ENV_FILE and docker-compose.yml."
}

wait_for_gateway() {
  if ! command -v curl >/dev/null 2>&1; then
    log "curl is not installed; Docker Compose startup completed without an HTTP readiness probe."
    return
  fi

  local health_url="http://127.0.0.1:${gateway_port}/health"
  local deadline=$((SECONDS + wait_timeout_seconds))

  log "Waiting for the API gateway at $health_url ..."
  until curl --fail --silent --show-error --max-time 5 "$health_url" >/dev/null 2>&1; do
    if (( SECONDS >= deadline )); then
      compose ps --all
      die "API gateway did not become ready within ${wait_timeout_seconds}s. Run './scripts/script.sh --logs' for details."
    fi
    sleep 1
  done

  log "API gateway is ready."
}

start_services() {
  require_environment
  validate_compose_file

  local build_flag=()
  if (( build_images == 1 )); then
    build_flag=(--build)
    log "Building Docker images and starting mobile services ..."
  else
    log "Starting mobile services with existing Docker images ..."
  fi

  compose up -d "${build_flag[@]}" --wait --wait-timeout "$wait_timeout_seconds" "${MOBILE_SERVICES[@]}"
  wait_for_gateway
  compose ps --all "${MOBILE_SERVICES[@]}"
}

stop_services() {
  require_environment
  validate_compose_file
  log "Stopping mobile services ..."
  compose stop "${MOBILE_SERVICES[@]}"
  compose ps --all "${MOBILE_SERVICES[@]}"
}

restart_services() {
  stop_services
  start_services
}

show_status() {
  require_environment
  validate_compose_file
  compose ps --all "${MOBILE_SERVICES[@]}"
}

show_logs() {
  require_environment
  validate_compose_file
  compose logs -f --tail=100 "${MOBILE_SERVICES[@]}"
}

parse_arguments() {
  while (($# > 0)); do
    case "$1" in
      --start|start)
        [[ -z "$command_name" ]] || die "Choose only one command"
        command_name="start"
        ;;
      --stop|stop)
        [[ -z "$command_name" ]] || die "Choose only one command"
        command_name="stop"
        ;;
      --restart|restart)
        [[ -z "$command_name" ]] || die "Choose only one command"
        command_name="restart"
        ;;
      --status|status)
        [[ -z "$command_name" ]] || die "Choose only one command"
        command_name="status"
        ;;
      --logs|logs)
        [[ -z "$command_name" ]] || die "Choose only one command"
        command_name="logs"
        ;;
      --no-build)
        build_images=0
        ;;
      --wait-timeout)
        shift
        (($# > 0)) || die "--wait-timeout requires a number of seconds"
        wait_timeout_seconds="$1"
        [[ "$wait_timeout_seconds" =~ ^[1-9][0-9]*$ ]] || die "--wait-timeout must be a positive integer"
        ;;
      --no-docker)
        die "This launcher is Docker-only; native mode is unsupported"
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1. Run './$SCRIPT_NAME --help' for usage."
        ;;
    esac
    shift
  done

  [[ -n "$command_name" ]] || {
    usage >&2
    exit 2
  }
}

main() {
  parse_arguments "$@"

  require_command docker
  docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required. Start Docker Desktop and try again."
  docker info >/dev/null 2>&1 || die "Docker Desktop/Engine is not running or is not reachable. Start it and try again."

  case "$command_name" in
    start)
      start_services
      ;;
    stop)
      stop_services
      ;;
    restart)
      restart_services
      ;;
    status)
      show_status
      ;;
    logs)
      show_logs
      ;;
  esac
}

main "$@"
