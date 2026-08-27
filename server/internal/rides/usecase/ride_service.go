package usecase

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/Easy-Bao/DrivingApp/server/internal/rides/domain"
)

type RouteMetrics struct {
	DistanceKm      float64
	DurationMinutes float64
}

type RouteCalculator interface {
	CalculateRoute(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (RouteMetrics, error)
}

type RouteCalculatorFunc func(context.Context, float64, float64, float64, float64) (RouteMetrics, error)

func (calculator RouteCalculatorFunc) CalculateRoute(ctx context.Context, originLat, originLng, destinationLat, destinationLng float64) (RouteMetrics, error) {
	return calculator(ctx, originLat, originLng, destinationLat, destinationLng)
}

type RideService struct {
	repository        domain.Repository
	routeCalculator   RouteCalculator
	pricingConfig     PricingConfig
	eventPublisher    domain.EventPublisher
	reportingLocation *time.Location
}

func NewRideService(repository domain.Repository, pricingConfig PricingConfig, publishers ...domain.EventPublisher) *RideService {
	return &RideService{repository: repository, pricingConfig: pricingConfig, eventPublisher: firstPublisher(publishers), reportingLocation: defaultReportingLocation}
}

func NewRideServiceWithRouteCalculator(repository domain.Repository, calculator RouteCalculator, pricingConfig PricingConfig, publishers ...domain.EventPublisher) *RideService {
	return &RideService{repository: repository, routeCalculator: calculator, pricingConfig: pricingConfig, eventPublisher: firstPublisher(publishers), reportingLocation: defaultReportingLocation}
}

func (service *RideService) PricingConfig() PricingConfig {
	return service.pricingConfig
}
func (service *RideService) CreateRide(ctx context.Context, passengerID int, fareCentavos int64) (domain.Ride, error) {
	if passengerID <= 0 || fareCentavos <= 0 {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	ride, err := service.repository.CreateRide(ctx, domain.Ride{PassengerID: passengerID, Status: string(domain.RideRequested), FareCentavos: fareCentavos, RideType: "Solo Ride"})
	if err != nil {
		return domain.Ride{}, err
	}
	service.publishRide(ctx, rideCreatedEvent, ride, map[string]any{"ride": ride})
	return ride, nil
}
func (service *RideService) SubmitBid(ctx context.Context, rideID, driverID int, fareCentavos int64) (domain.Bid, error) {
	if rideID <= 0 || driverID <= 0 || fareCentavos <= 0 {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	bid, err := service.repository.CreateBid(ctx, domain.Bid{RideID: rideID, DriverID: driverID, FareCentavos: fareCentavos, Status: "pending"})
	if err != nil {
		return domain.Bid{}, err
	}
	if ride, rideErr := service.repository.Get(ctx, rideID); rideErr == nil {
		service.publishRide(ctx, rideOfferUpdatedEvent, ride, map[string]any{"bid": bid})
	}
	return bid, nil
}
func (service *RideService) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	bid, ride, err := service.repository.AcceptBid(ctx, bidID, driverID)
	if err != nil {
		return domain.Bid{}, domain.Ride{}, err
	}
	service.publishRide(ctx, rideMatchedEvent, ride, map[string]any{"ride": ride, "bid": bid})
	return bid, ride, nil
}
func (service *RideService) Get(ctx context.Context, id int) (domain.Ride, error) {
	return service.repository.Get(ctx, id)
}

func (service *RideService) CreateRideWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
	if ride.PassengerID <= 0 {
		return domain.Ride{}, domain.ErrInvalidTrip
	}
	if ride.Status != "" {
		status, ok := domain.NormalizeRideStatus(ride.Status)
		if !ok || status != domain.RideRequested {
			return domain.Ride{}, domain.ErrInvalidTrip
		}
	}
	metrics, err := service.authoritativeRoute(ctx, ride.PickupLatitude, ride.PickupLongitude, ride.DropoffLatitude, ride.DropoffLongitude, ride.DistanceKm, ride.DurationMinutes)
	if err != nil {
		return domain.Ride{}, err
	}
	ride.DistanceKm = metrics.DistanceKm
	ride.DurationMinutes = metrics.DurationMinutes
	ride.FareCentavos = service.CalculateFare(metrics.DistanceKm, metrics.DurationMinutes)
	ride.Status = string(domain.RideRequested)
	if ride.RideType == "" {
		ride.RideType = "solo"
	}
	created, err := service.repository.CreateRide(ctx, ride)
	if err != nil {
		return domain.Ride{}, err
	}
	service.publishRide(ctx, rideCreatedEvent, created, map[string]any{"ride": created})
	return created, nil
}

func (service *RideService) Fare(ctx context.Context, originLat, originLng, destinationLat, destinationLng *float64, distanceKm, durationMinutes float64) (RouteMetrics, int64, error) {
	if service.routeCalculator != nil {
		if originLat == nil || originLng == nil || destinationLat == nil || destinationLng == nil {
			return RouteMetrics{}, 0, domain.ErrInvalidTrip
		}
		metrics, err := service.authoritativeRoute(ctx, *originLat, *originLng, *destinationLat, *destinationLng, distanceKm, durationMinutes)
		if err != nil {
			return RouteMetrics{}, 0, err
		}
		return metrics, service.CalculateFare(metrics.DistanceKm, metrics.DurationMinutes), nil
	}
	if err := validateTrip(0, 0, 0, 0, distanceKm, durationMinutes); err != nil {
		return RouteMetrics{}, 0, err
	}
	metrics := RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}
	return metrics, service.CalculateFare(distanceKm, durationMinutes), nil
}

func (service *RideService) authoritativeRoute(ctx context.Context, pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes float64) (RouteMetrics, error) {
	if service.routeCalculator == nil {
		if err := validateTrip(pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes); err != nil {
			return RouteMetrics{}, err
		}
		return RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}, nil
	}
	if err := validateTrip(pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, 0, 0); err != nil {
		return RouteMetrics{}, err
	}
	metrics, err := service.routeCalculator.CalculateRoute(ctx, pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude)
	if err != nil {
		return RouteMetrics{}, domain.ErrRouteUnavailable
	}
	if err := validateTrip(pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, metrics.DistanceKm, metrics.DurationMinutes); err != nil {
		return RouteMetrics{}, domain.ErrRouteUnavailable
	}
	return metrics, nil
}

func (service *RideService) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	repository, ok := service.repository.(domain.LifecycleRepository)
	if !ok {
		return domain.Ride{}, errors.New("ride lifecycle persistence is unavailable")
	}
	ride, err := repository.AcceptRide(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, err
	}
	service.publishRide(ctx, rideMatchedEvent, ride, map[string]any{"ride": ride})
	return ride, nil
}

func (service *RideService) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	repository, ok := service.repository.(domain.PaymentRepository)
	if !ok {
		return domain.Ride{}, errors.New("cash settlement persistence is unavailable")
	}
	if driverID <= 0 {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	ride, err := repository.SettleCash(ctx, rideID, driverID)
	if err != nil {
		return domain.Ride{}, err
	}
	service.publishRide(ctx, rideStatusChangedEvent, ride, map[string]any{"ride": ride, "payment_status": ride.PaymentStatus})
	return ride, nil
}

func (service *RideService) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
	repository, ok := service.repository.(domain.LifecycleRepository)
	if !ok {
		return domain.Ride{}, errors.New("ride lifecycle persistence is unavailable")
	}
	current, err := service.repository.Get(ctx, rideID)
	if err != nil {
		return domain.Ride{}, err
	}
	if current.PassengerID != actorID && (current.DriverID == nil || *current.DriverID != actorID) {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	currentStatus, currentOK := domain.NormalizeRideStatus(current.Status)
	nextStatus, nextOK := domain.NormalizeRideStatus(next)
	if !currentOK || !nextOK || !domain.CanTransition(string(currentStatus), string(nextStatus)) {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	if current.PassengerID == actorID && nextStatus != domain.RideCancelled {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	if current.DriverID == nil && nextStatus != domain.RideCancelled {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	updated, err := repository.UpdateStatus(ctx, rideID, actorID, string(currentStatus), string(nextStatus))
	if err != nil {
		return domain.Ride{}, err
	}
	service.publishRide(ctx, rideStatusChangedEvent, updated, map[string]any{
		"previous_status": string(currentStatus),
		"ride":            updated,
	})
	return updated, nil
}

func (service *RideService) CalculateFare(distanceKm, durationMinutes float64) int64 {
	return service.pricingConfig.FareCentavos(distanceKm, durationMinutes)
}

func validateTrip(pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes float64) error {
	values := []float64{pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes}
	for _, value := range values {
		if math.IsNaN(value) || math.IsInf(value, 0) {
			return domain.ErrInvalidTrip
		}
	}
	if pickupLatitude < -90 || pickupLatitude > 90 || dropoffLatitude < -90 || dropoffLatitude > 90 || pickupLongitude < -180 || pickupLongitude > 180 || dropoffLongitude < -180 || dropoffLongitude > 180 || distanceKm < 0 || durationMinutes < 0 {
		return domain.ErrInvalidTrip
	}
	return nil
}

func (service *RideService) DriverStats(ctx context.Context, driverID int) (domain.DriverStats, error) {
	repository, ok := service.repository.(domain.DriverStatisticsRepository)
	if !ok {
		return domain.DriverStats{}, errors.New("driver analytics persistence is unavailable")
	}
	dayStart, dayEnd := service.reportingDayBounds(time.Now())
	return repository.DriverStats(ctx, driverID, dayStart, dayEnd)
}

func (service *RideService) DriverEarnings(ctx context.Context, driverID int) (domain.DriverEarningsSummary, error) {
	repository, ok := service.repository.(domain.DriverEarningsRepository)
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
	entries, err := repository.DriverEarnings(ctx, driverID, monthStart.UTC(), monthEnd.UTC())
	if err != nil {
		return domain.DriverEarningsSummary{}, err
	}
	return summarizeDriverEarnings(entries, now, location), nil
}

func (service *RideService) DriverTrips(ctx context.Context, driverID int, query domain.TripHistoryQuery) ([]domain.Ride, error) {
	repository, ok := service.repository.(domain.TripHistoryRepository)
	if !ok {
		return nil, errors.New("driver trip persistence is unavailable")
	}
	if err := validateTripHistoryQuery(query); err != nil {
		return nil, err
	}
	return repository.DriverTrips(ctx, driverID, query)
}

func (service *RideService) PassengerRides(ctx context.Context, passengerID int, query domain.TripHistoryQuery) ([]domain.Ride, error) {
	repository, ok := service.repository.(domain.TripHistoryRepository)
	if !ok {
		return nil, errors.New("passenger ride persistence is unavailable")
	}
	if err := validateTripHistoryQuery(query); err != nil {
		return nil, err
	}
	return repository.PassengerRides(ctx, passengerID, query)
}

func (service *RideService) PassengerActivitySummary(ctx context.Context, passengerID int) (domain.PassengerActivitySummary, error) {
	repository, ok := service.repository.(domain.PassengerActivitySummaryRepository)
	if !ok {
		return domain.PassengerActivitySummary{}, errors.New("passenger activity persistence is unavailable")
	}
	weekStart, weekEnd := service.reportingWeekBounds(time.Now())
	return repository.PassengerActivitySummary(ctx, passengerID, weekStart, weekEnd)
}

func (service *RideService) PassengerRecentRides(ctx context.Context, passengerID, limit int) ([]domain.Ride, error) {
	if passengerID <= 0 || limit <= 0 || limit > 100 {
		return nil, errors.New("invalid passenger recent rides request")
	}
	if repository, ok := service.repository.(domain.RecentPassengerRidesRepository); ok {
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
	repository, ok := service.repository.(domain.ReviewRepository)
	if !ok {
		return nil, errors.New("driver review persistence is unavailable")
	}
	return repository.DriverReviews(ctx, driverID, limit, offset)
}

func (service *RideService) CreateReview(ctx context.Context, review domain.Review) (domain.Review, error) {
	repository, ok := service.repository.(domain.ReviewRepository)
	if !ok {
		return domain.Review{}, errors.New("driver review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.Review{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreateReview(ctx, review)
}

func (service *RideService) CreatePassengerReview(ctx context.Context, review domain.PassengerReview) (domain.PassengerReview, error) {
	repository, ok := service.repository.(domain.PassengerReviewRepository)
	if !ok {
		return domain.PassengerReview{}, errors.New("passenger review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.PassengerReview{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreatePassengerReview(ctx, review)
}

func (service *RideService) OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error) {
	repository, ok := service.repository.(domain.DriverAvailabilityRepository)
	if !ok {
		return nil, errors.New("online driver persistence is unavailable")
	}
	if len(driverIDs) == 0 || len(driverIDs) > 20 {
		return nil, errors.New("driver availability ids are invalid")
	}
	return repository.OnlineDrivers(ctx, driverIDs)
}

func (service *RideService) PublicDriverSummaries(ctx context.Context, limit int) ([]domain.PublicDriverSummary, error) {
	repository, ok := service.repository.(domain.DriverAvailabilityRepository)
	if !ok {
		return nil, errors.New("public driver summaries are unavailable")
	}
	if limit <= 0 || limit > 20 {
		return nil, errors.New("public driver summary limit is invalid")
	}
	return repository.PublicDriverSummaries(ctx, limit)
}

func validateTripHistoryQuery(query domain.TripHistoryQuery) error {
	if query.Limit <= 0 || query.Limit > 100 || query.Offset < 0 || query.Offset > 1_000_000 {
		return errors.New("trip history pagination is invalid")
	}
	if query.ActiveOnly && query.Limit > 20 {
		return errors.New("active trip history limit is invalid")
	}
	return nil
}
