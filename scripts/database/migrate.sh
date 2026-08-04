#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ -z "${DATABASE_URL:-}" ]]; then
  if [[ ! -f "${repository_root}/.env" ]]; then
    echo "DATABASE_URL is required." >&2
    exit 1
  fi
  DATABASE_URL="$(awk -F= '$1 == "DATABASE_URL" { print substr($0, index($0, "=") + 1); exit }' "${repository_root}/.env")"
fi

if [[ -z "${DATABASE_URL}" ]]; then
  echo "DATABASE_URL is required." >&2
  exit 1
fi

# Local Compose Postgres does not expose SSL. Keep production URLs untouched,
# while making the development migration explicit and repeatable.
if [[ "${DATABASE_URL}" == *"127.0.0.1"* || "${DATABASE_URL}" == *"localhost"* ]] && [[ "${DATABASE_URL}" != *"sslmode="* ]]; then
  DATABASE_URL="${DATABASE_URL}?sslmode=disable"
fi

cd "${repository_root}/server"
GOCACHE="${GOCACHE:-/tmp/easyride-go-cache}" DATABASE_URL="${DATABASE_URL}" go run ./cmd/migrate
