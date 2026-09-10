package domain

import (
	"context"
)

// Repository is retained for compatibility with existing internal adapters.
// New application code should depend on ride/ports instead.
type Repository interface {
	CreateRide(ctx context.Context, ride Ride) (Ride, error)
	CreateBid(ctx context.Context, bid Bid) (Bid, error)
	AcceptBid(ctx context.Context, bidID, driverID int) (Bid, Ride, error)
	Get(ctx context.Context, id int) (Ride, error)
}

// LifecycleRepository is retained for compatibility with existing internal
// adapters. New application code should depend on ride/ports instead.
type LifecycleRepository interface {
	Repository
	AcceptRide(ctx context.Context, rideID, driverID int) (Ride, error)
	UpdateStatus(ctx context.Context, rideID, actorID int, currentStatus, nextStatus string) (Ride, error)
}

// PaymentRepository is retained for compatibility with existing internal
// adapters. New application code should depend on ride/ports instead.
type PaymentRepository interface {
	SettleCash(ctx context.Context, rideID, driverID int) (Ride, error)
}

// CounterpartyRepository is retained for compatibility with existing internal
// adapters. New application code should depend on ride/ports instead.
type CounterpartyRepository interface {
	Counterparty(ctx context.Context, rideID, actorID int) (Counterparty, error)
}

// BiddingRepository is retained for compatibility with existing internal
// adapters. New application code should depend on ride/ports instead.
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

// Deprecated: use ride/ports.ReviewStore instead.
type ReviewRepository interface {
	DriverReviews(ctx context.Context, driverID int, limit, offset int) ([]Review, error)
	CreateReview(ctx context.Context, review Review) (Review, error)
}

// Deprecated: use ride/ports.PassengerReviewStore instead.
type PassengerReviewRepository interface {
	CreatePassengerReview(ctx context.Context, review PassengerReview) (PassengerReview, error)
}

// Deprecated: use ride/ports.DriverAvailabilityReader instead.
type DriverAvailabilityRepository interface {
	OnlineDrivers(ctx context.Context, driverIDs []int) ([]OnlineDriver, error)
	PublicDriverSummaries(ctx context.Context, limit int) ([]PublicDriverSummary, error)
}
