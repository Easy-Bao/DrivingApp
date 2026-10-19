package app

import (
	"context"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

// RideReader supplies the aggregate snapshot needed for authorization and
// lifecycle decisions.
type RideReader interface {
	Get(ctx context.Context, id int) (domain.Ride, error)
}

// RideWriter is the command boundary for creating requested rides.
type RideWriter interface {
	CreateRide(ctx context.Context, ride domain.Ride) (domain.Ride, error)
}

// PassengerActiveRideChecker verifies whether a passenger currently has an
// active ride in progress.
type PassengerActiveRideChecker interface {
	HasActivePassengerRide(ctx context.Context, passengerID int) (bool, error)
}

// RideStore is the command-side persistence port used by the ride service.
// The more focused ports above remain available for use cases that need only
// one capability.
type RideStore interface {
	RideReader
	RideWriter
}

// RideLifecycleStore is the atomic boundary for participant-authorized state
// changes.
type RideLifecycleStore interface {
	RideReader
	AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	MarkArrived(
		ctx context.Context,
		rideID, driverID int,
		currentStatus string,
		passengerWaitDuration time.Duration,
	) (domain.Ride, error)
	StartTrip(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	CompleteTrip(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	MarkPassengerNoShow(ctx context.Context, rideID, driverID int) (domain.Ride, error)
	UpdateStatus(
		ctx context.Context,
		rideID, actorID int,
		currentStatus, nextStatus string,
		transition domain.RideTransition,
	) (domain.Ride, error)
}

// CashSettlementStore is the atomic boundary for recording driver cash
// settlement on completed rides.
type CashSettlementStore interface {
	SettleCash(ctx context.Context, request domain.CashSettlementRequest) (domain.Ride, error)
}

// SafetyReportStore persists incidents separately from service-quality ratings.
type SafetyReportStore interface {
	CreateSafetyReport(ctx context.Context, report domain.SafetyReport) (domain.SafetyReport, error)
}

// CounterpartyReader provides the participant projection used for ride
// authorization.
type CounterpartyReader interface {
	Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error)
}

// RideHistoryReader supplies trip-history read models without exposing command
// persistence.
type RideHistoryReader interface {
	DriverTrips(ctx context.Context, driverID int, query domain.TripHistoryQuery) ([]domain.Ride, error)
	PassengerRides(ctx context.Context, passengerID int, query domain.TripHistoryQuery) ([]domain.Ride, error)
}

// RecentPassengerRidesReader keeps the passenger home query bounded to recent
// records.
type RecentPassengerRidesReader interface {
	PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error)
}

// PassengerActivityReader isolates passenger dashboard reads from ride commands.
type PassengerActivityReader interface {
	PassengerActivitySummary(
		ctx context.Context,
		passengerID int,
		weekStart time.Time,
		weekEnd time.Time,
	) (domain.PassengerActivitySummary, error)
}

// DriverEarningsReader isolates reporting reads from ride command persistence.
type DriverEarningsReader interface {
	DriverEarnings(ctx context.Context, driverID int, monthStart, monthEnd time.Time) ([]domain.DriverEarning, error)
}

// DriverStatisticsReader isolates dashboard reads from ride command persistence.
type DriverStatisticsReader interface {
	DriverStats(ctx context.Context, driverID int, dayStart, dayEnd time.Time) (domain.DriverStats, error)
}

// DriverLocation is the server-observed position used for lifecycle
// proximity checks. It deliberately does not expose a client-provided
// command coordinate as an authority.
type DriverLocation struct {
	Latitude   float64
	Longitude  float64
	ObservedAt time.Time
}

// DriverLocationReader supplies the latest server-owned telemetry point for a
// driver. Lifecycle commands must use this port instead of trusting command
// payload coordinates.
type DriverLocationReader interface {
	ReadDriverLocation(ctx context.Context, driverID int) (DriverLocation, error)
}

// DriverLocationReaderFunc adapts a function without coupling the ride
// lifecycle to the concrete telemetry adapter.
type DriverLocationReaderFunc func(context.Context, int) (DriverLocation, error)

var _ DriverLocationReader = DriverLocationReaderFunc(nil)

func (reader DriverLocationReaderFunc) ReadDriverLocation(
	ctx context.Context,
	driverID int,
) (DriverLocation, error) {
	return reader(ctx, driverID)
}

// RouteMetrics carries provider-authoritative values into pricing and booking;
// callers must not replace them with client estimates.
type RouteMetrics struct {
	DistanceKm      float64
	DurationMinutes float64
}

// RouteProvider isolates route calculation from the mapping adapter.
type RouteProvider interface {
	CalculateRoute(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (RouteMetrics, error)
}

// RouteProviderFunc adapts a route function without introducing a concrete
// provider dependency.
type RouteProviderFunc func(context.Context, float64, float64, float64, float64) (RouteMetrics, error)

var _ RouteProvider = RouteProviderFunc(nil)

func (provider RouteProviderFunc) CalculateRoute(
	ctx context.Context,
	originLat float64,
	originLng float64,
	destinationLat float64,
	destinationLng float64,
) (RouteMetrics, error) {
	return provider(
		ctx,
		originLat,
		originLng,
		destinationLat,
		destinationLng,
	)
}

// RouteResolver applies the ride application's validation and fallback policy
// around a route provider.
type RouteResolver func(
	ctx context.Context,
	pickupLatitude float64,
	pickupLongitude float64,
	dropoffLatitude float64,
	dropoffLongitude float64,
	distanceKm float64,
	durationMinutes float64,
) (RouteMetrics, error)

// EventPublisher is the ride module's outbound seam for transient event
// delivery. Persistence remains authoritative when fan-out is unavailable.
type EventPublisher interface {
	Publish(ctx context.Context, realtimeEvent RealtimeEvent) error
}

type RealtimeEvent = event.RealtimeEvent
