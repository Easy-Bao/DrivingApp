// Package booking owns the ride-creation use cases.
package booking

import (
	"context"
	"errors"
	"fmt"
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

// FareCalculator keeps pricing policy injectable at the application boundary.
type FareCalculator func(distanceKm, durationMinutes float64) int64

// RideEventPublisher routes a ride event only after persistence succeeds.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

// Dependencies collects the policies and ports that keep booking independent
// of concrete adapters.
type Dependencies struct {
	Writer           ports.RideWriter
	ResolveRoute     RouteResolver
	CalculateFare    FareCalculator
	PublishRide      RideEventPublisher
	HasRouteProvider bool
}

// Service keeps ride creation behind focused outbound ports.
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

// Create is the minimal ride-creation path for callers without route details.
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
		return domain.Ride{}, fmt.Errorf("create ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideOfferCreated,
		ride,
		map[string]any{"ride": ride},
	)
	return ride, nil
}

// CreateWithDetails replaces client-supplied route metrics with authoritative
// values before persisting a fully described ride request.
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
	missingRouteResolver := service.resolveRoute == nil
	missingFareCalculator := service.calculateFare == nil
	missingWriter := service.writer == nil
	if missingRouteResolver || missingFareCalculator || missingWriter {
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
		return domain.Ride{}, fmt.Errorf("resolve authoritative route: %w", err)
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
		return domain.Ride{}, fmt.Errorf("create ride with details: %w", err)
	}
	service.publish(
		ctx,
		event.RideOfferCreated,
		created,
		map[string]any{"ride": created},
	)
	return created, nil
}

// EstimateFare uses provider metrics when coordinates are available and
// validates supplied metrics when the provider is not configured.
func (service *Service) EstimateFare(
	ctx context.Context,
	originLatitude, originLongitude, destinationLatitude, destinationLongitude *float64,
	distanceKm, durationMinutes float64,
) (ports.RouteMetrics, int64, error) {
	if service.calculateFare == nil {
		return ports.RouteMetrics{}, 0, errUnavailable
	}
	if service.hasRouteProvider {
		missingOrigin := originLatitude == nil || originLongitude == nil
		missingDestination := destinationLatitude == nil || destinationLongitude == nil
		if missingOrigin || missingDestination {
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
			return ports.RouteMetrics{}, 0, fmt.Errorf("resolve authoritative fare route: %w", err)
		}
		return metrics, service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes), nil
	}
	if err := validateTrip(
		0,
		0,
		0,
		0,
		distanceKm,
		durationMinutes,
	); err != nil {
		return ports.RouteMetrics{}, 0, err
	}
	metrics := ports.RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}
	return metrics, service.calculateFare(distanceKm, durationMinutes), nil
}

func (service *Service) publish(
	ctx context.Context,
	eventType event.Type,
	ride domain.Ride,
	payload map[string]any,
) {
	if service.publishRide != nil {
		service.publishRide(
			ctx,
			eventType,
			ride,
			payload,
		)
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
	invalidPickupLatitude := pickupLatitude < -90 || pickupLatitude > 90
	invalidDropoffLatitude := dropoffLatitude < -90 || dropoffLatitude > 90
	invalidPickupLongitude := pickupLongitude < -180 || pickupLongitude > 180
	invalidDropoffLongitude := dropoffLongitude < -180 || dropoffLongitude > 180
	invalidDistance := distanceKm < 0
	invalidDuration := durationMinutes < 0
	if invalidPickupLatitude || invalidDropoffLatitude ||
		invalidPickupLongitude || invalidDropoffLongitude ||
		invalidDistance || invalidDuration {
		return domain.ErrInvalidTrip
	}
	return nil
}
