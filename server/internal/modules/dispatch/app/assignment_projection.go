package app

import (
	"context"
	"encoding/json"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

const (
	_defaultEmptyDriverCacheTTL = 15 * time.Second
	_defaultMaxEmptyDrivers     = 10_000
)

// MemoryProjection keeps the small active-assignment index needed by high
// frequency driver telemetry. It is a routing hint only; ride authorization
// continues to use the PostgreSQL-backed authority in assignment.Resolver.
type MemoryProjection struct {
	mu              sync.RWMutex
	byRide          map[string]Assignment
	byDriver        map[string]map[string]struct{}
	emptyDrivers    map[string]time.Time
	emptyTTL        time.Duration
	maxEmptyDrivers int
	now             func() time.Time
}

var _ Projection = (*MemoryProjection)(nil)

func NewMemoryProjection() *MemoryProjection {
	return &MemoryProjection{
		byRide:          make(map[string]Assignment),
		byDriver:        make(map[string]map[string]struct{}),
		emptyDrivers:    make(map[string]time.Time),
		emptyTTL:        _defaultEmptyDriverCacheTTL,
		maxEmptyDrivers: _defaultMaxEmptyDrivers,
		now:             time.Now,
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
		if !(Assignment{Status: status}).Active() {
			projection.remove(envelope.Scope.RideID)
			return
		}
		projection.upsert(envelope.Scope, status)
	case event.RideStatusChanged:
		status := rideStatus(envelope.Payload)
		if status == "" {
			return
		}
		if !(Assignment{Status: status}).Active() {
			projection.remove(envelope.Scope.RideID)
			return
		}
		projection.upsert(envelope.Scope, status)
	}
}

func (projection *MemoryProjection) ForRide(
	_ context.Context,
	rideID string,
) (Assignment, bool, error) {
	projection.mu.RLock()
	defer projection.mu.RUnlock()
	value, found := projection.byRide[rideID]
	if !found || !value.Active() {
		return Assignment{}, false, nil
	}
	return value, true, nil
}

func (projection *MemoryProjection) ForDriver(
	ctx context.Context,
	driverID string,
) ([]Assignment, error) {
	values, _, err := projection.ForDriverCached(ctx, driverID)
	return values, err
}

func (projection *MemoryProjection) ForDriverCached(
	_ context.Context,
	driverID string,
) ([]Assignment, bool, error) {
	projection.mu.RLock()
	defer projection.mu.RUnlock()

	if rides := projection.byDriver[driverID]; len(rides) > 0 {
		rideIDs := make([]string, 0, len(rides))
		for rideID := range rides {
			rideIDs = append(rideIDs, rideID)
		}
		sort.Strings(rideIDs)
		values := make([]Assignment, 0, len(rideIDs))
		for _, rideID := range rideIDs {
			values = append(values, projection.byRide[rideID])
		}
		return values, true, nil
	}
	if expiresAt, knownEmpty := projection.emptyDrivers[driverID]; knownEmpty && projection.currentTime().Before(expiresAt) {
		return []Assignment{}, true, nil
	}
	return []Assignment{}, false, nil
}

// Remember refreshes one driver's routing slice from the authoritative ride
// query. Clearing that slice first prevents a stale in-memory assignment from
// surviving a cache miss or process restart recovery. Non-active rides are
// excluded because this projection tracks active telemetry routing only.
func (projection *MemoryProjection) Remember(driverID string, values []Assignment) {
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
	delete(projection.emptyDrivers, driverID)
	stored := 0
	for _, value := range values {
		missingRideID := value.RideID == ""
		wrongDriver := value.DriverID != driverID
		missingPassengerID := value.PassengerID == ""
		if missingRideID || wrongDriver || missingPassengerID || !value.Active() {
			continue
		}
		projection.upsertLocked(value)
		stored++
	}
	if stored == 0 {
		projection.rememberEmptyLocked(driverID)
	}
}

func (projection *MemoryProjection) rememberEmptyLocked(driverID string) {
	ttl := projection.emptyTTL
	if ttl <= 0 {
		ttl = _defaultEmptyDriverCacheTTL
	}
	now := projection.currentTime()
	maxEntries := projection.maxEmptyDrivers
	if maxEntries <= 0 {
		maxEntries = _defaultMaxEmptyDrivers
	}
	if len(projection.emptyDrivers) >= maxEntries {
		for id, expiresAt := range projection.emptyDrivers {
			if !now.Before(expiresAt) {
				delete(projection.emptyDrivers, id)
			}
		}
		if len(projection.emptyDrivers) >= maxEntries {
			var oldestID string
			var oldestExpiry time.Time
			found := false
			for id, expiresAt := range projection.emptyDrivers {
				if !found || expiresAt.Before(oldestExpiry) {
					oldestID = id
					oldestExpiry = expiresAt
					found = true
				}
			}
			if found {
				delete(projection.emptyDrivers, oldestID)
			}
		}
	}
	projection.emptyDrivers[driverID] = now.Add(ttl)
}

func (projection *MemoryProjection) currentTime() time.Time {
	if projection != nil && projection.now != nil {
		return projection.now()
	}
	return time.Now()
}

func (projection *MemoryProjection) upsert(scope event.Scope, status string) {
	missingRideID := scope.RideID == ""
	missingDriverID := scope.DriverID == ""
	missingPassengerID := scope.PassengerID == ""
	if missingRideID || missingDriverID || missingPassengerID {
		return
	}
	value := Assignment{
		RideID:      scope.RideID,
		DriverID:    scope.DriverID,
		PassengerID: scope.PassengerID,
		Status:      status,
	}
	if !value.Active() {
		return
	}

	projection.mu.Lock()
	defer projection.mu.Unlock()
	projection.upsertLocked(value)
}

func (projection *MemoryProjection) upsertLocked(value Assignment) {
	if previous, found := projection.byRide[value.RideID]; found && previous.DriverID != value.DriverID {
		projection.removeDriverAssignment(previous.DriverID, value.RideID)
	}
	delete(projection.emptyDrivers, value.DriverID)
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
