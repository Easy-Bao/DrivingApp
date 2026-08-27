package usecase

import (
	"context"
	"errors"
	"fmt"
	"log"
	"math"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/assignment"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type LocationTrackingService struct {
	repository     domain.Repository
	assignments    assignment.Lookup
	eventPublisher domain.EventPublisher
}

type Option func(*LocationTrackingService)

func WithRideAssignments(assignments assignment.Lookup) Option {
	return func(service *LocationTrackingService) { service.assignments = assignments }
}

func WithEventPublisher(publisher domain.EventPublisher) Option {
	return func(service *LocationTrackingService) { service.eventPublisher = publisher }
}

func NewLocationTrackingService(repository domain.Repository, options ...Option) *LocationTrackingService {
	service := &LocationTrackingService{repository: repository}
	for _, option := range options {
		option(service)
	}
	return service
}

func (service *LocationTrackingService) Ingest(ctx context.Context, point domain.DriverPoint) error {
	if !validCoordinates(point.Latitude, point.Longitude) || !validMotion(point.Heading, point.Speed) || point.DriverID == "" {
		return domain.ErrInvalidLocation
	}
	if err := service.repository.Upsert(ctx, point); err != nil {
		return fmt.Errorf("persist driver location: %w", err)
	}
	assignments, err := service.activeRidesForDriver(ctx, point.DriverID)
	if err != nil {
		log.Printf("realtime ride assignment lookup failed: %v", err)
	}
	if len(assignments) == 0 {
		service.publish(ctx, event.DriverLocationUpdated, event.Scope{DriverID: point.DriverID}, map[string]any{"location": point})
		return nil
	}
	for _, rideAssignment := range assignments {
		service.publish(ctx, event.DriverLocationUpdated, event.Scope{
			RideID: rideAssignment.RideID, DriverID: rideAssignment.DriverID, PassengerID: rideAssignment.PassengerID,
		}, map[string]any{"location": point})
	}
	return nil
}
func (service *LocationTrackingService) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	if !validCoordinates(latitude, longitude) || math.IsNaN(radiusKm) || math.IsInf(radiusKm, 0) || radiusKm <= 0 || radiusKm > 50 {
		return nil, domain.ErrInvalidLocation
	}
	return service.repository.Nearby(ctx, latitude, longitude, radiusKm)
}

func (service *LocationTrackingService) Remove(ctx context.Context, driverID string) error {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return errors.New("driver location removal is unavailable")
	}
	if driverID == "" {
		return errors.New("driver id is required")
	}
	return repository.Remove(ctx, driverID)
}

func (service *LocationTrackingService) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("location lookup is unavailable")
	}
	return repository.Get(ctx, driverID)
}

func (service *LocationTrackingService) UpdatePassenger(ctx context.Context, rideID, passengerID string, point domain.DriverPoint) error {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return errors.New("passenger location persistence is unavailable")
	}
	if rideID == "" || passengerID == "" || !validCoordinates(point.Latitude, point.Longitude) {
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
	service.publish(ctx, event.PassengerLocationUpdated, event.Scope{
		RideID: rideID, DriverID: assignment.DriverID, PassengerID: assignment.PassengerID,
	}, map[string]any{"location": point})
	return nil
}

func (service *LocationTrackingService) GetPassengerForDriver(ctx context.Context, rideID, driverID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("passenger location lookup is unavailable")
	}
	assignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if assignment.DriverID != driverID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	return repository.GetPassenger(ctx, rideID)
}

func (service *LocationTrackingService) GetDriverForRide(ctx context.Context, rideID, passengerID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("driver location lookup is unavailable")
	}
	rideAssignment, err := service.assignmentForRide(ctx, rideID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if rideAssignment.PassengerID != passengerID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	return repository.Get(ctx, rideAssignment.DriverID)
}

func (service *LocationTrackingService) activeRidesForDriver(ctx context.Context, driverID string) ([]assignment.Assignment, error) {
	if service.assignments == nil {
		return nil, nil
	}
	assignments, err := service.assignments.ForDriver(ctx, driverID)
	if err != nil {
		return nil, fmt.Errorf("load active ride assignments: %w", err)
	}
	active := make([]assignment.Assignment, 0, len(assignments))
	for _, rideAssignment := range assignments {
		if rideAssignment.Active() {
			active = append(active, rideAssignment)
		}
	}
	return active, nil
}

func (service *LocationTrackingService) assignmentForRide(ctx context.Context, rideID string) (assignment.Assignment, error) {
	if service.assignments == nil {
		return assignment.Assignment{}, domain.ErrRideAssignmentUnavailable
	}
	rideAssignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		return assignment.Assignment{}, fmt.Errorf("load ride assignment: %w", err)
	}
	if !found || !rideAssignment.Active() {
		return assignment.Assignment{}, domain.ErrRideAccessDenied
	}
	return rideAssignment, nil
}

func (service *LocationTrackingService) publish(ctx context.Context, eventType event.Type, scope event.Scope, payload map[string]any) {
	if service.eventPublisher == nil {
		return
	}
	envelope, err := event.New(event.NewID(), eventType, time.Now(), scope, payload)
	if err != nil {
		log.Printf("realtime location event construction failed: %v", err)
		return
	}
	if err := service.eventPublisher.Publish(ctx, envelope); err != nil {
		log.Printf("realtime location event publishing failed: %v", err)
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
