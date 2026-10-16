package app

import (
	"context"
	"errors"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/location/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

var ErrCacheMiss = errors.New("location cache miss")

// Cache stores bounded provider responses without coupling location use cases
// to a cache implementation.
type Cache interface {
	GetPlaces(ctx context.Context, key string) ([]domain.Place, error)
	SetPlaces(ctx context.Context, key string, places []domain.Place) error
	GetPlace(ctx context.Context, key string) (*domain.Place, error)
	SetPlace(ctx context.Context, key string, place *domain.Place) error
	GetMatrix(ctx context.Context, key string) (*domain.Matrix, error)
	SetMatrix(ctx context.Context, key string, matrix *domain.Matrix) error
}

// Provider isolates search, route, and geocoding use cases from the mapping
// vendor.
type Provider interface {
	Search(ctx context.Context, query string, origin domain.Coordinates) ([]domain.Place, error)
	Nearby(ctx context.Context, origin domain.Coordinates, page int) ([]domain.Place, error)
	ReverseGeocode(ctx context.Context, coordinates domain.Coordinates) (*domain.Place, error)
	Route(ctx context.Context, origin, destination domain.Coordinates, options domain.RouteOptions) (*domain.Route, error)
	Matrix(ctx context.Context, origin domain.Coordinates, destinations []domain.Coordinates) (*domain.Matrix, error)
}

// LocationStore is the tracking module's persistence boundary for telemetry
// and active-ride location.
type LocationStore interface {
	Upsert(ctx context.Context, point domain.DriverPoint) error
	Nearby(ctx context.Context, latitude, longitude float64, radiusKm float64) ([]domain.DriverPoint, error)
	Remove(ctx context.Context, driverID string) error
	Get(ctx context.Context, driverID string) (domain.DriverPoint, error)
	UpsertPassenger(ctx context.Context, rideID string, point domain.DriverPoint) error
	GetPassenger(ctx context.Context, rideID string) (domain.DriverPoint, error)
}

// DriverPresenceReader is the server-owned availability check used before
// accepting driver telemetry. The mobile client's online flag is not an
// authority for publishing location.
type DriverPresenceReader interface {
	IsOnline(ctx context.Context, driverID string) (bool, error)
}

type DriverPresenceReaderFunc func(context.Context, string) (bool, error)

func (reader DriverPresenceReaderFunc) IsOnline(
	ctx context.Context,
	driverID string,
) (bool, error) {
	return reader(ctx, driverID)
}

// EventPublisher delivers location notifications to the process-local event
// transport. Active ride REST endpoints remain authoritative for recovery.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
