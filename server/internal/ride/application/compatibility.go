package application

import "github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"

// EventPublisher is retained at the application package for existing callers.
// New wiring should depend on ride/ports.EventPublisher.
type EventPublisher = ports.EventPublisher
