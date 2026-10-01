# EasyRide Driver

The driver client reads its public runtime configuration from the local `.env`
asset. Copy `.env.example` to `.env`, set the API origin and Mapbox public
token, then bootstrap the workspace from the repository root.

`API_BASE_URL` must be a complete HTTP or HTTPS origin, including its configured
gateway port. Release builds require HTTPS. Local Android emulators rewrite a
loopback origin through `ANDROID_EMULATOR_LOOPBACK_HOST` unless adb reverse is
enabled; physical devices must use an API host reachable from that device.

For USB debugging, run `just adb-reverse` and set
`ANDROID_USE_ADB_REVERSE=true` while keeping the loopback API origin. For
local Wi-Fi testing, use the computer's LAN address in `API_BASE_URL` and
expose the native API or Compose gateway on a development-only network
interface. Release builds intentionally require HTTPS.

`ENABLE_DRIVER_BACKGROUND_TELEMETRY` is enabled by default so the driver keeps
an Android foreground location service and sticky notification while online,
including when a third-party navigation app is in the foreground. Set it to
`false` only for builds that intentionally opt out of background location
sharing.

Values in this file are bundled with the application and are not secrets.
Server credentials, signing material, and private access tokens belong only in
the root server environment or the platform secret store.
