package usecase

import (
	"context"
	"errors"
	"fmt"
	"log"
	"math"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/geo/domain"
)

type Service struct {
	repository     domain.Repository
	assignments    domain.RideAssignmentLookup
	eventPublisher domain.EventPublisher
}

type Option func(*Service)

func WithRideAssignments(assignments domain.RideAssignmentLookup) Option {
	return func(service *Service) { service.assignments = assignments }
}

func WithEventPublisher(publisher domain.EventPublisher) Option {
	return func(service *Service) { service.eventPublisher = publisher }
}

func NewService(repository domain.Repository, options ...Option) *Service {
	service := &Service{repository: repository}
	for _, option := range options {
		option(service)
	}
	return service
}

func (service *Service) Ingest(ctx context.Context, point domain.DriverPoint) error {
	if !validCoordinates(point.Latitude, point.Longitude) || point.DriverID == "" {
		return errors.New("invalid driver location")
	}
	if err := service.repository.Upsert(ctx, point); err != nil {
		return fmt.Errorf("persist driver location: %w", err)
	}
	scope := event.Scope{DriverID: point.DriverID}
	if assignment, found, err := service.activeRideForDriver(ctx, point.DriverID); err != nil {
		log.Printf("realtime ride assignment lookup failed: %v", err)
	} else if found {
		scope = event.Scope{RideID: assignment.RideID, DriverID: assignment.DriverID, PassengerID: assignment.PassengerID}
	}
	service.publish(ctx, event.DriverLocationUpdated, scope, map[string]any{"location": point})
	return nil
}
func (service *Service) Nearby(ctx context.Context, latitude, longitude, radiusKm float64) ([]domain.DriverPoint, error) {
	if !validCoordinates(latitude, longitude) || math.IsNaN(radiusKm) || math.IsInf(radiusKm, 0) || radiusKm <= 0 || radiusKm > 50 {
		return nil, errors.New("invalid nearby location")
	}
	return service.repository.Nearby(ctx, latitude, longitude, radiusKm)
}

func (service *Service) Remove(ctx context.Context, driverID string) error {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return errors.New("driver location removal is unavailable")
	}
	if driverID == "" {
		return errors.New("driver id is required")
	}
	return repository.Remove(ctx, driverID)
}

func (service *Service) Get(ctx context.Context, driverID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("location lookup is unavailable")
	}
	return repository.Get(ctx, driverID)
}

func (service *Service) UpdatePassenger(ctx context.Context, rideID, passengerID string, point domain.DriverPoint) error {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return errors.New("passenger location persistence is unavailable")
	}
	if rideID == "" || passengerID == "" || !validCoordinates(point.Latitude, point.Longitude) {
		return errors.New("invalid passenger location")
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

func (service *Service) GetPassengerForDriver(ctx context.Context, rideID, driverID string) (domain.DriverPoint, error) {
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

func (service *Service) GetDriverForPassenger(ctx context.Context, driverID, passengerID string) (domain.DriverPoint, error) {
	repository, ok := service.repository.(domain.LocationRepository)
	if !ok {
		return domain.DriverPoint{}, errors.New("driver location lookup is unavailable")
	}
	assignment, found, err := service.activeRideForDriver(ctx, driverID)
	if err != nil {
		return domain.DriverPoint{}, err
	}
	if !found || assignment.PassengerID != passengerID {
		return domain.DriverPoint{}, domain.ErrRideAccessDenied
	}
	return repository.Get(ctx, driverID)
}

func (service *Service) activeRideForDriver(ctx context.Context, driverID string) (domain.RideAssignment, bool, error) {
	if service.assignments == nil {
		return domain.RideAssignment{}, false, nil
	}
	assignment, found, err := service.assignments.ForDriver(ctx, driverID)
	if err != nil {
		return domain.RideAssignment{}, false, fmt.Errorf("load active ride assignment: %w", err)
	}
	return assignment, found, nil
}

func (service *Service) assignmentForRide(ctx context.Context, rideID string) (domain.RideAssignment, error) {
	if service.assignments == nil {
		return domain.RideAssignment{}, domain.ErrRideAssignmentUnavailable
	}
	assignment, found, err := service.assignments.ForRide(ctx, rideID)
	if err != nil {
		return domain.RideAssignment{}, fmt.Errorf("load ride assignment: %w", err)
	}
	if !found {
		return domain.RideAssignment{}, domain.ErrRideAccessDenied
	}
	return assignment, nil
}

func (service *Service) publish(ctx context.Context, eventType event.Type, scope event.Scope, payload map[string]any) {
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
