#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Keep the historical entrypoint, but route it through the Docker-only launcher.
exec "${repository_root}/scripts/script.sh" "$@"
