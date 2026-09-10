// Package booking owns the ride-creation use cases.
package booking

import (
	"context"
	"errors"
	"math"

	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

var errUnavailable = errors.New("ride booking persistence is unavailable")

// RouteResolver is the application policy used to obtain authoritative route
// metrics. Keeping it as a function lets booking remain independent of the
// mapping adapter and of the ride facade kept for compatibility.
type RouteResolver = ports.RouteResolver

// FareCalculator calculates the server-authoritative fare.
type FareCalculator func(distanceKm, durationMinutes float64) int64

// RideEventPublisher publishes a ride event after persistence succeeds.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

// Dependencies contains the seams used by booking use cases.
type Dependencies struct {
	Writer           ports.RideWriter
	ResolveRoute     RouteResolver
	CalculateFare    FareCalculator
	PublishRide      RideEventPublisher
	HasRouteProvider bool
}

// Service implements booking use cases behind focused outbound ports.
type Service struct {
	writer           ports.RideWriter
	resolveRoute     RouteResolver
	calculateFare    FareCalculator
	publishRide      RideEventPublisher
	hasRouteProvider bool
}

func NewService(dependencies Dependencies) *Service {
	return &Service{
		writer:           dependencies.Writer,
		resolveRoute:     dependencies.ResolveRoute,
		calculateFare:    dependencies.CalculateFare,
		publishRide:      dependencies.PublishRide,
		hasRouteProvider: dependencies.HasRouteProvider,
	}
}

// Create records a simple passenger ride request.
func (service *Service) Create(ctx context.Context, passengerID int, fareCentavos int64) (domain.Ride, error) {
	if passengerID <= 0 || fareCentavos <= 0 {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	if service.writer == nil {
		return domain.Ride{}, errUnavailable
	}
	ride, err := service.writer.CreateRide(ctx, domain.Ride{
		PassengerID:  passengerID,
		Status:       string(domain.RideRequested),
		FareCentavos: fareCentavos,
		RideType:     "Solo Ride",
	})
	if err != nil {
		return domain.Ride{}, err
	}
	service.publish(event.RideOfferCreated, ctx, ride, map[string]any{"ride": ride})
	return ride, nil
}

// CreateWithDetails calculates authoritative route metrics and persists a
// fully described passenger ride request.
func (service *Service) CreateWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
	if ride.PassengerID <= 0 {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	if ride.Status != "" {
		status, ok := domain.NormalizeRideStatus(ride.Status)
		if !ok || status != domain.RideRequested {
			return domain.Ride{}, domain.ErrInvalidTrip
		}
	}
	if service.resolveRoute == nil || service.calculateFare == nil || service.writer == nil {
		return domain.Ride{}, errUnavailable
	}
	metrics, err := service.resolveRoute(
		ctx,
		ride.PickupLatitude,
		ride.PickupLongitude,
		ride.DropoffLatitude,
		ride.DropoffLongitude,
		ride.DistanceKm,
		ride.DurationMinutes,
	)
	if err != nil {
		return domain.Ride{}, err
	}
	ride.DistanceKm = metrics.DistanceKm
	ride.DurationMinutes = metrics.DurationMinutes
	ride.FareCentavos = service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes)
	ride.Status = string(domain.RideRequested)
	if ride.RideType == "" {
		ride.RideType = "solo"
	}
	created, err := service.writer.CreateRide(ctx, ride)
	if err != nil {
		return domain.Ride{}, err
	}
	service.publish(event.RideOfferCreated, ctx, created, map[string]any{"ride": created})
	return created, nil
}

// EstimateFare returns the route metrics and server-calculated fare.
func (service *Service) EstimateFare(
	ctx context.Context,
	originLatitude, originLongitude, destinationLatitude, destinationLongitude *float64,
	distanceKm, durationMinutes float64,
) (ports.RouteMetrics, int64, error) {
	if service.calculateFare == nil {
		return ports.RouteMetrics{}, 0, errUnavailable
	}
	if service.hasRouteProvider {
		if originLatitude == nil || originLongitude == nil || destinationLatitude == nil || destinationLongitude == nil {
			return ports.RouteMetrics{}, 0, domain.ErrInvalidTrip
		}
		if service.resolveRoute == nil {
			return ports.RouteMetrics{}, 0, errUnavailable
		}
		metrics, err := service.resolveRoute(
			ctx,
			*originLatitude,
			*originLongitude,
			*destinationLatitude,
			*destinationLongitude,
			distanceKm,
			durationMinutes,
		)
		if err != nil {
			return ports.RouteMetrics{}, 0, err
		}
		return metrics, service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes), nil
	}
	if err := validateTrip(0, 0, 0, 0, distanceKm, durationMinutes); err != nil {
		return ports.RouteMetrics{}, 0, err
	}
	metrics := ports.RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}
	return metrics, service.calculateFare(distanceKm, durationMinutes), nil
}

func (service *Service) publish(
	eventType event.Type,
	ctx context.Context,
	ride domain.Ride,
	payload map[string]any,
) {
	if service.publishRide != nil {
		service.publishRide(ctx, eventType, ride, payload)
	}
}

func validateTrip(
	pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes float64,
) error {
	values := []float64{pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes}
	for _, value := range values {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return domain.ErrInvalidTrip
		}
	}
	if pickupLatitude < -90 || pickupLatitude > 90 ||
		dropoffLatitude < -90 || dropoffLatitude > 90 ||
		pickupLongitude < -180 || pickupLongitude > 180 ||
		dropoffLongitude < -180 || dropoffLongitude > 180 ||
		distanceKm < 0 || durationMinutes < 0 {
		return domain.ErrInvalidTrip
	}
	return nil
}
