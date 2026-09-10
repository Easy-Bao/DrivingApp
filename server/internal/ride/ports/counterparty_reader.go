package ports

import (
	"context"

	"github.com/Easy-Bao/DrivingApp/server/internal/ride/domain"
)

// CounterpartyReader loads the participant visible to the authenticated ride
// actor.
type CounterpartyReader interface {
	Counterparty(ctx context.Context, rideID, actorID int) (domain.Counterparty, error)
}
