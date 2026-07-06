#!/usr/bin/env bash

devices=$(adb devices | tail -n +2 | cut -sf 1)

if [ -z "$devices" ]; then
  echo "❌ No Android devices or emulators found."
  exit 0
fi

ports=(8080 8081 8082 8083 8084 8085 8086)

echo "Reversing ports for all connected Android devices..."
for device in $devices; do
  echo "📱 Device: $device"
  for port in "${ports[@]}"; do
    if adb -s "$device" reverse tcp:"$port" tcp:"$port" >/dev/null 2>&1; then
      echo "   tcp:$port tcp:$port"
    else
      echo "   tcp:$port tcp:$port (failed/already configured)"
    fi
  done
done
echo "Port forwarding complete!"
