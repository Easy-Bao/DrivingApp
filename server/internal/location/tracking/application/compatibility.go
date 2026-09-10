package application

import trackingports "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/ports"

// EventPublisher is the location application's outbound seam for transient
// event delivery. The location store remains authoritative for recovery.
type EventPublisher = trackingports.EventPublisher
