#!/usr/bin/env bash

set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
environment_file="${DRIVER_ENV_FILE:-$repository_root/apps/driver_app/.env}"

if [[ ! -f "$environment_file" ]]; then
  printf 'Missing Driver environment file: %s\n' "$environment_file" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$environment_file"
set +a

required_variables=(DRIVER_SERVICE_URL PLACE_SERVICE_BASE_URL)
for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    printf '%s is required in %s\n' "$variable_name" "$environment_file" >&2
    exit 1
  fi
done

dart_defines=(
  "--dart-define=DRIVER_SERVICE_URL=${DRIVER_SERVICE_URL}"
  "--dart-define=PLACE_SERVICE_BASE_URL=${PLACE_SERVICE_BASE_URL}"
)

optional_variables=(
  MAPBOX_PUBLIC_TOKEN
  AUTH_SERVICE_URL
  TRIP_SERVICE_URL
  OFFLINE_MODE
  PHYSICAL_DEVICE
  ANDROID_EMULATOR_LOOPBACK_HOST
)
for variable_name in "${optional_variables[@]}"; do
  if [[ -n "${!variable_name:-}" ]]; then
    dart_defines+=("--dart-define=${variable_name}=${!variable_name}")
  fi
done

cd "$repository_root/apps/driver_app"
exec flutter run "${dart_defines[@]}" "$@"
