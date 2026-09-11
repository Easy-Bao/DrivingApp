package application

import (
	"context"
	"errors"
	"log/slog"
	"math"
	"time"

	biddingapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application/bidding"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/application/booking"
	lifecycleapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application/lifecycle"
	settlementapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application/settlement"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

type RouteMetrics = ports.RouteMetrics
type RouteCalculator = ports.RouteProvider
type RouteCalculatorFunc = ports.RouteProviderFunc

type RideService struct {
	repository        ports.RideStore
	routeCalculator   RouteCalculator
	pricingConfig     PricingConfig
	eventPublisher    EventPublisher
	bookingService    *booking.Service
	biddingService    *biddingapplication.Service
	lifecycleService  *lifecycleapplication.Service
	settlementService *settlementapplication.Service
	reportingLocation *time.Location
	logger            *slog.Logger
}

func NewRideService(
	repository ports.RideStore,
	pricingConfig PricingConfig,
	publisher EventPublisher,
) *RideService {
	service := &RideService{
		repository:        repository,
		pricingConfig:     pricingConfig,
		eventPublisher:    publisher,
		reportingLocation: defaultReportingLocation,
		logger:            slog.Default(),
	}
	service.bookingService = booking.NewService(booking.Dependencies{
		Writer:           repository,
		ResolveRoute:     service.authoritativeRoute,
		CalculateFare:    pricingConfig.FareCentavos,
		PublishRide:      service.publishRide,
		HasRouteProvider: false,
	})
	service.biddingService = newBiddingService(service)
	lifecycleStore, _ := repository.(ports.RideLifecycleStore)
	service.lifecycleService = lifecycleapplication.NewService(lifecycleapplication.Dependencies{
		Store:       lifecycleStore,
		PublishRide: service.publishRide,
	})
	settlementStore, _ := repository.(ports.CashSettlementStore)
	service.settlementService = settlementapplication.NewService(settlementapplication.Dependencies{
		Store:       settlementStore,
		PublishRide: service.publishRide,
	})
	return service
}

func NewRideServiceWithRouteCalculator(
	repository ports.RideStore,
	calculator RouteCalculator,
	pricingConfig PricingConfig,
	publisher EventPublisher,
) *RideService {
	service := &RideService{
		repository:        repository,
		routeCalculator:   calculator,
		pricingConfig:     pricingConfig,
		eventPublisher:    publisher,
		reportingLocation: defaultReportingLocation,
		logger:            slog.Default(),
	}
	service.bookingService = booking.NewService(booking.Dependencies{
		Writer:           repository,
		ResolveRoute:     service.authoritativeRoute,
		CalculateFare:    pricingConfig.FareCentavos,
		PublishRide:      service.publishRide,
		HasRouteProvider: calculator != nil,
	})
	service.biddingService = newBiddingService(service)
	lifecycleStore, _ := repository.(ports.RideLifecycleStore)
	service.lifecycleService = lifecycleapplication.NewService(lifecycleapplication.Dependencies{
		Store:       lifecycleStore,
		PublishRide: service.publishRide,
	})
	settlementStore, _ := repository.(ports.CashSettlementStore)
	service.settlementService = settlementapplication.NewService(settlementapplication.Dependencies{
		Store:       settlementStore,
		PublishRide: service.publishRide,
	})
	return service
}

func (service *RideService) WithLogger(logger *slog.Logger) *RideService {
	if logger != nil {
		service.logger = logger
	}
	return service
}

func (service *RideService) PricingConfig() PricingConfig {
	return service.pricingConfig
}
func (service *RideService) CreateRide(ctx context.Context, passengerID int, fareCentavos int64) (domain.Ride, error) {
	return service.bookingService.Create(ctx, passengerID, fareCentavos)
}
func (service *RideService) SubmitBid(
	ctx context.Context,
	rideID int,
	driverID int,
	fareCentavos int64,
) (domain.Bid, error) {
	invalidRideID := rideID <= 0
	invalidDriverID := driverID <= 0
	invalidFare := fareCentavos <= 0
	if invalidRideID || invalidDriverID || invalidFare {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	bid, err := service.repository.CreateBid(ctx, domain.Bid{
		RideID:       rideID,
		DriverID:     driverID,
		FareCentavos: fareCentavos,
		Status:       "pending",
	})
	if err != nil {
		return domain.Bid{}, err
	}
	if ride, rideErr := service.repository.Get(ctx, rideID); rideErr == nil {
		service.publishRide(
			ctx,
			rideOfferUpdatedEvent,
			ride,
			map[string]any{"bid": bid},
		)
	}
	return bid, nil
}
func (service *RideService) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	bid, ride, err := service.repository.AcceptBid(ctx, bidID, driverID)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	service.publishRide(
		ctx,
		rideMatchedEvent,
		ride,
		map[string]any{"ride": ride, "bid": bid},
	)
	return bid, ride, nil
}
func (service *RideService) Get(ctx context.Context, id int) (domain.Ride, error) {
	return service.repository.Get(ctx, id)
}

func (service *RideService) CreateRideWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
	return service.bookingService.CreateWithDetails(ctx, ride)
}

func (service *RideService) Fare(
	ctx context.Context,
	originLat *float64,
	originLng *float64,
	destinationLat *float64,
	destinationLng *float64,
	distanceKm float64,
	durationMinutes float64,
) (RouteMetrics, int64, error) {
	return service.bookingService.EstimateFare(
		ctx,
		originLat,
		originLng,
		destinationLat,
		destinationLng,
		distanceKm,
		durationMinutes,
	)
}

func (service *RideService) authoritativeRoute(
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

func (service *RideService) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	return service.lifecycleService.AcceptRide(ctx, rideID, driverID)
}

func (service *RideService) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	return service.settlementService.SettleCash(ctx, rideID, driverID)
}

func (service *RideService) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	return service.lifecycleService.UpdateStatus(
		ctx,
		rideID,
		actorID,
		next,
	)
}

func (service *RideService) CalculateFare(distanceKm, durationMinutes float64) int64 {
	return service.pricingConfig.FareCentavos(distanceKm, durationMinutes)
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
	if invalidLatitude || invalidLongitude || invalidMetrics {
		return domain.ErrInvalidTrip
	}
	return nil
}

func (service *RideService) DriverStats(ctx context.Context, driverID int) (domain.DriverStats, error) {
	repository, ok := service.repository.(ports.DriverStatisticsReader)
	if !ok {
		return domain.DriverStats{}, errors.New("driver analytics persistence is unavailable")
	}
	dayStart, dayEnd := service.reportingDayBounds(time.Now())
	return repository.DriverStats(
		ctx,
		driverID,
		dayStart,
		dayEnd,
	)
}

func (service *RideService) DriverEarnings(ctx context.Context, driverID int) (domain.DriverEarningsSummary, error) {
	repository, ok := service.repository.(ports.DriverEarningsReader)
	if !ok {
		return domain.DriverEarningsSummary{}, errors.New("driver earnings persistence is unavailable")
	}
	location := service.reportingLocation
	if location == nil {
		location = defaultReportingLocation
	}
	now := time.Now().In(location)
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, location)
	monthEnd := monthStart.AddDate(0, 1, 0)
	entries, err := repository.DriverEarnings(
		ctx,
		driverID,
		monthStart.UTC(),
		monthEnd.UTC(),
	)
	if err != nil {
		return domain.DriverEarningsSummary{}, err
	}
	return summarizeDriverEarnings(entries, now, location), nil
}

func (service *RideService) DriverTrips(
	ctx context.Context,
	driverID int,
	query domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	repository, ok := service.repository.(ports.RideHistoryReader)
	if !ok {
		return nil, errors.New("driver trip persistence is unavailable")
	}
	if err := validateTripHistoryQuery(query); err != nil {
		return nil, err
	}
	return repository.DriverTrips(ctx, driverID, query)
}

func (service *RideService) PassengerRides(
	ctx context.Context,
	passengerID int,
	query domain.TripHistoryQuery,
) ([]domain.Ride, error) {
	repository, ok := service.repository.(ports.RideHistoryReader)
	if !ok {
		return nil, errors.New("passenger ride persistence is unavailable")
	}
	if err := validateTripHistoryQuery(query); err != nil {
		return nil, err
	}
	return repository.PassengerRides(ctx, passengerID, query)
}

func (service *RideService) PassengerActivitySummary(
	ctx context.Context,
	passengerID int,
) (domain.PassengerActivitySummary, error) {
	repository, ok := service.repository.(ports.PassengerActivityReader)
	if !ok {
		return domain.PassengerActivitySummary{}, errors.New("passenger activity persistence is unavailable")
	}
	weekStart, weekEnd := service.reportingWeekBounds(time.Now())
	return repository.PassengerActivitySummary(
		ctx,
		passengerID,
		weekStart,
		weekEnd,
	)
}

func (service *RideService) PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error) {
	invalidPassengerID := passengerID <= 0
	invalidLimit := limit <= 0 || limit > 100
	if invalidPassengerID || invalidLimit {
		return nil, errors.New("invalid passenger recent rides request")
	}
	if repository, ok := service.repository.(ports.RecentPassengerRidesReader); ok {
		return repository.PassengerRecentRides(ctx, passengerID, limit)
	}
	rides, err := service.PassengerRides(ctx, passengerID, domain.TripHistoryQuery{Limit: limit, Offset: 0})
	if err != nil {
		return nil, err
	}
	if len(rides) > limit {
		return rides[:limit], nil
	}
	return rides, nil
}

func (service *RideService) DriverReviews(ctx context.Context, driverID, limit, offset int) ([]domain.Review, error) {
	repository, ok := service.repository.(ports.ReviewStore)
	if !ok {
		return nil, errors.New("driver review persistence is unavailable")
	}
	return repository.DriverReviews(
		ctx,
		driverID,
		limit,
		offset,
	)
}

func (service *RideService) CreateReview(ctx context.Context, review domain.Review) (domain.Review, error) {
	repository, ok := service.repository.(ports.ReviewStore)
	if !ok {
		return domain.Review{}, errors.New("driver review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.Review{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreateReview(ctx, review)
}

func (service *RideService) CreatePassengerReview(
	ctx context.Context,
	review domain.PassengerReview,
) (domain.PassengerReview, error) {
	repository, ok := service.repository.(ports.PassengerReviewStore)
	if !ok {
		return domain.PassengerReview{}, errors.New("passenger review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.PassengerReview{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreatePassengerReview(ctx, review)
}

func (service *RideService) OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error) {
	repository, ok := service.repository.(ports.DriverAvailabilityReader)
	if !ok {
		return nil, errors.New("online driver persistence is unavailable")
	}
	if len(driverIDs) == 0 || len(driverIDs) > 20 {
		return nil, errors.New("driver availability ids are invalid")
	}
	return repository.OnlineDrivers(ctx, driverIDs)
}

func (service *RideService) PublicDriverSummaries(
	ctx context.Context,
	limit int,
) ([]domain.PublicDriverSummary, error) {
	repository, ok := service.repository.(ports.DriverAvailabilityReader)
	if !ok {
		return nil, errors.New("public driver summaries are unavailable")
	}
	if limit <= 0 || limit > 20 {
		return nil, errors.New("public driver summary limit is invalid")
	}
	return repository.PublicDriverSummaries(ctx, limit)
}

func validateTripHistoryQuery(query domain.TripHistoryQuery) error {
	invalidLimit := query.Limit <= 0 || query.Limit > 100
	invalidOffset := query.Offset < 0 || query.Offset > 1_000_000
	if invalidLimit || invalidOffset {
		return errors.New("trip history pagination is invalid")
	}
	if query.ActiveOnly && query.Limit > 20 {
		return errors.New("active trip history limit is invalid")
	}
	return nil
}
