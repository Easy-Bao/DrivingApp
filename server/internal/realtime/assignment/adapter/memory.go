package adapter

import (
	"context"
	"encoding/json"
	"sort"
	"strings"
	"sync"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

// MemoryProjection keeps the small active-assignment index needed by high
// frequency driver telemetry. It is a routing hint only; ride authorization
// continues to use the PostgreSQL-backed authority in assignment.Resolver.
type MemoryProjection struct {
	mu       sync.RWMutex
	byRide   map[string]assignment.Assignment
	byDriver map[string]map[string]struct{}
}

func NewMemoryProjection() *MemoryProjection {
	return &MemoryProjection{
		byRide:   make(map[string]assignment.Assignment),
		byDriver: make(map[string]map[string]struct{}),
	}
}

// Publish applies only ride lifecycle events. Location and chat events do not
// affect assignment routing and are ignored.
func (projection *MemoryProjection) Publish(envelope event.Envelope) {
	if projection == nil {
		return
	}
	switch envelope.Type {
	case event.RideMatched:
		status := rideStatus(envelope.Payload)
		if status == "" {
			status = "assigned"
		}
		projection.upsert(envelope.Scope, status)
	case event.RideStatusChanged:
		status := rideStatus(envelope.Payload)
		if isTerminal(status) {
			projection.remove(envelope.Scope.RideID)
			return
		}
		if status != "" {
			projection.upsert(envelope.Scope, status)
		}
	}
}

func (projection *MemoryProjection) ForRide(_ context.Context, rideID string) (assignment.Assignment, bool, error) {
	projection.mu.RLock()
	defer projection.mu.RUnlock()
	value, found := projection.byRide[rideID]
	return value, found, nil
}

func (projection *MemoryProjection) ForDriver(_ context.Context, driverID string) ([]assignment.Assignment, error) {
	projection.mu.RLock()
	defer projection.mu.RUnlock()

	rideIDs := make([]string, 0, len(projection.byDriver[driverID]))
	for rideID := range projection.byDriver[driverID] {
		rideIDs = append(rideIDs, rideID)
	}
	sort.Strings(rideIDs)
	values := make([]assignment.Assignment, 0, len(rideIDs))
	for _, rideID := range rideIDs {
		values = append(values, projection.byRide[rideID])
	}
	return values, nil
}

// Remember refreshes one driver's routing slice from the authoritative ride
// query. Clearing that slice first prevents a stale in-memory assignment from
// surviving a cache miss or process restart recovery.
func (projection *MemoryProjection) Remember(driverID string, values []assignment.Assignment) {
	if projection == nil || driverID == "" {
		return
	}
	projection.mu.Lock()
	defer projection.mu.Unlock()
	for rideID := range projection.byDriver[driverID] {
		if value, found := projection.byRide[rideID]; found && value.DriverID == driverID {
			delete(projection.byRide, rideID)
		}
	}
	delete(projection.byDriver, driverID)
	for _, value := range values {
		if value.RideID == "" || value.DriverID != driverID || value.PassengerID == "" {
			continue
		}
		projection.upsertLocked(value)
	}
}

func (projection *MemoryProjection) upsert(scope event.Scope, status string) {
	if scope.RideID == "" || scope.DriverID == "" || scope.PassengerID == "" {
		return
	}
	value := assignment.Assignment{
		RideID:      scope.RideID,
		DriverID:    scope.DriverID,
		PassengerID: scope.PassengerID,
		Status:      status,
	}

	projection.mu.Lock()
	defer projection.mu.Unlock()
	projection.upsertLocked(value)
}

func (projection *MemoryProjection) upsertLocked(value assignment.Assignment) {
	if previous, found := projection.byRide[value.RideID]; found && previous.DriverID != value.DriverID {
		projection.removeDriverAssignment(previous.DriverID, value.RideID)
	}
	projection.byRide[value.RideID] = value
	if projection.byDriver[value.DriverID] == nil {
		projection.byDriver[value.DriverID] = make(map[string]struct{})
	}
	projection.byDriver[value.DriverID][value.RideID] = struct{}{}
}

func (projection *MemoryProjection) remove(rideID string) {
	if rideID == "" {
		return
	}
	projection.mu.Lock()
	defer projection.mu.Unlock()
	if value, found := projection.byRide[rideID]; found {
		projection.removeDriverAssignment(value.DriverID, rideID)
		delete(projection.byRide, rideID)
	}
}

func (projection *MemoryProjection) removeDriverAssignment(driverID, rideID string) {
	rides := projection.byDriver[driverID]
	delete(rides, rideID)
	if len(rides) == 0 {
		delete(projection.byDriver, driverID)
	}
}

func rideStatus(payload []byte) string {
	var value struct {
		Ride struct {
			Status string `json:"status"`
		} `json:"ride"`
	}
	if json.Unmarshal(payload, &value) != nil {
		return ""
	}
	return strings.ToLower(strings.TrimSpace(value.Ride.Status))
}

func isTerminal(status string) bool {
	switch status {
	case "completed", "canceled", "cancelled":
		return true
	default:
		return false
	}
}
