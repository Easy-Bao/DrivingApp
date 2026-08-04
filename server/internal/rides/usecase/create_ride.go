package usecase

import (
	"context"
	"errors"
	"math"

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

type Service struct {
	repository      domain.Repository
	routeCalculator RouteCalculator
}

func NewService(repository domain.Repository) *Service { return &Service{repository: repository} }

func NewServiceWithRouteCalculator(repository domain.Repository, calculator RouteCalculator) *Service {
	return &Service{repository: repository, routeCalculator: calculator}
}
func (service *Service) CreateRide(ctx context.Context, passengerID int, fareCentavos int64) (domain.Ride, error) {
	return service.repository.CreateRide(ctx, domain.Ride{PassengerID: passengerID, Status: "requested", FareCentavos: fareCentavos, RideType: "Solo Ride"})
}
func (service *Service) SubmitBid(ctx context.Context, rideID, driverID int, fareCentavos int64) (domain.Bid, error) {
	if rideID <= 0 || driverID <= 0 || fareCentavos <= 0 {
		return domain.Bid{}, domain.ErrInvalidFareOffer
	}
	return service.repository.CreateBid(ctx, domain.Bid{RideID: rideID, DriverID: driverID, FareCentavos: fareCentavos, Status: "pending"})
}
func (service *Service) AcceptBid(ctx context.Context, bidID, driverID int) (domain.Bid, domain.Ride, error) {
	return service.repository.AcceptBid(ctx, bidID, driverID)
}
func (service *Service) Get(ctx context.Context, id int) (domain.Ride, error) {
	return service.repository.Get(ctx, id)
}

func (service *Service) CreateRideWithDetails(ctx context.Context, ride domain.Ride) (domain.Ride, error) {
	metrics, err := service.authoritativeRoute(ctx, ride.PickupLatitude, ride.PickupLongitude, ride.DropoffLatitude, ride.DropoffLongitude, ride.DistanceKm, ride.DurationMinutes)
	if err != nil {
		return domain.Ride{}, err
	}
	ride.DistanceKm = metrics.DistanceKm
	ride.DurationMinutes = metrics.DurationMinutes
	ride.FareCentavos = CalculateFare(metrics.DistanceKm, metrics.DurationMinutes)
	if ride.Status == "" {
		ride.Status = "requested"
	}
	if ride.RideType == "" {
		ride.RideType = "solo"
	}
	return service.repository.CreateRide(ctx, ride)
}

func (service *Service) Fare(ctx context.Context, originLat, originLng, destinationLat, destinationLng *float64, distanceKm, durationMinutes float64) (RouteMetrics, int64, error) {
	if service.routeCalculator != nil {
		if originLat == nil || originLng == nil || destinationLat == nil || destinationLng == nil {
			return RouteMetrics{}, 0, domain.ErrInvalidTrip
		}
		metrics, err := service.authoritativeRoute(ctx, *originLat, *originLng, *destinationLat, *destinationLng, distanceKm, durationMinutes)
		if err != nil {
			return RouteMetrics{}, 0, err
		}
		return metrics, CalculateFare(metrics.DistanceKm, metrics.DurationMinutes), nil
	}
	if err := validateTrip(0, 0, 0, 0, distanceKm, durationMinutes); err != nil {
		return RouteMetrics{}, 0, err
	}
	metrics := RouteMetrics{DistanceKm: distanceKm, DurationMinutes: durationMinutes}
	return metrics, CalculateFare(distanceKm, durationMinutes), nil
}

func (service *Service) authoritativeRoute(ctx context.Context, pickupLatitude, pickupLongitude, dropoffLatitude, dropoffLongitude, distanceKm, durationMinutes float64) (RouteMetrics, error) {
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

func (service *Service) AcceptRide(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	repository, ok := service.repository.(domain.LifecycleRepository)
	if !ok {
		return domain.Ride{}, errors.New("ride lifecycle persistence is unavailable")
	}
	return repository.AcceptRide(ctx, rideID, driverID)
}

func (service *Service) SettleCash(ctx context.Context, rideID, driverID int) (domain.Ride, error) {
	repository, ok := service.repository.(domain.PaymentRepository)
	if !ok {
		return domain.Ride{}, errors.New("cash settlement persistence is unavailable")
	}
	if driverID <= 0 {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	return repository.SettleCash(ctx, rideID, driverID)
}

func (service *Service) UpdateStatus(ctx context.Context, rideID, actorID int, next string) (domain.Ride, error) {
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
	if current.PassengerID == actorID && next != "canceled" && next != "cancelled" {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	if current.DriverID == nil && next != "canceled" && next != "cancelled" {
		return domain.Ride{}, domain.ErrUnauthorizedRide
	}
	allowed := map[string]map[string]bool{
		"requested":  {"accepted": true, "canceled": true, "cancelled": true},
		"accepted":   {"arrived": true, "canceled": true, "cancelled": true},
		"arrived":    {"in_transit": true, "canceled": true, "cancelled": true},
		"in_transit": {"completed": true, "canceled": true, "cancelled": true},
	}
	if !allowed[current.Status][next] {
		return domain.Ride{}, domain.ErrInvalidStatusTransition
	}
	return repository.UpdateStatus(ctx, rideID, actorID, current.Status, next)
}

func CalculateFare(distanceKm, durationMinutes float64) int64 {
	if !isFiniteNonNegative(distanceKm) || !isFiniteNonNegative(durationMinutes) {
		return 0
	}
	total := 2500 + distanceKm*100 + durationMinutes*50
	if total < 2500 {
		return 2500
	}
	return int64(total)
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

func isFiniteNonNegative(value float64) bool {
	return !math.IsNaN(value) && !math.IsInf(value, 0) && value >= 0
}

func (service *Service) DriverStats(ctx context.Context, driverID int) (domain.DriverStats, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return domain.DriverStats{}, errors.New("driver analytics persistence is unavailable")
	}
	return repository.DriverStats(ctx, driverID)
}

func (service *Service) DriverTrips(ctx context.Context, driverID int) ([]domain.Ride, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("driver trip persistence is unavailable")
	}
	return repository.DriverTrips(ctx, driverID)
}

func (service *Service) PassengerRides(ctx context.Context, passengerID int) ([]domain.Ride, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("passenger ride persistence is unavailable")
	}
	return repository.PassengerRides(ctx, passengerID)
}

func (service *Service) DriverReviews(ctx context.Context, driverID, limit, offset int) ([]domain.Review, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("driver review persistence is unavailable")
	}
	return repository.DriverReviews(ctx, driverID, limit, offset)
}

func (service *Service) CreateReview(ctx context.Context, review domain.Review) (domain.Review, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return domain.Review{}, errors.New("driver review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.Review{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreateReview(ctx, review)
}

func (service *Service) CreatePassengerReview(ctx context.Context, review domain.PassengerReview) (domain.PassengerReview, error) {
	repository, ok := service.repository.(domain.PassengerReviewRepository)
	if !ok {
		return domain.PassengerReview{}, errors.New("passenger review persistence is unavailable")
	}
	if review.Rating < 1 || review.Rating > 5 {
		return domain.PassengerReview{}, errors.New("rating must be between 1 and 5")
	}
	return repository.CreatePassengerReview(ctx, review)
}

func (service *Service) OnlineDrivers(ctx context.Context) ([]domain.OnlineDriver, error) {
	repository, ok := service.repository.(domain.AnalyticsRepository)
	if !ok {
		return nil, errors.New("online driver persistence is unavailable")
	}
	return repository.OnlineDrivers(ctx)
}
