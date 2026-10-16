package redis

import (
	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
)

// LocationStore is the tracking module's persistence boundary for telemetry
// and active-ride location.
type LocationStore = locationapp.LocationStore
