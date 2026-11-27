package app

import (
	"context"
	"errors"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"sync"
	"time"
)

var ErrPersistenceUnavailable = errors.New("ride lifecycle persistence is unavailable")

type LifecycleDependencies struct {
	Store          RideLifecycleStore
	DriverLocation DriverLocationReader
	PublishRide    RideEventPublisher
	Config         LifecycleConfig
}

type LifecycleService struct {
	store          RideLifecycleStore
	driverLocation DriverLocationReader
	publishRide    RideEventPublisher
	config         LifecycleConfig
}

func NewLifecycleService(dependencies LifecycleDependencies) *LifecycleService {
	return &LifecycleService{
		store:          dependencies.Store,
		driverLocation: dependencies.DriverLocation,
		publishRide:    dependencies.PublishRide,
		config:         dependencies.Config,
	}
}

func (service *LifecycleService) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for acceptance: %w", err)
	}
	currentStatus, currentStatusOK := domain.NormalizeRideStatus(current.Status)
	if current.DriverID != nil &&
		*current.DriverID == driverID &&
		currentStatusOK &&
		domain.IsActive(current.Status) &&
		currentStatus != domain.RideRequested {
		return current, nil
	}
	ride, err := service.store.AcceptRide(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("accept ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideMatched,
		ride,
		map[string]any{"ride": ride},
	)
	return ride, nil
}

// UpdateStatus validates the current aggregate state and persists the next
// participant-authorized status.
func (service *LifecycleService) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	return service.transition(ctx, rideID, actorID, next, domain.RideTransition{
		EventType: domain.RideEventStatusChanged,
	})
}

func (service *LifecycleService) StartTrip(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, location, cleanup, err := service.loadRideWithDriverLocation(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for trip start: %w", err)
	}
	defer cleanup()
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	status, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status == domain.RideInTransit {
		return current, nil
	}
	if status != domain.RideArrived {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	driverLat, driverLng, err := location()
	if err != nil {
		return domain.Ride{}, err
	}
	if err := domain.ValidateArrivalLocation(
		current.PickupLatitude,
		current.PickupLongitude,
		driverLat,
		driverLng,
		service.config.arrivalRadiusMeters(),
	); err != nil {
		return domain.Ride{}, err
	}
	if current.ArrivedAt != nil {
		arrivedAt, parseErr := time.Parse(time.RFC3339, *current.ArrivedAt)
		if parseErr != nil {
			arrivedAt, parseErr = time.Parse(time.RFC3339Nano, *current.ArrivedAt)
		}
		if parseErr == nil && time.Since(arrivedAt) < 3*time.Second {
			return domain.Ride{}, domain.ErrInvalidStatusTransition
		}
	}
	updated, err := service.store.StartTrip(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("start ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(domain.RideArrived),
			"ride":            updated,
		},
	)
	return updated, nil
}

func (service *LifecycleService) CompleteTrip(
	ctx context.Context,
	rideID, driverID int,
	_, _ float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for trip completion: %w", err)
	}
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	status, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status == domain.RideCompleted {
		return current, nil
	}
	if status != domain.RideInTransit {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	updated, err := service.store.CompleteTrip(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("complete ride: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(domain.RideInTransit),
			"ride":            updated,
		},
	)
	return updated, nil
}

func (service *LifecycleService) MarkArrived(
	ctx context.Context,
	rideID, driverID int,
	_, _ float64,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, location, cleanup, err := service.loadRideWithDriverLocation(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for arrival: %w", err)
	}
	defer cleanup()
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	normalizedStatus, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if normalizedStatus == domain.RideArrived {
		return current, nil
	}
	if normalizedStatus != domain.RideAssigned && normalizedStatus != domain.RideAccepted {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	driverLatitude, driverLongitude, err := location()
	if err != nil {
		return domain.Ride{}, err
	}
	if err := domain.ValidateArrivalLocation(
		current.PickupLatitude,
		current.PickupLongitude,
		driverLatitude,
		driverLongitude,
		service.config.arrivalRadiusMeters(),
	); err != nil {
		return domain.Ride{}, err
	}
	updated, err := service.store.MarkArrived(
		ctx,
		rideID,
		driverID,
		string(normalizedStatus),
		service.config.passengerWaitDuration(),
	)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("mark ride arrived: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(normalizedStatus),
			"ride":            updated,
		},
	)
	return updated, nil
}

type driverLocationResult struct {
	latitude, longitude float64
	err                 error
}

// loadRideWithDriverLocation reads the ride and the authoritative driver
// location concurrently so location-gated commands pay one round trip of
// latency instead of two. The returned function blocks until the location
// read finishes; callers still evaluate ride ownership and status first so
// error precedence is unchanged. The location read is cancelled and drained
// when the ride cannot be loaded.
func (service *LifecycleService) loadRideWithDriverLocation(
	ctx context.Context,
	rideID, driverID int,
) (domain.Ride, func() (float64, float64, error), func(), error) {
	locationCtx, cancel := context.WithCancel(ctx)
	results := make(chan driverLocationResult, 1)
	go func() {
		defer cancel()
		latitude, longitude, err := service.authoritativeDriverLocation(locationCtx, driverID)
		results <- driverLocationResult{latitude: latitude, longitude: longitude, err: err}
	}()
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		cancel()
		<-results
		return domain.Ride{}, nil, nil, err
	}
	var (
		locationOnce sync.Once
		result       driverLocationResult
	)
	getLocation := func() (float64, float64, error) {
		locationOnce.Do(func() {
			select {
			case result = <-results:
			case <-ctx.Done():
				result = driverLocationResult{err: ctx.Err()}
			}
		})
		return result.latitude, result.longitude, result.err
	}
	cleanup := sync.OnceFunc(func() {
		cancel()
	})
	return current, getLocation, cleanup, nil
}

const _maxDriverLocationClockSkew = 15 * time.Second

func (service *LifecycleService) authoritativeDriverLocation(
	ctx context.Context,
	driverID int,
) (float64, float64, error) {
	if service.driverLocation == nil {
		return 0, 0, domain.ErrDriverLocationUnavailable
	}
	point, err := service.driverLocation.ReadDriverLocation(ctx, driverID)
	if err != nil {
		if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
			return 0, 0, err
		}
		return 0, 0, fmt.Errorf("read authoritative driver location: %w: %v", domain.ErrDriverLocationUnavailable, err)
	}
	if point.ObservedAt.IsZero() {
		return 0, 0, domain.ErrDriverLocationUnavailable
	}
	observedAge := time.Since(point.ObservedAt)
	if observedAge < -_maxDriverLocationClockSkew || observedAge > service.config.driverLocationMaxAge() {
		return 0, 0, domain.ErrDriverLocationStale
	}
	return point.Latitude, point.Longitude, nil
}

func (service *LifecycleService) MarkPassengerNoShow(
	ctx context.Context,
	rideID, driverID int,
) (domain.Ride, error) {
	if service.store == nil {
		return domain.Ride{}, ErrPersistenceUnavailable
	}
	current, err := service.store.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("load ride for passenger no-show: %w", err)
	}
	if current.DriverID == nil || *current.DriverID != driverID {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	status, ok := domain.NormalizeRideStatus(current.Status)
	if !ok {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status == domain.RideCancelled {
		if current.CancelledBy != nil &&
			*current.CancelledBy == driverID &&
			domain.NormalizeCancellationReason(current.CancellationReason) ==
				domain.CancellationReasonPassengerNoShow &&
			current.CancellationResponsibility ==
				string(domain.CancellationResponsibilityPassengerFault) {
			return current, nil
		}
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if status != domain.RideArrived {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if current.WaitingUntil == nil {
		return domain.Ride{}, domain.ErrPassengerNoShowNotReady
	}
	waitingUntil, parseErr := time.Parse(time.RFC3339, *current.WaitingUntil)
	if parseErr != nil {
		waitingUntil, parseErr = time.Parse(time.RFC3339Nano, *current.WaitingUntil)
	}
	if parseErr != nil || time.Now().UTC().Before(waitingUntil.Add(-5*time.Second)) {
		return domain.Ride{}, domain.ErrPassengerNoShowNotReady
	}
	updated, err := service.store.MarkPassengerNoShow(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("mark passenger no-show: %w", err)
	}
	service.publish(
		ctx,
		event.RideStatusChanged,
		updated,
		map[string]any{
			"previous_status": string(domain.RideArrived),
			"reason":          string(domain.CancellationReasonPassengerNoShow),
			"responsibility":  string(domain.CancellationResponsibilityPassengerFault),
			"ride":            updated,
		},
	)
	return updated, nil
}
