package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// BiddingStore is the application boundary for bid-session and offer state.
type BiddingStore interface {
	CreateSession(ctx context.Context, session domain.BidSession) (domain.BidSession, error)
	ActiveSessions(ctx context.Context, driverID *int) ([]domain.BidSession, error)
	Offers(ctx context.Context, sessionID int) ([]domain.BidOffer, error)
	PlaceOffer(ctx context.Context, offer domain.BidOffer) (domain.BidOffer, error)
	AcceptOffer(
		ctx context.Context,
		sessionID int,
		offerID int,
		passengerID int,
	) (domain.BidSession, domain.BidOffer, domain.Ride, error)
	CancelSession(ctx context.Context, sessionID, passengerID int) (domain.BidSession, error)
	CancelOffer(ctx context.Context, sessionID, driverID int) (domain.BidOffer, error)
	Session(ctx context.Context, sessionID int) (domain.BidSession, error)
}
