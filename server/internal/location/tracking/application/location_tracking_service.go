package application

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"time"

	assignmentdomain "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/domain"
	assignmentports "github.com/Easy-Bao/DrivingApp/server/internal/dispatch/assignment/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/domain"
	trackingports "github.com/Easy-Bao/DrivingApp/server/internal/location/tracking/ports"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
)

type LocationTrackingService struct {
	repository     trackingports.LocationStore
	assignments    assignmentports.Lookup
	eventPublisher EventPublisher
	logger         *slog.Logger
}

type Option func(*LocationTrackingService)

func WithRideAssignments(assignments assignmentports.Lookup) Option {
	return func(service *LocationTrackingService) { service.assignments = assignments }
}

func WithEventPublisher(publisher EventPublisher) Option {
	return func(service *LocationTrackingService) { service.eventPublisher = publisher }
}

func WithLogger(logger *slog.Logger) Option {
	return func(service *LocationTrackingService) {
		if logger != nil {
			service.logger = logger
		}
	}
}

func NewLocationTrackingService(repository trackingports.LocationStore, options ...Option) *LocationTrackingService {
	service := &LocationTrackingService{repository: repository, logger: slog.Default()}
	for _, option := range options {
		option(service)
	}
	return service
}

func (service *LocationTrackingService) Ingest(ctx context.Context, point domain.DriverPoint) error {
	if err := contextError(ctx); err != nil {
		return err
	}
	invalidCoordinates := !validCoordinates(point.Latitude, point.Longitude)
	invalidMotion := !validMotion(point.Heading, point.Speed)
	missingDriverID := point.DriverID == ""
	if invalidCoordinates || invalidMotion || missingDriverID {
		return domain.ErrInvalidLocation
	}
	if err := service.repository.Upsert(ctx, point); err != nil {
		return fmt.Errorf("persist driver location: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return err
	}
	assignments, err := service.activeRidesForDriver(ctx, point.DriverID)
	if err != nil {
		service.logger.WarnContext(ctx, "load realtime ride assignments failed", "error", err)
	}
	if err := contextError(ctx); err != nil {
		return err
	}
	if len(assignments) == 0 {
		service.publish(
			ctx,
			event.DriverLocationUpdated,
			event.Scope{DriverID: point.DriverID},
			map[string]any{"location": point},
		)
		return contextError(ctx)
	}
	for _, rideAssignment := range assignments {
		if err := contextError(ctx); err != nil {
			return err
		}
		service.publish(
			ctx,
			event.DriverLocationUpdated,
			event.Scope{
				RideID:      rideAssignment.RideID,
				DriverID:    rideAssignment.DriverID,
				PassengerID: rideAssignment.PassengerID,
			},
			map[string]any{"location": point},
		)
	}
	return contextError(ctx)
}
func (service *LocationTrackingService) Nearby(
	ctx context.Context,
	latitude float64,
	longitude float64,
	radiusKm float64,
) ([]domain.DriverPoint, error) {
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	invalidCoordinates := !validCoordinates(latitude, longitude)
	invalidRadius := math.IsNaN(radiusKm) || math.IsInf(radiusKm, 0) || radiusKm <= 0 || radiusKm > 50
	if invalidCoordinates || invalidRadius {
		return nil, domain.ErrInvalidLocation
	}
	points, err := service.repository.Nearby(ctx, latitude, longitude, radiusKm)
	if err != nil {
		return nil, err
	}
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	return points, nil
}

func (service *LocationTrackingService) Remove(ctx context.Context, driverID string) error {
	if err := contextError(ctx); err != nil {
		return err
	}
	repository := service.repository
	if repository == nil {
		return errors.New("driver location removal is unavailable")
	}
	if driverID == "" {
		return errors.New("driver id is required")
	}
	if err := repository.Remove(ctx, driverID); err != nil {
		return err
	}
	return contextError(ctx)
}

func (service *LocationTrackingService) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	repository := service.repository
	if repository == nil {
		return domain.DriverPoint{}, errors.New("location lookup is unavailable")
	}
	point, err := repository.Get(ctx, driverID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	return point, nil
}

func (service *LocationTrackingService) UpdatePassenger(
	ctx context.Context,
	rideID string,
	passengerID string,
	point domain.DriverPoint,
) error {
	if err := contextError(ctx); err != nil {
		return err
	}
	repository := service.repository
	if repository == nil {
		return errors.New("passenger location persistence is unavailable")
	}
	missingRideID := rideID == ""
	missingPassengerID := passengerID == ""
	invalidCoordinates := !validCoordinates(point.Latitude, point.Longitude)
	if missingRideID || missingPassengerID || invalidCoordinates {
		return domain.ErrInvalidLocation
	}
	assignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return err
	}
	if assignment.PassengerID != passengerID {
		return domain.ErrRideAccessDenied
	}
	if err := repository.UpsertPassenger(ctx, rideID, point); err != nil {
		return fmt.Errorf("persist passenger location: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return err
	}
	service.publish(
		ctx,
		event.PassengerLocationUpdated,
		event.Scope{
			RideID:      rideID,
			DriverID:    assignment.DriverID,
			PassengerID: assignment.PassengerID,
		},
		map[string]any{"location": point},
	)
	return contextError(ctx)
}

func (service *LocationTrackingService) GetPassengerForDriver(
	ctx context.Context,
	rideID string,
	driverID string,
) (domain.DriverPoint, error) {
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	repository := service.repository
	if repository == nil {
		return domain.DriverPoint{}, errors.New("passenger location lookup is unavailable")
	}
	assignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if assignment.DriverID != driverID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	point, err := repository.GetPassenger(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	return point, nil
}

func (service *LocationTrackingService) GetDriverForRide(
	ctx context.Context,
	rideID string,
	passengerID string,
) (domain.DriverPoint, error) {
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	repository := service.repository
	if repository == nil {
		return domain.DriverPoint{}, errors.New("driver location lookup is unavailable")
	}
	rideAssignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if rideAssignment.PassengerID != passengerID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	point, err := repository.Get(ctx, rideAssignment.DriverID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	return point, nil
}

func (service *LocationTrackingService) activeRidesForDriver(
	ctx context.Context,
	driverID string,
) ([]assignmentdomain.Assignment, error) {
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	if service.assignments == nil {
		return []assignmentdomain.Assignment{}, nil
	}
	assignments, err := service.assignments.ForDriver(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("load active ride assignments: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	active := make([]assignmentdomain.Assignment, 0, len(assignments))
	for _, rideAssignment := range assignments {
		if rideAssignment.Active() {
			active = append(active, rideAssignment)
		}
	}
	return active, nil
}

func (service *LocationTrackingService) assignmentForRide(
	ctx context.Context,
	rideID string,
) (assignmentdomain.Assignment, error) {
	if err := contextError(ctx); err != nil {
		return assignmentdomain.Assignment{}, err
	}
	if service.assignments == nil {
		return assignmentdomain.Assignment{}, domain.ErrRideAssignmentUnavailable
	}
	rideAssignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		return assignmentdomain.Assignment{}, fmt.Errorf("load ride assignment: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return assignmentdomain.Assignment{}, err
	}
	if !found || !rideAssignment.Active() {
		return assignmentdomain.Assignment{}, domain.ErrRideAccessDenied
	}
	return rideAssignment, nil
}

func (service *LocationTrackingService) publish(
	ctx context.Context,
	eventType event.Type,
	scope event.Scope,
	payload map[string]any,
) {
	if service.eventPublisher == nil {
		return
	}
	envelope, err := event.New(
		event.NewID(),
		eventType,
		time.Now(),
		scope,
		payload,
	)
	if err != nil {
		service.logger.ErrorContext(ctx, "construct realtime location event failed", "error", err, "event_type", eventType)
		return
	}
	if err := service.eventPublisher.Publish(ctx, envelope); err != nil {
		service.logger.WarnContext(ctx, "publish realtime location event failed", "error", err, "event_type", eventType)
	}
}

func validCoordinates(latitude, longitude float64) bool {
	return !math.IsNaN(latitude) && !math.IsInf(latitude, 0) && latitude >= -90 && latitude <= 90 &&
		!math.IsNaN(longitude) && !math.IsInf(longitude, 0) && longitude >= -180 && longitude <= 180
}

func validMotion(heading, speed float64) bool {
	return !math.IsNaN(heading) && !math.IsInf(heading, 0) && heading >= 0 && heading <= 360 &&
		!math.IsNaN(speed) && !math.IsInf(speed, 0) && speed >= 0 && speed <= 200
}

func contextError(ctx context.Context) error {
	if ctx == nil {
		return nil
	}
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return nil
	}
}
