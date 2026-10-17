package app

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

var errUnavailable = errors.New("ride booking persistence is unavailable")

const (
	_fareRouteCacheTTL        = 15 * time.Second
	_fareRouteCacheMaxEntries = 128
)

type fareRouteCacheEntry struct {
	metrics   RouteMetrics
	createdAt time.Time
}

type fareRouteFlight struct {
	done    chan struct{}
	metrics RouteMetrics
	err     error
}

type FareCalculator func(distanceKm, durationMinutes float64) int64

// RideEventPublisher routes a ride event only after persistence succeeds.
type RideEventPublisher func(ctx context.Context, eventType event.Type, ride domain.Ride, payload map[string]any)

type BookingDependencies struct {
	Writer            RideWriter
	ActiveRideChecker PassengerActiveRideChecker
	ResolveRoute      RouteResolver
	CalculateFare     FareCalculator
	PublishRide       RideEventPublisher
	HasRouteProvider  bool
}

type BookingService struct {
	writer            RideWriter
	activeRideChecker PassengerActiveRideChecker
	resolveRoute      RouteResolver
	calculateFare     FareCalculator
	publishRide       RideEventPublisher
	hasRouteProvider  bool
	fareRouteCacheMu  sync.Mutex
	fareRouteCache    map[string]fareRouteCacheEntry
	fareRouteFlights  map[string]*fareRouteFlight
}

func NewBookingService(dependencies BookingDependencies) *BookingService {
	activeRideChecker := dependencies.ActiveRideChecker
	if activeRideChecker == nil {
		if checker, ok := dependencies.Writer.(PassengerActiveRideChecker); ok {
			activeRideChecker = checker
		}
	}
	return &BookingService{
		writer:            dependencies.Writer,
		activeRideChecker: activeRideChecker,
		resolveRoute:      dependencies.ResolveRoute,
		calculateFare:     dependencies.CalculateFare,
		publishRide:       dependencies.PublishRide,
		hasRouteProvider:  dependencies.HasRouteProvider,
		fareRouteCache:    make(map[string]fareRouteCacheEntry),
		fareRouteFlights:  make(map[string]*fareRouteFlight),
	}
}

func (service *BookingService) Create(ctx context.Context, passengerID int, fareAmount int64) (domain.Ride, error) {
	if passengerID <= 0 || fareAmount <= 0 {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	if service.writer == nil {
		return domain.Ride{}, errUnavailable
	}
	if service.activeRideChecker != nil {
		hasActive, err := service.activeRideChecker.HasActivePassengerRide(ctx, passengerID)
		if err != nil {
			return domain.Ride{}, fmt.Errorf("check active passenger ride: %w", err)
		}
		if hasActive {
			return domain.Ride{}, domain.ErrActiveBooking
		}
	}
	ride, err := service.writer.CreateRide(ctx, domain.Ride{
		PassengerID: passengerID,
		Status:      string(domain.RideRequested),
		FareAmount:  fareAmount,
		RideType:    "Solo Ride",
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
func (service *BookingService) CreateWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
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
	if service.activeRideChecker != nil {
		hasActive, err := service.activeRideChecker.HasActivePassengerRide(ctx, ride.PassengerID)
		if err != nil {
			return domain.Ride{}, fmt.Errorf("check active passenger ride: %w", err)
		}
		if hasActive {
			return domain.Ride{}, domain.ErrActiveBooking
		}
	}
	metrics, err := service.resolveRouteMetrics(
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
	ride.FareAmount = service.calculateFare(metrics.DistanceKm, metrics.DurationMinutes)
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
func (service *BookingService) EstimateFare(
	ctx context.Context,
	originLatitude, originLongitude, destinationLatitude, destinationLongitude *float64,
	distanceKm, durationMinutes float64,
) (RouteMetrics, int64, error) {
	if service.calculateFare == nil {
		return RouteMetrics{}, 0, errUnavailable
	}
	if service.hasRouteProvider {
		missingOrigin := originLatitude == nil || originLongitude == nil
		missingDestination := destinationLatitude == nil || destinationLongitude == nil
		if missingOrigin || missingDestination {
			return RouteMetrics{}, 0, domain.ErrInvalidTrip
		}
		if *originLatitude == *destinationLatitude && *originLongitude == *destinationLongitude {
			return RouteMetrics{}, 0, domain.ErrInvalidTrip
		}
		if service.resolveRoute == nil {
			return RouteMetrics{}, 0, errUnavailable
		}
		metrics, err := service.resolveRouteMetrics(
			ctx,
			*originLatitude,
			*originLongitude,
			*destinationLatitude,
			*destinationLongitude,
			distanceKm,
			durationMinutes,
		)
		if err != nil {
			return RouteMetrics{}, 0, fmt.Errorf("resolve authoritative fare route: %w", err)
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
		return RouteMetrics{}, 0, err
	}
	metrics := RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}
	return metrics, service.calculateFare(distanceKm, durationMinutes), nil
}

func (service *BookingService) resolveRouteMetrics(
	ctx context.Context,
	originLatitude, originLongitude, destinationLatitude, destinationLongitude float64,
	distanceKm, durationMinutes float64,
) (RouteMetrics, error) {
	if !service.hasRouteProvider {
		return service.resolveRoute(
			ctx,
			originLatitude,
			originLongitude,
			destinationLatitude,
			destinationLongitude,
			distanceKm,
			durationMinutes,
		)
	}
	key := fareRouteCacheKey(
		originLatitude,
		originLongitude,
		destinationLatitude,
		destinationLongitude,
	)
	service.fareRouteCacheMu.Lock()
	if entry, ok := service.fareRouteCache[key]; ok {
		if time.Since(entry.createdAt) < _fareRouteCacheTTL {
			service.fareRouteCacheMu.Unlock()
			return entry.metrics, nil
		}
		delete(service.fareRouteCache, key)
	}
	if flight, ok := service.fareRouteFlights[key]; ok {
		service.fareRouteCacheMu.Unlock()
		select {
		case <-flight.done:
			return flight.metrics, flight.err
		case <-ctx.Done():
			return RouteMetrics{}, ctx.Err()
		}
	}
	flight := &fareRouteFlight{done: make(chan struct{})}
	service.fareRouteFlights[key] = flight
	service.fareRouteCacheMu.Unlock()

	metrics, err := service.resolveRoute(
		ctx,
		originLatitude,
		originLongitude,
		destinationLatitude,
		destinationLongitude,
		distanceKm,
		durationMinutes,
	)

	service.fareRouteCacheMu.Lock()
	delete(service.fareRouteFlights, key)
	flight.metrics = metrics
	flight.err = err
	if err == nil {
		service.storeFareRouteLocked(key, metrics)
	}
	close(flight.done)
	service.fareRouteCacheMu.Unlock()
	return metrics, err
}

func (service *BookingService) storeFareRouteLocked(key string, metrics RouteMetrics) {
	if len(service.fareRouteCache) >= _fareRouteCacheMaxEntries {
		oldestKey := ""
		var oldest time.Time
		for candidateKey, candidate := range service.fareRouteCache {
			if oldestKey == "" || candidate.createdAt.Before(oldest) {
				oldestKey = candidateKey
				oldest = candidate.createdAt
			}
		}
		delete(service.fareRouteCache, oldestKey)
	}
	service.fareRouteCache[key] = fareRouteCacheEntry{
		metrics:   metrics,
		createdAt: time.Now(),
	}
}

func fareRouteCacheKey(
	originLatitude, originLongitude, destinationLatitude, destinationLongitude float64,
) string {
	return fmt.Sprintf(
		"fare-route:%.6f:%.6f:%.6f:%.6f",
		originLatitude,
		originLongitude,
		destinationLatitude,
		destinationLongitude,
	)
}

func (service *BookingService) publish(
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
