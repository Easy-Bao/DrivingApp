package app

import (
	"context"
	"fmt"
	"github.com/Easy-Bao/DrivingApp/server/internal/modules/tracking/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	"github.com/Easy-Bao/DrivingApp/server/internal/platform/geo"
	"time"
)

func (service *TrackingService) UpdatePassenger(
	ctx context.Context,
	rideID string,
	passengerID string,
	point domain.DriverPoint,
) error {
	if err := contextError(ctx); err != nil {
		return err
	}
	if service == nil || service.repository == nil {
		return ErrPersistenceUnavailable
	}
	repository := service.repository
	missingRideID := rideID == ""
	missingPassengerID := passengerID == ""
	invalidCoordinates := !geo.ValidCoordinates(point.Latitude, point.Longitude)
	if missingRideID || missingPassengerID || invalidCoordinates {
		return domain.ErrInvalidLocation
	}
	if point.ObservedAt.IsZero() {
		point.ObservedAt = time.Now().UTC()
	} else {
		point.ObservedAt = point.ObservedAt.UTC()
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

func (service *TrackingService) GetPassengerForDriver(
	ctx context.Context,
	rideID string,
	driverID string,
) (domain.DriverPoint, error) {
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	if service == nil || service.repository == nil {
		return domain.DriverPoint{}, ErrPersistenceUnavailable
	}
	repository := service.repository
	assignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if assignment.DriverID != driverID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	point, err := repository.GetPassenger(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, fmt.Errorf("load passenger location: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	return point, nil
}

func (service *TrackingService) GetDriverForRide(
	ctx context.Context,
	rideID string,
	passengerID string,
) (domain.DriverPoint, error) {
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	if service == nil || service.repository == nil {
		return domain.DriverPoint{}, ErrPersistenceUnavailable
	}
	repository := service.repository
	rideAssignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if rideAssignment.PassengerID != passengerID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	point, err := repository.Get(ctx, rideAssignment.DriverID)
	if err != nil {
		return domain.DriverPoint{}, fmt.Errorf("load driver location: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return domain.DriverPoint{}, err
	}
	return point, nil
}

func (service *TrackingService) activeRidesForDriver(
	ctx context.Context,
	driverID string,
) ([]RideAssignment, error) {
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	if service.assignments == nil {
		return []RideAssignment{}, nil
	}
	assignments, err := service.assignments.ForDriver(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("load active ride assignments: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return nil, err
	}
	active := make([]RideAssignment, 0, len(assignments))
	for _, rideAssignment := range assignments {
		if rideAssignment.Active() {
			active = append(active, rideAssignment)
		}
	}
	return active, nil
}

func (service *TrackingService) assignmentForRide(
	ctx context.Context,
	rideID string,
) (RideAssignment, error) {
	if err := contextError(ctx); err != nil {
		return RideAssignment{}, err
	}
	if service.assignments == nil {
		return RideAssignment{}, domain.ErrRideAssignmentUnavailable
	}
	rideAssignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		return RideAssignment{}, fmt.Errorf("load ride assignment: %w", err)
	}
	if err := contextError(ctx); err != nil {
		return RideAssignment{}, err
	}
	if !found || !rideAssignment.Active() {
		return RideAssignment{}, domain.ErrRideAccessDenied
	}
	return rideAssignment, nil
}

func (service *TrackingService) publish(
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
		time.Now().UTC(),
		scope,
		payload,
	)
	if err != nil {
		service.log().ErrorContext(ctx, "construct realtime location event failed", "error", err, "event_type", eventType)
		return
	}
	if err := service.eventPublisher.Publish(ctx, envelope); err != nil {
		service.log().WarnContext(ctx, "publish realtime location event failed", "error", err, "event_type", eventType)
	}
}
