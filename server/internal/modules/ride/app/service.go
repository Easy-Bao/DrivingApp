package app

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"math"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/modules/ride/domain"
)

var errRidePersistenceUnavailable = errors.New("ride persistence is unavailable")

type Option func(*Service)

func WithRouteCalculator(calculator RouteProvider) Option {
	return func(service *Service) {
		service.routeCalculator = calculator
	}
}

type Service struct {
	repository        RideStore
	counterparties    CounterpartyReader
	history           RideHistoryReader
	recentRides       RecentPassengerRidesReader
	passengerActivity PassengerActivityReader
	driverEarnings    DriverEarningsReader
	driverStats       DriverStatisticsReader
	safetyReports     SafetyReportStore
	routeCalculator   RouteProvider
	pricingConfig     PricingConfig
	eventPublisher    EventPublisher
	bookingService    *BookingService
	lifecycleService  *LifecycleService
	settlementService *SettlementService
	reportingLocation *time.Location
	logger            *slog.Logger
}

type Dependencies struct {
	Repository        RideStore
	ActiveRideChecker PassengerActiveRideChecker
	Lifecycle         RideLifecycleStore
	Settlement        CashSettlementStore
	Counterparties    CounterpartyReader
	History           RideHistoryReader
	RecentRides       RecentPassengerRidesReader
	PassengerActivity PassengerActivityReader
	DriverEarnings    DriverEarningsReader
	DriverStats       DriverStatisticsReader
	SafetyReports     SafetyReportStore
	PricingConfig     PricingConfig
	EventPublisher    EventPublisher
	LifecycleConfig   LifecycleConfig
	DriverLocation    DriverLocationReader
}

func NewService(
	dependencies Dependencies,
	options ...Option,
) *Service {
	pricingConfig := dependencies.PricingConfig
	service := &Service{
		repository:        dependencies.Repository,
		counterparties:    dependencies.Counterparties,
		history:           dependencies.History,
		recentRides:       dependencies.RecentRides,
		passengerActivity: dependencies.PassengerActivity,
		driverEarnings:    dependencies.DriverEarnings,
		driverStats:       dependencies.DriverStats,
		safetyReports:     dependencies.SafetyReports,
		pricingConfig:     pricingConfig,
		eventPublisher:    dependencies.EventPublisher,
		reportingLocation: _defaultReportingLocation,
		logger:            slog.Default(),
	}
	for _, option := range options {
		if option != nil {
			option(service)
		}
	}
	service.bookingService = NewBookingService(BookingDependencies{
		Writer:            dependencies.Repository,
		ActiveRideChecker: dependencies.ActiveRideChecker,
		ResolveRoute:      service.authoritativeRoute,
		CalculateFare:     pricingConfig.FareAmount,
		PublishRide:       service.publishRide,
		HasRouteProvider:  service.routeCalculator != nil,
	})
	service.lifecycleService = NewLifecycleService(LifecycleDependencies{
		Store:          dependencies.Lifecycle,
		DriverLocation: dependencies.DriverLocation,
		PublishRide:    service.publishRide,
		Config:         dependencies.LifecycleConfig,
	})
	service.settlementService = NewSettlementService(SettlementDependencies{
		Store:       dependencies.Settlement,
		PublishRide: service.publishRide,
	})
	return service
}

func (service *Service) WithLogger(logger *slog.Logger) *Service {
	if service != nil && logger != nil {
		service.logger = logger
	}
	return service
}

func (service *Service) log() *slog.Logger {
	if service != nil && service.logger != nil {
		return service.logger
	}
	return slog.Default()
}

func (service *Service) PricingConfig() PricingConfig {
	return service.pricingConfig
}
func (service *Service) CreateRide(ctx context.Context, passengerID int, fareAmount int64) (domain.Ride, error) {
	return service.bookingService.Create(ctx, passengerID, fareAmount)
}
func (service *Service) Get(ctx context.Context, id int) (domain.Ride, error) {
	if service.repository == nil {
		return domain.Ride{}, errRidePersistenceUnavailable
	}
	ride, err := service.repository.Get(ctx, id)
	if err != nil {
		return domain.Ride{}, fmt.Errorf("get ride: %w", err)
	}
	return ride, nil
}

func (service *Service) CreateRideWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
	return service.bookingService.CreateWithDetails(ctx, ride)
}

func (service *Service) Fare(
	ctx context.Context,
	originLatitude *float64,
	originLongitude *float64,
	destinationLatitude *float64,
	destinationLongitude *float64,
	distanceKm float64,
	durationMinutes float64,
) (RouteMetrics, int64, error) {
	return service.bookingService.EstimateFare(
		ctx,
		originLatitude,
		originLongitude,
		destinationLatitude,
		destinationLongitude,
		distanceKm,
		durationMinutes,
	)
}

func (service *Service) authoritativeRoute(
	ctx context.Context,
	pickupLatitude float64,
	pickupLongitude float64,
	dropoffLatitude float64,
	dropoffLongitude float64,
	distanceKm float64,
	durationMinutes float64,
) (RouteMetrics, error) {
	if err := contextError(ctx); err != nil {
		return RouteMetrics{}, err
	}
	if service.routeCalculator == nil {
		if err := validateTrip(
			pickupLatitude,
			pickupLongitude,
			dropoffLatitude,
			dropoffLongitude,
			distanceKm,
			durationMinutes,
		); err != nil {
			return RouteMetrics{}, err
		}
		return RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}, nil
	}
	if pickupLatitude == dropoffLatitude && pickupLongitude == dropoffLongitude {
		return RouteMetrics{}, domain.ErrInvalidTrip
	}
	if err := validateTrip(
		pickupLatitude,
		pickupLongitude,
		dropoffLatitude,
		dropoffLongitude,
		0,
		0,
	); err != nil {
		return RouteMetrics{}, err
	}
	metrics, err := service.routeCalculator.CalculateRoute(
		ctx,
		pickupLatitude,
		pickupLongitude,
		dropoffLatitude,
		dropoffLongitude,
	)
	if err != nil {
		if contextErr := contextError(ctx); contextErr != nil {
			return RouteMetrics{}, contextErr
		}
		service.log().WarnContext(ctx, "authoritative route calculation failed", "error", err)
		return RouteMetrics{}, domain.ErrRouteUnavailable
	}
	if err := contextError(ctx); err != nil {
		return RouteMetrics{}, err
	}
	if err := validateTrip(
		pickupLatitude,
		pickupLongitude,
		dropoffLatitude,
		dropoffLongitude,
		metrics.DistanceKm,
		metrics.DurationMinutes,
	); err != nil {
		return RouteMetrics{}, domain.ErrRouteUnavailable
	}
	return metrics, nil
}

func contextError(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
		return nil
	}
}

func (service *Service) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	return service.lifecycleService.AcceptRide(ctx, rideID, driverID)
}

func (service *Service) SettleCash(ctx context.Context, request domain.CashSettlementRequest) (domain.Ride, error) {
	return service.settlementService.SettleCash(ctx, request)
}

func (service *Service) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	return service.lifecycleService.UpdateStatus(
		ctx,
		rideID,
		actorID,
		next,
	)
}

func (service *Service) CancelRide(
	ctx context.Context,
	request domain.CancellationRequest,
) (domain.Ride, error) {
	return service.lifecycleService.Cancel(ctx, request)
}

func (service *Service) EmergencyStop(
	ctx context.Context,
	request domain.EmergencyStopRequest,
) (domain.Ride, error) {
	return service.lifecycleService.EmergencyStop(ctx, request)
}

func (service *Service) MarkArrived(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	return service.lifecycleService.MarkArrived(
		ctx,
		rideID,
		driverID,
		driverLatitude,
		driverLongitude,
	)
}

func (service *Service) StartTrip(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	return service.lifecycleService.StartTrip(
		ctx,
		rideID,
		driverID,
		driverLatitude,
		driverLongitude,
	)
}

func (service *Service) CompleteTrip(
	ctx context.Context,
	rideID, driverID int,
	driverLatitude, driverLongitude float64,
) (domain.Ride, error) {
	return service.lifecycleService.CompleteTrip(
		ctx,
		rideID,
		driverID,
		driverLatitude,
		driverLongitude,
	)
}

func (service *Service) MarkPassengerNoShow(
	ctx context.Context,
	rideID, driverID int,
) (domain.Ride, error) {
	return service.lifecycleService.MarkPassengerNoShow(ctx, rideID, driverID)
}

func (service *Service) CalculateFare(distanceKm, durationMinutes float64) int64 {
	return service.pricingConfig.FareAmount(distanceKm, durationMinutes)
}

func validateTrip(
	pickupLatitude float64,
	pickupLongitude float64,
	dropoffLatitude float64,
	dropoffLongitude float64,
	distanceKm float64,
	durationMinutes float64,
) error {
	values := []float64{
		pickupLatitude,
		pickupLongitude,
		dropoffLatitude,
		dropoffLongitude,
		distanceKm,
		durationMinutes,
	}
	for _, value := range values {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return domain.ErrInvalidTrip
		}
	}
	invalidPickupLatitude := pickupLatitude < -90 || pickupLatitude > 90
	invalidDropoffLatitude := dropoffLatitude < -90 || dropoffLatitude > 90
	invalidLatitude := invalidPickupLatitude || invalidDropoffLatitude
	invalidPickupLongitude := pickupLongitude < -180 || pickupLongitude > 180
	invalidDropoffLongitude := dropoffLongitude < -180 || dropoffLongitude > 180
	invalidLongitude := invalidPickupLongitude || invalidDropoffLongitude
	invalidMetrics := distanceKm < 0 || durationMinutes < 0
	hasCoordinates := !(pickupLatitude == 0 && pickupLongitude == 0 && dropoffLatitude == 0 && dropoffLongitude == 0)
	sameCoordinates := hasCoordinates && pickupLatitude == dropoffLatitude && pickupLongitude == dropoffLongitude
	if invalidLatitude || invalidLongitude || invalidMetrics || sameCoordinates {
		return domain.ErrInvalidTrip
	}
	return nil
}
