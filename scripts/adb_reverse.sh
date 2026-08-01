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

readonly service_ports=(8080 8081 8082 8083 8084 8085 8086 8087 8088 8089)
failed_mapping_count=0

echo "Reversing ports for all connected Android devices..."
for device_id in "${connected_device_ids[@]}"; do
  echo "Device: ${device_id}"
  for service_port in "${service_ports[@]}"; do
    if adb -s "${device_id}" reverse \
      "tcp:${service_port}" "tcp:${service_port}" >/dev/null; then
      echo "   tcp:${service_port} -> tcp:${service_port}"
    else
      echo "   Failed to reverse tcp:${service_port} for ${device_id}." >&2
      failed_mapping_count=$((failed_mapping_count + 1))
    fi
  done
done

if (( failed_mapping_count > 0 )); then
  echo "Port forwarding failed for ${failed_mapping_count} mapping(s)." >&2
  exit 1
fi

echo "Port forwarding complete."
