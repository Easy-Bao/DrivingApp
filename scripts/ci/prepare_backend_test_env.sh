#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly test_database_url="postgresql://driveapp:driveapp_ci_password@127.0.0.1:5432/passenger_db"
readonly passenger_database_url="postgresql://driveapp:driveapp_ci_password@127.0.0.1:5432/passenger_db"
readonly driver_database_url="postgresql://driveapp:driveapp_ci_password@127.0.0.1:5432/driver_db"
readonly ci_jwt_secret_value="ci_jwt_secret_for_automated_test_runs_only"
readonly service_directories=(
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

if [[ -f .env && "${CI:-}" != "true" ]]; then
  echo "Refusing to overwrite an existing local .env outside CI." >&2
  exit 1
fi

cat > .env <<EOF
POSTGRES_USER=driveapp
POSTGRES_PASSWORD=driveapp_ci_password
POSTGRES_DB=passenger_db
DATABASE_URL=${test_database_url}
PASSENGER_DB_URL=${passenger_database_url}
DRIVER_DB_URL=${driver_database_url}
JWT_SECRET=${ci_jwt_secret_value}
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=ci@example.test
SMTP_PASS=ci_smtp_password
SMTP_FROM=ci@example.test
AUTH_SERVICE_URL=http://127.0.0.1:8088
PASSENGER_SERVICE_URL=http://127.0.0.1:8081
DRIVER_SERVICE_URL=http://127.0.0.1:8082
TRIP_SERVICE_URL=http://127.0.0.1:8083
BIDDING_SERVICE_URL=http://127.0.0.1:8084
TELEMETRY_SERVICE_URL=http://127.0.0.1:8085
CHAT_SERVICE_URL=http://127.0.0.1:8086
FARE_SERVICE_URL=http://127.0.0.1:8087
LOCATION_SERVICE_URL=http://127.0.0.1:8089
EOF

for service_directory in "${service_directories[@]}"; do
  cat > "${service_directory}/.env.test" <<EOF
DATABASE_URL=${test_database_url}
PASSENGER_DB_URL=${passenger_database_url}
DRIVER_DB_URL=${driver_database_url}
JWT_SECRET=${ci_jwt_secret_value}
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_USER=ci@example.test
SMTP_PASS=ci_smtp_password
SMTP_FROM=ci@example.test
AUTH_SERVICE_URL=http://127.0.0.1:8088
PASSENGER_SERVICE_URL=http://127.0.0.1:8081
DRIVER_SERVICE_URL=http://127.0.0.1:8082
TRIP_SERVICE_URL=http://127.0.0.1:8083
BIDDING_SERVICE_URL=http://127.0.0.1:8084
TELEMETRY_SERVICE_URL=http://127.0.0.1:8085
CHAT_SERVICE_URL=http://127.0.0.1:8086
FARE_SERVICE_URL=http://127.0.0.1:8087
LOCATION_SERVICE_URL=http://127.0.0.1:8089
EOF
done

echo "Backend CI environment files are ready."
