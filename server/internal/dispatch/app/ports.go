package app

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/dispatch/domain"
	event "github.com/Easy-Bao/DrivingApp/server/internal/platform/events"
	ridedomain "github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// BiddingStore persists bid-session state and the ride created by acceptance
// in one transaction.
type BiddingStore interface {
	CreateSession(ctx context.Context, session domain.BidSession) (domain.BidSession, error)
	ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error)
	Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error)
	PlaceOffer(ctx context.Context, offer domain.BidOffer) (domain.BidOffer, error)
	AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (OfferAcceptance, error)
	CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error)
	CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error)
	Session(ctx context.Context, sessionID int) (domain.BidSession, error)
}

type OfferAcceptance struct {
	Session         domain.BidSession
	Offer           domain.BidOffer
	Ride            ridedomain.Ride
	RejectedOffers  []domain.BidOffer
	WithdrawnOffers []domain.BidOfferWithdrawal
}

type PassengerActiveRideChecker interface {
	HasActivePassengerRide(ctx context.Context, passengerID int) (bool, error)
}

type EventPublisher interface {
	Publish(context.Context, event.RealtimeEvent) error
}

type RouteMetrics struct {
	DistanceKm      float64
	DurationMinutes float64
}

type RouteResolver func(
	ctx context.Context,
	pickupLatitude float64,
	pickupLongitude float64,
	dropoffLatitude float64,
	dropoffLongitude float64,
	distanceKm float64,
	durationMinutes float64,
) (RouteMetrics, error)

// DriverAvailabilityReader supplies bounded availability and public driver projections.
type DriverAvailabilityReader interface {
	OnlineDrivers(ctx context.Context, driverIDs []int) ([]domain.OnlineDriver, error)
	PublicDriverSummaries(ctx context.Context, limit int) ([]domain.PublicDriverSummary, error)
}
