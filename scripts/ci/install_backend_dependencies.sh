#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repository_root}"
cd server
GOCACHE="${GOCACHE:-/tmp/easyride-go-cache}" go mod download
