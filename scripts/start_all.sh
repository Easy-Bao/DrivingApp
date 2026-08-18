#!/usr/bin/env bash

set -Eeuo pipefail

readonly repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Keep the historical Docker entrypoint for contributors who explicitly use it.
exec "${repository_root}/scripts/script.sh" "$@"
