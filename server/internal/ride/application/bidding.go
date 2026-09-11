package application

import (
	"context"

	biddingapplication "github.com/Easy-Bao/DrivingApp/server/internal/ride/application/bidding"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
	"github.com/Easy-Bao/DrivingApp/server/internal/ride/ports"
)

// ErrBiddingPersistenceUnavailable is retained for callers of the legacy ride
// facade. The bidding module owns the underlying error value.
var ErrBiddingPersistenceUnavailable = biddingapplication.ErrPersistenceUnavailable

func newBiddingService(service *RideService) *biddingapplication.Service {
	store, _ := service.repository.(ports.BiddingStore)
	return biddingapplication.NewService(biddingapplication.Dependencies{
		Store:              store,
		ResolveRoute:       service.authoritativeRoute,
		CalculateFare:      service.pricingConfig.FareCentavos,
		PublishRide:        service.publishRide,
		PublishSession:     service.publishSession,
		PublishDriverOffer: service.publishDriverOffer,
	})
}

func (service *RideService) CreateSession(ctx context.Context, session domain.BidSession) (domain.BidSession, error) {
	return service.biddingService.CreateSession(ctx, session)
}

func (service *RideService) ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error) {
	return service.biddingService.ActiveSessions(ctx, driverID)
}

func (service *RideService) Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error) {
	return service.biddingService.Offers(ctx, sessionID)
}

func (service *RideService) PlaceOffer(ctx context.Context, offer domain.BidOffer) (domain.BidOffer, error) {
	return service.biddingService.PlaceOffer(ctx, offer)
}

func (service *RideService) AcceptOffer(
	ctx context.Context,
	sessionID int,
	offerID int,
	passengerID int,
) (domain.BidSession, domain.BidOffer, domain.Ride, error) {
	return service.biddingService.AcceptOffer(
		ctx,
		sessionID,
		offerID,
		passengerID,
	)
}

func (service *RideService) CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error) {
	return service.biddingService.CancelSession(ctx, sessionID, passengerID)
}

func (service *RideService) CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error) {
	return service.biddingService.CancelOffer(ctx, sessionID, driverID)
}

func (service *RideService) Session(ctx context.Context, sessionID int) (domain.BidSession, error) {
	return service.biddingService.Session(ctx, sessionID)
}
