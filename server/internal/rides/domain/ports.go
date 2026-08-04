package domain

import "context"

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

type BiddingRepository interface {
	Repository
	CreateSession(ctx context.Context, session BidSession) (BidSession, error)
	ActiveSessions(ctx context.Context, driverID *int) ([]BidSession, error)
	Offers(ctx context.Context, sessionID int) ([]BidOffer, error)
	PlaceOffer(ctx context.Context, offer BidOffer) (BidOffer, error)
	AcceptOffer(ctx context.Context, sessionID, offerID, driverID int) (BidSession, BidOffer, Ride, error)
	CancelSession(ctx context.Context, sessionID, passengerID int) (BidSession, error)
	CancelOffer(ctx context.Context, sessionID, driverID int) (BidOffer, error)
	Session(ctx context.Context, sessionID int) (BidSession, error)
}
