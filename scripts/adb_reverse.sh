#!/usr/bin/env bash

set -Eeuo pipefail

if ! command -v adb >/dev/null 2>&1; then
  echo "Required command 'adb' was not found." >&2
  exit 1
fi

mapfile -t connected_device_ids < <(
  adb devices | awk 'NR > 1 && $2 == "device" { print $1 }'
)

if (( ${#connected_device_ids[@]} == 0 )); then
  echo "No authorized Android devices or emulators were found." >&2
  exit 1
fi

readonly gateway_port=8000
failed_mapping_count=0

echo "Reversing ports for all connected Android devices..."
for device_id in "${connected_device_ids[@]}"; do
  echo "Device: ${device_id}"
  if adb -s "${device_id}" reverse \
    "tcp:${gateway_port}" "tcp:${gateway_port}" >/dev/null; then
    echo "   tcp:${gateway_port} -> tcp:${gateway_port}"
  else
    echo "   Failed to reverse tcp:${gateway_port} for ${device_id}." >&2
    failed_mapping_count=$((failed_mapping_count + 1))
  fi
done

if (( failed_mapping_count > 0 )); then
  echo "Port forwarding failed for ${failed_mapping_count} mapping(s)." >&2
  exit 1
fi

echo "Port forwarding complete."
