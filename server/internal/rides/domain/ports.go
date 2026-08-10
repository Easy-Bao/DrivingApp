package domain

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/realtime/event"
)

type Repository interface {
	CreateRide(ctx context.Context, ride Ride) (Ride, error)
	CreateBid(ctx context.Context, bid Bid) (Bid, error)
	AcceptBid(ctx context.Context, bidID, driverID int) (Bid, Ride, error)
	Get(ctx context.Context, id int) (Ride, error)
}

type LifecycleRepository interface {
	Repository
	AcceptRide(ctx context.Context, rideID, driverID int) (Ride, error)
	UpdateStatus(ctx context.Context, rideID, actorID int, currentStatus, nextStatus string) (Ride, error)
}

type PaymentRepository interface {
	SettleCash(ctx context.Context, rideID, driverID int) (Ride, error)
}

type BiddingRepository interface {
	Repository
	CreateSession(ctx context.Context, session BidSession) (BidSession, error)
	ActiveSessions(ctx context.Context, driverID *int) ([]BidSession, error)
	Offers(ctx context.Context, sessionID int) ([]BidOffer, error)
	PlaceOffer(ctx context.Context, offer BidOffer) (BidOffer, error)
	AcceptOffer(ctx context.Context, sessionID, offerID, passengerID int) (BidSession, BidOffer, Ride, error)
	CancelSession(ctx context.Context, sessionID, passengerID int) (BidSession, error)
	CancelOffer(ctx context.Context, sessionID, driverID int) (BidOffer, error)
	Session(ctx context.Context, sessionID int) (BidSession, error)
}

// EventPublisher is an outbound port. Event delivery is intentionally
// separate from persistence: clients recover authoritative state from REST
// snapshots when transient fan-out is unavailable.
type EventPublisher interface {
	Publish(ctx context.Context, envelope event.Envelope) error
}
