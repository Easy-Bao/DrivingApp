package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// CounterpartyReader provides the participant projection used for ride
// authorization.
type CounterpartyReader interface {
	Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error)
}
