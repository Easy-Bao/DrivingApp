package redis

import (
	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
)

// DriverPresenceReader is the server-owned availability check used before
// accepting driver telemetry. The mobile client's online flag is not an
// authority for publishing location.
type DriverPresenceReader = locationapp.DriverPresenceReader

type DriverPresenceReaderFunc = locationapp.DriverPresenceReaderFunc
