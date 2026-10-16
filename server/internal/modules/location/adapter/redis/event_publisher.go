package redis

import (
	locationapp "github.com/Easy-Bao/DrivingApp/server/internal/modules/location/app"
)

// EventPublisher delivers location notifications to the process-local event
// transport. Active ride REST endpoints remain authoritative for recovery.
type EventPublisher = locationapp.EventPublisher
