#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly test_database_url="postgresql://driveapp:driveapp_ci_password@127.0.0.1:5432/driveapp"

cd "${repository_root}"

if [[ -f .env && "${CI:-}" != "true" ]]; then
  echo "Refusing to overwrite an existing local .env outside CI." >&2
  exit 1
fi

cat > .env <<EOF
POSTGRES_USER=driveapp
POSTGRES_PASSWORD=driveapp_ci_password
POSTGRES_DB=driveapp
DATABASE_URL=${test_database_url}
JWT_SECRET=ci_jwt_secret_for_automated_test_runs_only
CORE_API_URL=http://core-api:8080
REALTIME_SERVICE_URL=http://realtime-service:8081
CORE_API_INTERNAL_URL=http://core-api:8080
REALTIME_SERVICE_INTERNAL_URL=http://realtime-service:8081
GATEWAY_PORT=8000
REDIS_URL=redis://127.0.0.1:6379
RABBITMQ_URL=amqp://127.0.0.1:5672
EOF

echo "Backend CI environment files are ready."
